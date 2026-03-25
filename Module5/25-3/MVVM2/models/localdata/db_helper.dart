import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../entity/user_model.dart';


class DBHelper {
  static Future<Database> initializeDB() async {
    String path = join(await getDatabasesPath(), 'app_data.db');
    return openDatabase(
      path,
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, surname TEXT, email TEXT, password TEXT, isSynced INTEGER DEFAULT 0)",
        );
      },
      version: 1,
    );
  }

  static Future<void> insertUser(UserModel user) async {
    final db = await initializeDB();
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<UserModel>> fetchUsers() async {
    final db = await initializeDB();
    final maps = await db.query('users');
    return maps.map((map) => UserModel.fromJson(map)).toList();
  }

  static Future<void> updateUser(UserModel user) async {
    final db = await initializeDB();
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  static Future<void> clearTable() async {
    final db = await initializeDB();
    await db.delete('users');
  }
}
