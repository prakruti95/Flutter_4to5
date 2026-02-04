import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/main.dart';
import 'package:jsoncrud1/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Signin extends StatefulWidget
{
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin>
{

  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();
  late SharedPreferences sharedPreferences;
  late String myemail,mypass;
  var _formkey = GlobalKey<FormState>();
  var newuser;
  @override
  void initState() {
    // TODO: implement initState
    checkvalue();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(),
      body: Form
        (
          key: _formkey,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center
              (
              child: Column
                (
                children:
                [
                  TextFormField(controller:email,decoration: InputDecoration(hintText: "Enter Email",border: OutlineInputBorder()),
                    validator: (value)
                    {
                      if(email.text.toString().isEmpty)
                      {
                        return "Please Enter Email";
                      }
                    },
                  ),
                  SizedBox(height: 20,),
                  TextFormField(controller:pass,obscureText:true,decoration: InputDecoration(hintText: "Enter Password",border: OutlineInputBorder()),
                    validator: (value)
                    {
                      if(pass.text.toString().isEmpty)
                      {
                        return "Please Enter Password";
                      }
                    },
                  ),


                  SizedBox(height: 20,),
                  TextButton(onPressed: ()
                  {

                    myemail = email.text.toString();
                    mypass = pass.text.toString();
                    if(_formkey.currentState!.validate())
                    {
                      checkdata();
                      sharedPreferences.setString("email",myemail);
                      sharedPreferences.setBool("tops", false);
                    }

                  }, child: Text("Login",style: TextStyle(fontSize: 20.00),)),
                  SizedBox(height: 20,),
                  TextButton(onPressed: ()
                  {
                    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Signup()));
                  }, child: Text("Do you want to signup?"))
                ],
              ),
            ),
          )
      ),
    );
  }

  void checkdata()async
  {
   // sharedPreferences = await SharedPreferences.getInstance();
    var url = "https://prakrutitech.xyz/Seminar/signin.php";
    var resp = await http.post(Uri.parse(url),body:
    {

      "e1":myemail,
      "p1":mypass,
    } );
    var data = json.decode(resp.body);
    if(data==0)
    {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Fail")));
    }
    else
    {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Success")));

      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyApp()));
    }


    // print(resp.statusCode);
    // print("Executed");
    // Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyApp()));

  }

   checkvalue() async
  {
    sharedPreferences = await SharedPreferences.getInstance();
    newuser = sharedPreferences.getBool("tops")??true;

    if(newuser==false)
    {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => MyApp()));

    }
  }
}
