import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firstapp/first.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    checkconnectivity();
    //Timer(Duration(seconds: 3),() => Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => FirstScreen())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset("assets/a.png", width: 300, height: 300)),
    );
  }

  void checkconnectivity() async {
    List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      Timer(
        Duration(seconds: 3),
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FirstScreen()),
        ),
      );
    }
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      Timer(
        Duration(seconds: 3),
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FirstScreen()),
        ),
      );
    }
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // print("Internet is not connected");
      showmydialog();
    }
  }

  showmydialog()
  {
    Widget ok = ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: Text("OK"),
    );

    AlertDialog alertDialog = AlertDialog(
      title: Text("No Internet"),
      content: Text("Please check your internet connection"),
      actions: [ok],
    );
    
    showDialog(context: context, builder: (BuildContext conext)
    {
      return alertDialog;
    });
  }
}
