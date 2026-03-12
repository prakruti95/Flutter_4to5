import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() 
{
  runApp(MaterialApp(home: MyApp()));
}
class MyApp extends StatefulWidget
{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
{
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  @override
  Widget build(BuildContext context) {
    return Scaffold
      (
        appBar: AppBar(title: Text("Login With Gmail Example"),actions:
        [
          IconButton(onPressed: () async
          {
            await _googleSignIn.signOut();
          },
              icon: Icon(Icons.logout))
        ],),
        body: Center
          (
          child: ElevatedButton
            (
            onPressed: ()
            {
              _handleSignIn(context);
            }, child: Text("Login With Gmail"),
          ),

          ),

    );
  }

   _handleSignIn(BuildContext context)async
  {
        try
        {
          GoogleSignInAccount? googleaccount = await _googleSignIn.signIn();
          if(googleaccount!=null)
            {
              GoogleSignInAuthentication googleSignInAuthentication = await googleaccount.authentication;

              final accessToken = googleSignInAuthentication.accessToken;
              final idToken = googleSignInAuthentication.idToken;

              print("$accessToken");
              print("$idToken");

              if(accessToken != null)
              {
                print("Name is :" + googleaccount.displayName.toString());
                print("Email is :" + googleaccount.email.toString());
                print("Photo is :" + googleaccount.photoUrl.toString());
              }
            }
        }
        catch(e)
       {
          print(e);
       }
  }
}

