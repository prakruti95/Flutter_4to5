import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
class DbHelper
{
  late Database db;

  Future open() async
  {
    var dbpath = await getDatabasesPath();
    String path = join(dbpath,'mybatch.db');

   db = await openDatabase(path,version: 1,
       onCreate:(Database db,int version)async
       {
          await db.execute(
              ''' CREATE TABLE IF NOT EXISTS students( 
                          name varchar(255) not null,
                          email varchar(255) not null,
                          password varchar(255) not null
                      );'''
          );
       });
  }
}