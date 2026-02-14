import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'home.dart';


void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget
{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
  final Future<FirebaseApp> _initailization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder
      (
        future: _initailization,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError)
          {
            print("something went wrong");
          }
          if (snapshot.connectionState == ConnectionState.done)
          {
            return MaterialApp
              (
              home: HomeScreen(),
            );
          }

          return CircularProgressIndicator();
        });

  }
}
