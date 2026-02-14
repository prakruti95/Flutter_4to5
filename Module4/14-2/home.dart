import 'package:flutter/material.dart';

import 'add.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(onPressed: ()
    {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Adddata()));

    },child: Icon(Icons.add),),
    );
  }
}
