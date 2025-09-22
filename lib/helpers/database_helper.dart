import 'package:na_posters_app/models/group.dart';
import 'package:na_posters_app/models/maintenance_log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/poster.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('posters.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const nullableTextType = 'TEXT';

    await db.execute('''
      CREATE TABLE groups (
        id $idType,
        name $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE posters (
        id $idType,
        group_id $integerType,
        poi_id $integerType,
        lat $realType,
        lon $realType,
        name $textType,
        amenity $textType,
        added_date $textType,
        description $textType,
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_logs (
        id $idType,
        poster_id $integerType,
        timestamp $integerType,
        status $textType,
        notes $textType,
        responsible_name $textType,
        image_path $nullableTextType,
        signature_path $nullableTextType,
        FOREIGN KEY (poster_id) REFERENCES posters (id) ON DELETE CASCADE
      )
    ''');
  }


  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migração para v2
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';

      await db.execute('CREATE TABLE groups (id $idType, name $textType)');
      await db.execute('ALTER TABLE posters ADD COLUMN group_id $integerType');
    }
    if (oldVersion < 3) {
      // Migração para v3
      await db.execute("ALTER TABLE maintenance_logs ADD COLUMN responsible_name TEXT NOT NULL DEFAULT 'Unknown'");
      await db.execute('ALTER TABLE maintenance_logs ADD COLUMN image_path TEXT');
      await db.execute('ALTER TABLE maintenance_logs ADD COLUMN signature_path TEXT');
    }
  }

  Future<Group> createGroup(Group group) async {
    final db = await instance.database;
    final id = await db.insert('groups', group.toMap());
    return group.copyWith(id: id);
  }

  Future<List<Group>> readAllGroups() async {
    final db = await instance.database;
    const orderBy = 'name ASC';
    final result = await db.query('groups', orderBy: orderBy);

    return result.map((json) => Group.fromMap(json)).toList();
  }

  Future<Poster> addPoster(Poster poster) async {
    final db = await instance.database;
    final id = await db.insert('posters', poster.toMap());
    return poster.copyWith(id: id);
  }

  Future<List<Poster>> getPostersByGroup(int groupId) async {
    final db = await instance.database;
    final result = await db.query(
      'posters',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'name ASC',
    );

    return result.map((json) => Poster.fromMap(json)).toList();
  }

  Future<List<Poster>> getPosters() async {
    final db = await instance.database;
    const orderBy = 'name ASC';
    final result = await db.query('posters', orderBy: orderBy);

    return result.map((json) => Poster.fromMap(json)).toList();
  }

  Future<int> deletePoster(int id) async {
    final db = await instance.database;
    return await db.delete(
      'posters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<MaintenanceLog> createMaintenanceLog(MaintenanceLog log) async {
    final db = await instance.database;
    final id = await db.insert('maintenance_logs', log.toMap());
    return log.copyWith(id: id);
  }

  Future<List<MaintenanceLog>> readAllMaintenanceLogs(int posterId) async {
    final db = await instance.database;
    const orderBy = 'timestamp DESC';
    final result = await db.query(
      'maintenance_logs',
      orderBy: orderBy,
      where: 'poster_id = ?',
      whereArgs: [posterId],
    );

    return result.map((json) => MaintenanceLog.fromMap(json)).toList();
  }
}
