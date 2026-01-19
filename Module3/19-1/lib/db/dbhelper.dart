import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper
{
  static final _databaseName = "topstech.db";
  static final _databaseVersion = 1;
  static final table = 'category';
  static final columnId = '_id';
  static final columnname = 'category_name';

  DbHelper._privateConstructor();

  static Database? _database;
  static final DbHelper instance = DbHelper._privateConstructor();

  Future <void> _onCreate(Database db, int version) async
  {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnname TEXT NOT NULL 
          )
          ''');
  }

  Future<Database> get database async => _database ??= await _initDatabase();

  _initDatabase()async
  {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase
      (path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future<Database?> get database1 async
  {
    if (_database == null)
    {
      _database = await _initDatabase();
    }
    return _database;
  }

  insertdata(Map<String, dynamic> row)async
  {
    Database? db = await instance.database;
    return await db.insert(table,row);
  }



}