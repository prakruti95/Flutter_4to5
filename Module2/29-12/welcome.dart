import 'package:flutter/material.dart';
import 'package:test6/uicontrolscreen.dart';

class WelcomeScreen extends StatefulWidget
{
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
{

  TextEditingController name = TextEditingController();

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("Tops Technologies"),),
        body: Center
          (
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column
                (
                children:
                [
                    TextFormField(controller: name,decoration: InputDecoration(hintText: "Enter Your Name",border: OutlineInputBorder()),),
                    SizedBox(height: 10,),
                    TextButton(onPressed: ()
                    {
                        String data = name.text.toString();
                        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => UiControlScreen(data:data)));
                    }, child: Text("Submit"))
                ],
              ),
            ),
          ),
      );
  }
}
