import 'package:file_manager/helper/folder_model.dart';
import 'package:file_manager/helper/gesture_model.dart';
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await db.execute('''
      CREATE TABLE gestures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folderId INTEGER,
        gesturePoints TEXT,
        createdAt TEXT,
        FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE gestures (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          folderId INTEGER,
          gesturePoints TEXT,
          createdAt TEXT,
          FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE CASCADE
        )
      ''');

    }
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

  Future<Folder?> getFolderById(int id) async {
    final database = await db;
    final result = await database.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Folder.fromMap(result.first);
    }
    return null;
  }

  Future<String?> getFolderNameById(int folderId) async {
    final database = await db;
    final result = await database.query(
      'folders',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [folderId],
    );
    if (result.isNotEmpty) {
      return result.first['name'] as String;
    }
    return null;
  }

  //              Gesture  ------------------
  Future<int> insertGesture(GestureModel gesture) async {
    final database = await db;
    return await database.insert('gestures', gesture.toMap());
  }

  Future<List<GestureModel>> getGestures() async {
    final database = await db;
    final result = await database.query('gestures');
    return result.map((map) => GestureModel.fromMap(map)).toList();
  }

  Future<int> deleteGesture(int id) async {
    final database = await db;
    return await database.delete(
      'gestures',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
