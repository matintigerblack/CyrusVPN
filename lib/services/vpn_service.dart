import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/vpn_config.dart';

enum VpnState { disconnected, connecting, connected, disconnecting, error }

class VpnService {
  VpnState state = VpnState.disconnected;
  VpnConfig? activeConfig;
  String duration = '00:00:00';
  String uploadSpeed = '0 B/s';
  String downloadSpeed = '0 B/s';

  Function(VpnState)? onStateChanged;
  Function(String duration, String up, String down)? onStatsChanged;

  late FlutterV2ray _v2ray;

  VpnService() {
    _v2ray = FlutterV2ray(
      onStatusChanged: (V2RayStatus status) {
        _handleStatusChange(status);
      },
    );
  }

  Future<void> initialize() async {
    await _v2ray.initializeV2Ray(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
    );
  }

  void _handleStatusChange(V2RayStatus status) {
    switch (status.state) {
      case 'CONNECTED':
        state = VpnState.connected;
        break;
      case 'CONNECTING':
        state = VpnState.connecting;
        break;
      case 'DISCONNECTED':
        state = VpnState.disconnected;
        activeConfig = null;
        break;
      case 'DISCONNECTING':
        state = VpnState.disconnecting;
        break;
      default:
        break;
    }

    duration = status.duration;
    uploadSpeed = status.speed?.upload ?? '0 B/s';
    downloadSpeed = status.speed?.download ?? '0 B/s';

    onStateChanged?.call(state);
    onStatsChanged?.call(duration, uploadSpeed, downloadSpeed);
  }

  Future<bool> connect(VpnConfig config) async {
    try {
      state = VpnState.connecting;
      onStateChanged?.call(state);

      // Request VPN permission
      final hasPermission = await _v2ray.requestPermission();
      if (!hasPermission) {
        state = VpnState.error;
        onStateChanged?.call(state);
        return false;
      }

      final v2rayUrl = FlutterV2ray.parseFromURL(config.rawLink);

      await _v2ray.startV2Ray(
        remark: config.remark,
        config: v2rayUrl.getFullConfiguration(),
        proxyOnly: false,
      );

      activeConfig = config;
      return true;
    } catch (e) {
      state = VpnState.error;
      onStateChanged?.call(state);
      return false;
    }
  }

  Future<void> disconnect() async {
    await _v2ray.stopV2Ray();
    activeConfig = null;
  }

  Future<int> testConfig(VpnConfig config) async {
    try {
      final v2rayUrl = FlutterV2ray.parseFromURL(config.rawLink);
      final delay = await FlutterV2ray.getServerDelay(
        config: v2rayUrl.getFullConfiguration(),
      );
      return delay;
    } catch (e) {
      return 0; // timeout
    }
  }

  bool get isConnected => state == VpnState.connected;
  bool get isConnecting => state == VpnState.connecting;
}
