import 'package:flutter/material.dart';
import 'package:test6/radioscreen.dart';

import 'checkboxscreen.dart';

class UiControlScreen extends StatefulWidget 
{
  String data="";
  String city="";
  UiControlScreen({required this.data,required this.city});
  
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
        appBar: AppBar(title: Text("Welcome : ${widget.data} from ${widget.city}"),),
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
