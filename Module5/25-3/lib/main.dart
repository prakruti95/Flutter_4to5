import 'package:flutter/material.dart';
import 'package:mynewapp/views/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Sync MVVM',
      home: HomeScreen(),
    );
  }
}