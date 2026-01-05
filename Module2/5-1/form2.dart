import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test6/form1.dart';

class WelcomeScreen2 extends StatefulWidget
{
  const WelcomeScreen2({super.key});

  @override
  State<WelcomeScreen2> createState() => _WelcomeScreen2State();
}

class _WelcomeScreen2State extends State<WelcomeScreen2> 
{
  late SharedPreferences sharedPreferences;
  var mydata;
  @override
  void initState() {
    // TODO: implement initState
    //super.initState();
    checkdata();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold
      (
        appBar: AppBar(title: Text("Welcome $mydata"),actions:
        [
          IconButton(onPressed: ()
          {
            sharedPreferences.setBool("app1", true);

            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyLoginPage()));

          }, icon: Icon(Icons.logout))
        ],),
      );
  }

  void checkdata()async
  {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(()
    {
      mydata = sharedPreferences.getString("tops1")!;
    });
    //print(sharedPreferences.getString("tops1"));
  }
}
