import 'package:flutter/material.dart';

class Checkboxscreen extends StatefulWidget
{
  const Checkboxscreen({super.key});

  @override
  State<Checkboxscreen> createState() => _CheckboxscreenState();
}

class _CheckboxscreenState extends State<Checkboxscreen>
{
  var first=false;
  var second=false;
  var third=false;

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
       appBar: AppBar(title: Text("Checkbox"),),
       body: Center
         (
          child: Column
            (
              children:
              [

                CheckboxListTile(value: first, onChanged:(value)
                {
                    setState(() {
                      this.first=value!;
                    });
                },title: Text("Cricket"),),
                CheckboxListTile(value: second, onChanged:(value)
                {
                  setState(() {
                    this.second=value!;
                  });
                },title: Text("Movies"),),
                CheckboxListTile(value: third, onChanged:(value)
                {
                  setState(() {
                    this.third=value!;
                  });
                },title: Text("Music"),)


              ],
            ),
         ),
      );
  }
}
