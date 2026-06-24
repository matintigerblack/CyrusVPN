import 'dart:async';
import 'dart:io';

enum HealthState { healthy, degrading, critical, dead }

class HealthMonitor {
  static const int _windowSize = 10;
  static const int _healthyThreshold = 200; // ms
  static const int _degradingThreshold = 500; // ms
  static const int _criticalFailCount = 3;

  final _pingHistory = <int>[]; // ms, 0 = timeout
  int _consecutiveFails = 0;
  HealthState _state = HealthState.healthy;
  Timer? _timer;
  bool _isRunning = false;

  HealthState get state => _state;
  List<int> get pingHistory => List.unmodifiable(_pingHistory);

  /// Called when state changes
  Function(HealthState state)? onStateChanged;

  /// Called when connection is completely dead - switch NOW
  Function()? onConnectionDead;

  /// Called when degrading - start pre-testing backups
  Function()? onDegrading;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _pingHistory.clear();
    _consecutiveFails = 0;
    _state = HealthState.healthy;
    _scheduleNextPing();
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _pingHistory.clear();
  }

  void _scheduleNextPing() {
    if (!_isRunning) return;

    // Faster pinging when degrading
    final interval = _state == HealthState.healthy
        ? const Duration(seconds: 4)
        : const Duration(seconds: 2);

    _timer = Timer(interval, _performPing);
  }

  Future<void> _performPing() async {
    if (!_isRunning) return;

    final latency = await _ping();
    _recordPing(latency);
    _scheduleNextPing();
  }

  Future<int> _ping() async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect('1.1.1.1', 80,
          timeout: const Duration(seconds: 3));
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return 0; // timeout
    }
  }

  void _recordPing(int latency) {
    _pingHistory.add(latency);
    if (_pingHistory.length > _windowSize) {
      _pingHistory.removeAt(0);
    }

    if (latency == 0) {
      _consecutiveFails++;
    } else {
      _consecutiveFails = 0;
    }

    _updateState();
  }

  void _updateState() {
    final prevState = _state;

    // Dead: 3+ consecutive timeouts
    if (_consecutiveFails >= _criticalFailCount) {
      _state = HealthState.dead;
      if (prevState != HealthState.dead) {
        onStateChanged?.call(_state);
        onConnectionDead?.call();
      }
      return;
    }

    // Need at least 3 pings to judge
    if (_pingHistory.length < 3) {
      _state = HealthState.healthy;
      return;
    }

    final avg = _movingAverage();

    if (avg >= _degradingThreshold) {
      _state = HealthState.critical;
    } else if (avg >= _healthyThreshold) {
      _state = HealthState.degrading;
    } else {
      _state = HealthState.healthy;
    }

    if (_state != prevState) {
      onStateChanged?.call(_state);

      if (_state == HealthState.degrading || _state == HealthState.critical) {
        onDegrading?.call();
      }
      if (_state == HealthState.dead) {
        onConnectionDead?.call();
      }
    }
  }

  double _movingAverage() {
    if (_pingHistory.isEmpty) return 0;
    final nonZero = _pingHistory.where((p) => p > 0).toList();
    if (nonZero.isEmpty) return 9999; // all timeouts
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  int get currentLatency =>
      _pingHistory.isNotEmpty ? _pingHistory.last : -1;

  double get averageLatency => _movingAverage();

  /// Force a manual health check
  Future<int> checkNow() async {
    final latency = await _ping();
    _recordPing(latency);
    return latency;
  }
}
