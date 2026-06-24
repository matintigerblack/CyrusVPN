class ChannelModel {
  final String id;
  String name; // e.g. "freevpn"
  bool isEnabled;
  int configCount;
  DateTime? lastFetched;
  String status; // idle, fetching, done, error

  ChannelModel({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.configCount = 0,
    this.lastFetched,
    this.status = 'idle',
  });

  String get url => 'https://t.me/s/$name';
  String get displayName => '@$name';

  String get lastFetchedText {
    if (lastFetched == null) return 'هنوز آپدیت نشده';
    final diff = DateTime.now().difference(lastFetched!);
    if (diff.inMinutes < 1) return 'همین الان';
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    return '${diff.inDays} روز پیش';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isEnabled': isEnabled ? 1 : 0,
    'configCount': configCount,
    'lastFetched': lastFetched?.millisecondsSinceEpoch,
    'status': status,
  };

  factory ChannelModel.fromMap(Map<String, dynamic> map) => ChannelModel(
    id: map['id'],
    name: map['name'],
    isEnabled: map['isEnabled'] == 1,
    configCount: map['configCount'] ?? 0,
    lastFetched: map['lastFetched'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['lastFetched'])
        : null,
    status: map['status'] ?? 'idle',
  );
}
