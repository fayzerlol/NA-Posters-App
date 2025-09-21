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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE posters (
        id $idType,
        lat $realType,
        lon $realType,
        name $textType,
        description $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_logs (
        id $idType,
        poster_id $integerType,
        timestamp $integerType,
        status $textType,
        notes $textType,
        FOREIGN KEY (poster_id) REFERENCES posters (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<Poster> createPoster(Poster poster) async {
    final db = await instance.database;
    final id = await db.insert('posters', poster.toMap());
    return poster;
  }

  Future<List<Poster>> readAllPosters() async {
    final db = await instance.database;
    const orderBy = 'name ASC';
    final result = await db.query('posters', orderBy: orderBy);

    return result.map((json) => Poster.fromMap(json)).toList();
  }

  Future<MaintenanceLog> createMaintenanceLog(MaintenanceLog log) async {
    final db = await instance.database;
    final id = await db.insert('maintenance_logs', log.toMap());
    return log;
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
