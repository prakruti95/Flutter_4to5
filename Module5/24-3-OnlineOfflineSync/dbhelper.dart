import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper
{
  static Future<Database> initializeDB() async
  {
    String path = join(await getDatabasesPath(), 'app_data.db');
    return openDatabase(
      path,
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT,  email TEXT, password TEXT, isSynced INTEGER DEFAULT 0)",
        );
      },
      version: 1,
    );
  }

  static Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await initializeDB();
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    final db = await initializeDB();
    return db.query('users');
  }

  static Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await initializeDB();
    await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  static Future<void> markAsUnsynced(int id) async {
    final db = await initializeDB();
    await db.update(
      'users',
      {'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ✅ Clear the entire 'users' table
  static Future<void> clearTable() async {
    final db = await initializeDB();
    await db.delete('users');
  }
}