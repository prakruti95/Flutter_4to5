import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jsoncrud1/main.dart';
import 'package:jsoncrud1/signin.dart';

class Signup extends StatefulWidget
{
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup>
{
  TextEditingController name = TextEditingController();
  TextEditingController surname = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();

  late String myname,mysurname,myemail,mypass;
  var _formkey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Form
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
                    TextFormField(controller:name,decoration: InputDecoration(hintText: "Enter name",border: OutlineInputBorder()),validator:(value)
                    {
                      if(name.text.toString().isEmpty)
                      {
                        return "Please Enter name";
                      }
                    },),
                    SizedBox(height: 10,),
                    TextFormField(controller:surname,decoration: InputDecoration(hintText: "Enter surname",border: OutlineInputBorder()),
                      validator: (value)
                      {
                        if(surname.text.toString().isEmpty)
                        {
                          return "Please Enter Surname";
                        }
                      },
                    ),
                    SizedBox(height: 10,),
        
        
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
                      myname = name.text.toString();
                      mysurname = surname.text.toString();
                      myemail = email.text.toString();
                      mypass = pass.text.toString();
                      if(_formkey.currentState!.validate())
                      {
                        adddata();
                      }
        
                    }, child: Text("Signup",style: TextStyle(fontSize: 20.00),)),
                    SizedBox(height: 20,),
                    TextButton(onPressed: ()
                    {
                      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Signin()));
                    }, child: Text("Login?"))
                  ],
                ),
              ),
            )
        ),
      ),
    );
  }

  void adddata()async
  {
    var url = "https://prakrutitech.xyz/Seminar/signup.php";
    var resp = await http.post(Uri.parse(url),body:
    {
      "name":myname,
      "surname":mysurname,
      "email":myemail,
      "password":mypass,
    } );
    print(resp.statusCode);
    print("Executed");
    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => Signin()));

  }
}
