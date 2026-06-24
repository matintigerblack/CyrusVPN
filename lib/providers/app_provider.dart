import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/vpn_config.dart';
import '../models/channel_model.dart';
import '../services/vpn_service.dart';
import '../services/health_monitor.dart';
import '../services/telegram_scraper.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final _vpnService = VpnService();
  final _healthMonitor = HealthMonitor();
  final _scraper = TelegramScraper();
  final _db = DatabaseService();

  // ─── State ────────────────────────────────────────────
  VpnState vpnState = VpnState.disconnected;
  HealthState healthState = HealthState.healthy;
  VpnConfig? activeConfig;
  List<VpnConfig> configs = [];
  List<ChannelModel> channels = [];

  // Stats
  String connectionDuration = '00:00:00';
  String uploadSpeed = '0 B/s';
  String downloadSpeed = '0 B/s';
  int currentLatency = -1;

  // UI states
  bool isTestingConfigs = false;
  bool isFetchingChannels = false;
  String statusMessage = '';
  bool autoSwitchEnabled = true;

  bool get isConnected => vpnState == VpnState.connected;
  bool get isConnecting => vpnState == VpnState.connecting;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await _vpnService.initialize();
    await _loadData();
    _setupListeners();
  }

  Future<void> _loadData() async {
    configs = await _db.getAllConfigs();
    channels = await _db.getAllChannels();
    notifyListeners();
  }

  void _setupListeners() {
    _vpnService.onStateChanged = (state) {
      vpnState = state;
      activeConfig = _vpnService.activeConfig;

      if (state == VpnState.connected) {
        _healthMonitor.start();
        statusMessage = 'متصل شد ✓';
      } else if (state == VpnState.disconnected) {
        _healthMonitor.stop();
        activeConfig = null;
        statusMessage = '';
      }
      notifyListeners();
    };

    _vpnService.onStatsChanged = (duration, up, down) {
      connectionDuration = duration;
      uploadSpeed = up;
      downloadSpeed = down;
      notifyListeners();
    };

    _healthMonitor.onStateChanged = (state) {
      healthState = state;
      notifyListeners();
    };

    _healthMonitor.onDegrading = () async {
      statusMessage = '⚠️ اتصال ضعیف شد، در حال آماده‌سازی...';
      notifyListeners();

      if (autoSwitchEnabled) {
        // Pre-test top configs while still connected
        await _preTestBackups();
      }
    };

    _healthMonitor.onConnectionDead = () async {
      statusMessage = '🔄 در حال تغییر کانفیگ...';
      notifyListeners();

      if (autoSwitchEnabled) {
        await _autoSwitch();
      }
    };
  }

  // ─── Connect / Disconnect ─────────────────────────────
  Future<void> toggleConnection() async {
    if (isConnected || isConnecting) {
      await disconnect();
    } else {
      await connectBest();
    }
  }

  Future<void> connectBest() async {
    final best = _getBestConfig();
    if (best == null) {
      statusMessage = 'ابتدا کانال تلگرام اضافه کنید';
      notifyListeners();
      return;
    }
    await connectTo(best);
  }

  Future<void> connectTo(VpnConfig config) async {
    statusMessage = 'در حال اتصال...';
    notifyListeners();

    final success = await _vpnService.connect(config);
    if (!success) {
      statusMessage = 'خطا در اتصال';
      config.recordFailure();
      await _db.updateConfig(config);
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _vpnService.disconnect();
    _healthMonitor.stop();
  }

  // ─── Auto Switch ──────────────────────────────────────
  Future<void> _preTestBackups() async {
    final candidates = configs
        .where((c) => c != activeConfig && c.isWorking)
        .take(5)
        .toList();

    for (final config in candidates) {
      final latency = await _vpnService.testConfig(config);
      if (latency > 0) {
        config.recordSuccess(latency);
      } else {
        config.recordFailure();
      }
      await _db.updateConfig(config);
    }
    configs.sort((a, b) => b.score.compareTo(a.score));
    notifyListeners();
  }

  Future<void> _autoSwitch() async {
    await _vpnService.disconnect();
    _healthMonitor.stop();

    // Update failed config
    if (activeConfig != null) {
      activeConfig!.recordFailure();
      await _db.updateConfig(activeConfig!);
    }

    // Find best working config (not the failed one)
    final candidates = configs
        .where((c) =>
            c.id != activeConfig?.id &&
            (c.isWorking || !c.isTested))
        .toList();
    candidates.sort((a, b) => b.score.compareTo(a.score));

    if (candidates.isEmpty) {
      statusMessage = '❌ هیچ کانفیگ جایگزینی یافت نشد';
      notifyListeners();
      return;
    }

    // Try connecting to candidates
    for (final candidate in candidates.take(3)) {
      final success = await _vpnService.connect(candidate);
      if (success) {
        statusMessage = '✅ کانفیگ جدید متصل شد';
        notifyListeners();
        return;
      }
    }

    statusMessage = '❌ اتصال ناموفق بود';
    notifyListeners();
  }

  VpnConfig? _getBestConfig() {
    if (configs.isEmpty) return null;
    final working = configs.where((c) => c.isWorking).toList();
    if (working.isNotEmpty) {
      working.sort((a, b) => b.score.compareTo(a.score));
      return working.first;
    }
    return configs.first;
  }

  // ─── Config Testing ───────────────────────────────────
  Future<void> testAllConfigs() async {
    isTestingConfigs = true;
    notifyListeners();

    final toTest = configs.take(20).toList();
    for (final config in toTest) {
      statusMessage = 'تست ${configs.indexOf(config) + 1}/${toTest.length}...';
      notifyListeners();

      final latency = await _vpnService.testConfig(config);
      if (latency > 0) {
        config.recordSuccess(latency);
      } else {
        config.recordFailure();
      }
      await _db.updateConfig(config);
    }

    configs.sort((a, b) => b.score.compareTo(a.score));
    isTestingConfigs = false;
    statusMessage = '✅ تست کامل شد';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    statusMessage = '';
    notifyListeners();
  }

  // ─── Channel Management ───────────────────────────────
  Future<void> addChannel(String channelName) async {
    // Clean the name
    String name = channelName
        .trim()
        .replaceAll('@', '')
        .replaceAll('https://t.me/', '')
        .replaceAll('t.me/', '');

    if (name.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final channel = ChannelModel(id: id, name: name);
    await _db.saveChannel(channel);
    channels.add(channel);
    notifyListeners();

    // Auto-fetch on add
    await fetchChannel(channel);
  }

  Future<void> fetchChannel(ChannelModel channel) async {
    channel.status = 'fetching';
    notifyListeners();

    try {
      final newConfigs = await _scraper.fetchFromChannel(channel);
      await _db.saveConfigs(newConfigs);

      channel.configCount = newConfigs.length;
      channel.lastFetched = DateTime.now();
      channel.status = 'done';
      await _db.updateChannel(channel);

      configs = await _db.getAllConfigs();
    } catch (e) {
      channel.status = 'error';
    }

    notifyListeners();
  }

  Future<void> fetchAllChannels() async {
    isFetchingChannels = true;
    notifyListeners();

    for (final channel in channels.where((c) => c.isEnabled)) {
      await fetchChannel(channel);
    }

    isFetchingChannels = false;
    notifyListeners();
  }

  Future<void> deleteChannel(ChannelModel channel) async {
    await _db.deleteChannel(channel.id);
    await _db.deleteConfigsByChannel(channel.name);
    channels.remove(channel);
    configs = await _db.getAllConfigs();
    notifyListeners();
  }

  Future<void> deleteConfig(VpnConfig config) async {
    await _db.deleteConfig(config.id);
    configs.remove(config);
    notifyListeners();
  }
}
