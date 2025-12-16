import 'dart:async';

import 'package:firstapp/first.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget
{
  @override
  SplashScreenState createState() => SplashScreenState();

}

class SplashScreenState extends State<SplashScreen>
{
  @override
  void initState()
  {
    Timer(Duration(seconds: 3),() => Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => FirstScreen())));
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      body: Center
        (
        child: Image.asset("assets/a.png",width: 300,height: 300,),

      ),
    );
  }
}