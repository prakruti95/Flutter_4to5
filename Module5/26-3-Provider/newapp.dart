import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'counter.dart';

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
    final counter = Provider.of<CounterProvider>(context);
    return MaterialApp(
        home:Scaffold
      (
        appBar: AppBar(title: Text("Provider Example")),
      body: Center(
        child: Text(
          counter.count.toString(),
          style: TextStyle(fontSize: 30),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: ()
      {
          counter.increment();
      },child: Icon(Icons.add),),
      ));
  }
}
