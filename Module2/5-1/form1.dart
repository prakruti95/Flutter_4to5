import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test6/welcome.dart';

import 'form2.dart';

class MyLoginPage extends StatefulWidget
{
  const MyLoginPage({super.key});

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage>
{
  TextEditingController uname = TextEditingController();
  TextEditingController pass = TextEditingController();
  late SharedPreferences sharedPreferences;

  var _formkey = GlobalKey<FormState>();
  var newuser;
  @override
  void initState()
  {
    // TODO: implement initState
    //super.initState();
    checkdata();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(title: Text("Form Example",style: TextStyle(color: Colors.white),),backgroundColor: Colors.blueGrey,),
      body: Form(
        key: _formkey,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Center
            (
              child: Column
                (
                children:
                [
                  TextFormField(controller:uname,decoration: InputDecoration(hintText: "Enter Username"),
                    validator: (value)
                    {
                      if (value!.isEmpty) {
                        return 'Please Enter Username';
                      }
                      return null;
                    },),
                  SizedBox(height:15),
                  TextFormField(controller:pass,decoration: InputDecoration(hintText: "Enter Password"),obscureText: true, validator: (value)
                  {
                    if (value!.isEmpty) {
                      return 'Please Enter Password';
                    }
                    return null;
                  },),
                  SizedBox(height:15),
                  ElevatedButton(onPressed: ()
                  {
                    if(_formkey.currentState!.validate())
                    {
                      String myuname = uname.text.toString();
                      String mypass = pass.text.toString();

                      if(myuname=="tops" && mypass=="1234")
                      {

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Success")));
                        sharedPreferences.setString("tops1", myuname);
                        sharedPreferences.setBool("app1", false);
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => WelcomeScreen2()));

                        //print("Login Success");
                      }
                      else
                      {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Fail")));
                        //print("Login Fail");
                      }
                    }



                    //print("$myuname and $mypass");

                  }, child: Text("Login"))

                ],
              )
          ),
        ),
      ),
    );
  }

  void checkdata() async
  {
    sharedPreferences = await SharedPreferences.getInstance();
    newuser = sharedPreferences.getBool('app1') ?? true;
    if(newuser==false)
    {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => WelcomeScreen2()));

    }

  }
}
