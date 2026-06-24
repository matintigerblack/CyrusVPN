import 'package:http/http.dart' as http;
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/vpn_config.dart';
import '../models/channel_model.dart';
import 'dart:convert';
import 'dart:math';

class TelegramScraper {
  static const List<String> _protocols = [
    'vmess://',
    'vless://',
    'trojan://',
    'ss://',
  ];

  /// Fetches configs from a Telegram public channel
  Future<List<VpnConfig>> fetchFromChannel(ChannelModel channel) async {
    final links = <String>[];

    try {
      // Try fetching multiple pages
      for (int attempt = 0; attempt < 3; attempt++) {
        final url = attempt == 0
            ? 'https://t.me/s/${channel.name}'
            : 'https://t.me/s/${channel.name}?before=${_getOffset(attempt)}';

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Android 14; Mobile) AppleWebKit/537.36',
            'Accept-Language': 'fa,en;q=0.9',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final extracted = _extractLinks(response.body);
          links.addAll(extracted);
        }
      }
    } catch (e) {
      // Network error - return empty
    }

    // Parse links to VpnConfig objects
    final configs = <VpnConfig>[];
    final seen = <String>{};

    for (final link in links) {
      final normalized = link.trim();
      if (seen.contains(normalized)) continue;
      seen.add(normalized);

      final config = _parseLink(normalized, channel.name);
      if (config != null) configs.add(config);
    }

    return configs;
  }

  List<String> _extractLinks(String html) {
    final links = <String>[];

    // Decode HTML entities
    String decoded = html
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#33;', '!')
        .replaceAll('&#61;', '=');

    for (final protocol in _protocols) {
      // Match protocol links - they end at whitespace, <, or "
      final pattern =
          RegExp('$protocol[A-Za-z0-9+/=@:._\\-?&#%]+', caseSensitive: false);
      final matches = pattern.allMatches(decoded);
      for (final match in matches) {
        String link = match.group(0)!;
        // Clean up trailing HTML artifacts
        link = link.replaceAll(RegExp(r'[<>"\'\\s]+$'), '');
        if (link.length > 20) links.add(link);
      }
    }

    return links;
  }

  VpnConfig? _parseLink(String link, String channelName) {
    try {
      final v2rayUrl = FlutterV2ray.parseFromURL(link);
      final remark = v2rayUrl.remark.isNotEmpty ? v2rayUrl.remark : 'Config';

      // Extract server and port from the link
      String server = '';
      int port = 0;
      String protocol = 'unknown';

      if (link.startsWith('vmess://')) {
        protocol = 'vmess';
        try {
          final base64 = link.substring(8);
          final decoded = utf8.decode(base64Decode(base64));
          final json = jsonDecode(decoded);
          server = json['add'] ?? '';
          port = int.tryParse(json['port'].toString()) ?? 0;
        } catch (_) {}
      } else if (link.startsWith('vless://')) {
        protocol = 'vless';
        final uri = Uri.tryParse(link.replaceFirst('vless://', 'https://'));
        server = uri?.host ?? '';
        port = uri?.port ?? 0;
      } else if (link.startsWith('trojan://')) {
        protocol = 'trojan';
        final uri = Uri.tryParse(link.replaceFirst('trojan://', 'https://'));
        server = uri?.host ?? '';
        port = uri?.port ?? 0;
      } else if (link.startsWith('ss://')) {
        protocol = 'ss';
        final uri = Uri.tryParse(link.replaceFirst('ss://', 'https://'));
        server = uri?.host ?? '';
        port = uri?.port ?? 0;
      }

      if (server.isEmpty) return null;

      // Generate unique ID from server+port+protocol
      final id = '${protocol}_${server}_${port}_${channelName}'.hashCode.abs().toString();

      return VpnConfig(
        id: id,
        rawLink: link,
        remark: remark,
        server: server,
        port: port,
        protocol: protocol,
        sourceChannel: channelName,
      );
    } catch (e) {
      return null;
    }
  }

  int _getOffset(int attempt) {
    return attempt * 20;
  }
}
