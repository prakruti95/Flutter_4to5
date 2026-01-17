import 'package:flutter/material.dart';
import 'package:sqfliteex/add.dart';

import 'dbhelper.dart';
import 'edit.dart';

void main()
{
  runApp(MaterialApp(home:MyApp()));
}
class MyApp extends StatefulWidget
{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
  DbHelper db1 = DbHelper();
  List<Map> slist = [];
  @override
  void initState() {
    // TODO: implement initState
    db1.open();
    getdata();

  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(),
        body: Center
          (
              child: Column
                (
                  children:slist.map((tops)
                  {
                        return Card
                          (
                            child: ListTile
                              (
                                leading:  Icon(Icons.person),
                                title: Text(tops["name"]),
                                subtitle: Text(tops["email"]),
                                trailing: Wrap
                                  (
                                    children:
                                    [
                                      IconButton(onPressed: ()
                                      {
                                        Navigator.push(context,MaterialPageRoute(builder: (context) => EditPage(email:tops["email"],name:tops["name"])));
                                      }, icon: Icon(Icons.edit)),
                                      IconButton(onPressed: ()
                                      {
                                          db1.db.rawDelete("delete from students where email=?",[tops["email"]]);
                                          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyApp()));
                                      }, icon: Icon(Icons.delete)),
                                    ],
                                  ),
                            ),
                          );
                  }).toList(),
                ) ,
          ),
        floatingActionButton:FloatingActionButton(onPressed: ()
        {
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => AddData()));
        },child: Icon(Icons.add),),
      );
  }

   getdata()
  {
    Future.delayed(Duration(milliseconds: 500),()async
    {
      slist = await db1.db.rawQuery('SELECT * FROM students');
      setState(()
      {

      });
    });
  }

  }

