import 'package:flutter/material.dart';
import 'package:sqfliteex/add.dart';

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
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(),
        body: Center(),
        floatingActionButton:FloatingActionButton(onPressed: ()
        {
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => AddData()));
        },child: Icon(Icons.add),),
      );
  }
}
