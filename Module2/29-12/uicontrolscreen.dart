import 'package:flutter/material.dart';
import 'package:test6/radioscreen.dart';

import 'checkboxscreen.dart';

class UiControlScreen extends StatefulWidget 
{
  String data="";
  UiControlScreen({required this.data});
  
  @override
  State<UiControlScreen> createState() => _UiControlScreenState();
}

class _UiControlScreenState extends State<UiControlScreen>
{
  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("Welcome : ${widget.data}"),),
        body: Center
          (
              child: Row
                (
                children:
                [
                    ElevatedButton(onPressed: ()
                    {
                        Navigator.push(context,MaterialPageRoute(builder: (context) => Checkboxscreen()));
                    }, child: Text("Checkbox")),
                    ElevatedButton(onPressed: ()
                    {
                      Navigator.push(context,MaterialPageRoute(builder: (context) => Radioscreen()));

                    }, child: Text("RadioButton"))
                ],
                ),
          ),
      );
  }
}
