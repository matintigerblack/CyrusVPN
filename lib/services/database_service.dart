import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vpn_config.dart';
import '../models/channel_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cyrus_vpn.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE configs (
            id TEXT PRIMARY KEY,
            rawLink TEXT NOT NULL,
            remark TEXT,
            server TEXT,
            port INTEGER,
            protocol TEXT,
            sourceChannel TEXT,
            latency INTEGER DEFAULT -1,
            score INTEGER DEFAULT 1000,
            failCount INTEGER DEFAULT 0,
            successCount INTEGER DEFAULT 0,
            lastTested INTEGER,
            fetchedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE channels (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            isEnabled INTEGER DEFAULT 1,
            configCount INTEGER DEFAULT 0,
            lastFetched INTEGER,
            status TEXT DEFAULT 'idle'
          )
        ''');
      },
    );
  }

  // ─── Configs ──────────────────────────────────────────
  Future<void> saveConfig(VpnConfig config) async {
    final database = await db;
    await database.insert(
      'configs',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveConfigs(List<VpnConfig> configs) async {
    final database = await db;
    final batch = database.batch();
    for (final c in configs) {
      batch.insert('configs', c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<VpnConfig>> getAllConfigs() async {
    final database = await db;
    final maps = await database.query('configs',
        orderBy: 'score DESC, latency ASC');
    return maps.map((m) => VpnConfig.fromMap(m)).toList();
  }

  Future<void> updateConfig(VpnConfig config) async {
    final database = await db;
    await database.update(
      'configs',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future<void> deleteConfig(String id) async {
    final database = await db;
    await database.delete('configs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteConfigsByChannel(String channel) async {
    final database = await db;
    await database.delete('configs',
        where: 'sourceChannel = ?', whereArgs: [channel]);
  }

  // ─── Channels ─────────────────────────────────────────
  Future<void> saveChannel(ChannelModel channel) async {
    final database = await db;
    await database.insert(
      'channels',
      channel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChannelModel>> getAllChannels() async {
    final database = await db;
    final maps = await database.query('channels');
    return maps.map((m) => ChannelModel.fromMap(m)).toList();
  }

  Future<void> updateChannel(ChannelModel channel) async {
    final database = await db;
    await database.update(
      'channels',
      channel.toMap(),
      where: 'id = ?',
      whereArgs: [channel.id],
    );
  }

  Future<void> deleteChannel(String id) async {
    final database = await db;
    await database.delete('channels', where: 'id = ?', whereArgs: [id]);
  }
}
