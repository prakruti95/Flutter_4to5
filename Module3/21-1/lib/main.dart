import 'package:db2/screens/homepage.dart';
import 'package:flutter/material.dart';

void main()
{
  runApp(MyApp());
}
class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp
      (
      theme: ThemeData
        (
        primarySwatch: Colors.blue,

      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}



