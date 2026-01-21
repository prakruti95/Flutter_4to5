import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper
{
  static final _databaseName = "topstech.db";
  static final _databaseVersion = 1;
  //1st table
  static final table = 'category';
  static final columnId = '_id';
  static final columnname = 'category_name';
  //2nd table
  static final table2 = 'contact';
  static final columnId1 = '_id';
  static final columnName = 'name';
  static final columnLName = 'lname';
  static final columnMobile = 'mobile';
  static final columnEmail = 'email';
  static final columnCategory = 'cat';
  static final columnProfile = 'profile';


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

    await db.execute('''
          CREATE TABLE $table2 (
            $columnId1 INTEGER PRIMARY KEY,
            $columnName TEXT NOT NULL, 
            $columnLName TEXT NOT NULL, 
            $columnMobile TEXT NOT NULL, 
            $columnEmail TEXT NOT NULL, 
            $columnCategory TEXT NOT NULL, 
            $columnProfile TEXT NOT NULL
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

  insertcontact(Map<String, dynamic> row)async
  {
    Database? db = await instance.database;
    return await db.insert(table2,row);
  }

  //view category
  Future<List<Map<String, dynamic>>> queryAllRows() async
  {
    Database db = await instance.database;
    return await db.query(table);//select * from category
  }

  //view contact
  Future<List<Map<String, dynamic>>> querycontact() async
  {
    Database db = await instance.database;
    return await db.query(table2);//select * from contact
  }

  //delete
  Future<int> deletedata(int id) async
  {
    Database db = await instance.database;
    return await db.delete(table2,where: '$columnId1 = ?', whereArgs: [id]);
  }

}