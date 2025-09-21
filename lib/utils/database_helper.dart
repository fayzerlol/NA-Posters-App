import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:na_posters_app/models/poster.dart';
import 'package:na_posters_app/models/maintenance_log.dart';

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
    await db.execute('''
    CREATE TABLE posters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poi_id INTEGER NOT NULL,
      lat REAL NOT NULL,
      lon REAL NOT NULL,
      name TEXT NOT NULL,
      amenity TEXT NOT NULL,
      added_date TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE maintenance_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poster_id INTEGER NOT NULL,
      timestamp INTEGER NOT NULL,
      status TEXT NOT NULL,
      notes TEXT NOT NULL,
      image_path TEXT,
      signature_path TEXT,
      FOREIGN KEY (poster_id) REFERENCES posters (id) ON DELETE CASCADE
    )
    ''');
  }

  // Métodos para Posters
  Future<int> addPoster(Poster poster) async {
    final db = await instance.database;
    return await db.insert('posters', poster.toMap());
  }

  Future<List<Poster>> getPosters() async {
    final db = await instance.database;
    final maps = await db.query('posters', orderBy: 'added_date DESC');
    return maps.map((json) => Poster.fromMap(json)).toList();
  }

  Future<int> deletePoster(int id) async {
    final db = await instance.database;
    return await db.delete('posters', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para MaintenanceLogs
  Future<int> addLog(MaintenanceLog log) async {
    final db = await instance.database;
    return await db.insert('maintenance_logs', log.toMap());
  }

  Future<List<MaintenanceLog>> getLogsForPoster(int posterId) async {
    final db = await instance.database;
    final maps = await db.query(
      'maintenance_logs',
      where: 'poster_id = ?',
      whereArgs: [posterId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((json) => MaintenanceLog.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
