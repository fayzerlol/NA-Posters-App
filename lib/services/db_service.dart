import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;

  DBService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('posters.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, fileName);
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      // TODO: create tables
    });
  }

  Future close() async {
    final db = await database;
    await db.close();
  }
}
