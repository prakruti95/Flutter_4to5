import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'constraints/textfield.dart';
import 'home.dart';



class Adddata extends StatefulWidget {
  const Adddata({super.key});

  @override
  State<Adddata> createState() => _AdddataState();
}

class _AdddataState extends State<Adddata> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  _clearText() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String email = '';
  String name = '';
  String password = '';

  CollectionReference addUser = FirebaseFirestore.instance.collection('Students');

  // Future<void> _registerUser()async
  // {
  //   return addUser.add({'Name':name,'Email':email,'Password':password})
  //       .then((value) => Navigator.push(context,MaterialPageRoute(builder: (context) => HomeScreen())))
  //       .catchError((e) => print('Something Error In registering User $e'));
  //
  // }
  Future<void> _registerUser() async
  {
    try
    {
      await addUser.add({'Name': name, 'Email': email, 'Password': password});

      if (!mounted) return; // <-- Check if widget is still mounted

      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
    catch (e)
    {
      print('Something Error In registering User $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold
      (
        body: Form
          (
          key: _formkey,
          child: ListView
            (
              children:
              [

                CustomTextEditField(
                  controller: nameController,
                  labettxt: 'Name',
                ),
                CustomTextEditField(
                  controller: emailController,
                  labettxt: 'Email',
                  valid: true,
                ),
                CustomTextEditField(
                  controller: passwordController,
                  labettxt: 'Password',
                  visibility: true,
                ),
                Row
                  (
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: ()
                      {
                        if (_formkey.currentState!.validate())
                        {
                          setState(() {
                            name = nameController.text.toString();
                            email = emailController.text.toString();
                            password = passwordController.text.toString();
                            _registerUser();
                            _clearText();
                            Navigator.pop(context);
                          });
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.green),
                      ),
                      child: const Text('Register'),
                    ),
                    ElevatedButton(
                      onPressed: _clearText,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      child: const Text('Clear'),
                    ),


                  ],
                )
              ]

          ),
        ));
  }


}