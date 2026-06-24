class VpnConfig {
  final String id;
  final String rawLink;
  final String remark;
  final String server;
  final int port;
  final String protocol; // vmess, vless, trojan, ss
  final String sourceChannel;
  int latency; // -1=untested, 0=timeout, >0=ms
  int score;
  int failCount;
  int successCount;
  DateTime? lastTested;
  DateTime fetchedAt;

  VpnConfig({
    required this.id,
    required this.rawLink,
    required this.remark,
    required this.server,
    required this.port,
    required this.protocol,
    required this.sourceChannel,
    this.latency = -1,
    this.score = 1000,
    this.failCount = 0,
    this.successCount = 0,
    this.lastTested,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  bool get isTested => latency != -1;
  bool get isWorking => latency > 0 && latency < 8000;
  bool get isFast => latency > 0 && latency < 300;
  bool get isDegrading => latency > 500;
  bool get isTimeout => latency == 0;

  // Color indicator
  String get statusEmoji {
    if (!isTested) return '⚪';
    if (isTimeout) return '🔴';
    if (latency < 200) return '🟢';
    if (latency < 500) return '🟡';
    return '🔴';
  }

  String get latencyText {
    if (!isTested) return 'نامشخص';
    if (isTimeout) return 'قطع';
    return '${latency}ms';
  }

  void recordSuccess(int newLatency) {
    latency = newLatency;
    successCount++;
    failCount = 0;
    score = (score + 10).clamp(0, 1000);
    if (newLatency < 100) score = (score + 50).clamp(0, 1000);
    if (newLatency < 200) score = (score + 20).clamp(0, 1000);
    lastTested = DateTime.now();
  }

  void recordFailure() {
    latency = 0;
    failCount++;
    score = (score - 200).clamp(0, 1000);
    lastTested = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'rawLink': rawLink,
    'remark': remark,
    'server': server,
    'port': port,
    'protocol': protocol,
    'sourceChannel': sourceChannel,
    'latency': latency,
    'score': score,
    'failCount': failCount,
    'successCount': successCount,
    'lastTested': lastTested?.millisecondsSinceEpoch,
    'fetchedAt': fetchedAt.millisecondsSinceEpoch,
  };

  factory VpnConfig.fromMap(Map<String, dynamic> map) => VpnConfig(
    id: map['id'],
    rawLink: map['rawLink'],
    remark: map['remark'] ?? 'Config',
    server: map['server'] ?? '',
    port: map['port'] ?? 0,
    protocol: map['protocol'] ?? 'unknown',
    sourceChannel: map['sourceChannel'] ?? '',
    latency: map['latency'] ?? -1,
    score: map['score'] ?? 1000,
    failCount: map['failCount'] ?? 0,
    successCount: map['successCount'] ?? 0,
    lastTested: map['lastTested'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['lastTested'])
        : null,
    fetchedAt: map['fetchedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['fetchedAt'])
        : DateTime.now(),
  );
}
