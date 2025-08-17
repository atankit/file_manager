import 'package:file_manager/helper/folder_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _createDb();
    return _db!;
  }

  Future<Database> _createDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'folders.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        createdAt TEXT,
        isFile INTEGER,
        filePath TEXT,
        parentId INTEGER
      )
    ''');
  }


  Future<int> insertFolder(Folder folder) async {
    Database database = await db;
    return await database.insert('folders', folder.toMap());
  }

  Future<List<Folder>> getFolders({int? parentId}) async {
    Database database = await db;
    final maps = await database.query(
      'folders',
      where: parentId == null ? 'parentId IS NULL' : 'parentId = ?',
      whereArgs: parentId == null ? null : [parentId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Folder.fromMap(map)).toList();
  }

  Future<int> deleteFolder(int id) async {
    Database database = await db;
    return await database.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateFolder(Folder folder) async {
    Database database = await db;
    return await database.update('folders', folder.toMap(), where: 'id = ?', whereArgs: [folder.id]);
  }
}
