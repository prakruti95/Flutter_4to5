import 'package:flutter/material.dart';

class Radioscreen extends StatefulWidget {
  const Radioscreen({super.key});

  @override
  State<Radioscreen> createState() => _RadioscreenState();
}
enum Gender {male,female}

class _RadioscreenState extends State<Radioscreen>
{
  var data;
  Gender _gender = Gender.male;

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(title: Text("RadioButton"),),
      body: Center
        (
        child: Column
          (
          children:
          [

            ListTile
              (
                title: Text("Male"),
                leading:Radio(value: Gender.male, groupValue: _gender, onChanged:(value)
                {
                  setState(() {
                    _gender = value!;
                  });

                }),
              ),
            ListTile
              (
              title: Text("Female"),
              leading:Radio(value: Gender.female, groupValue: _gender, onChanged:(value)
              {
                setState(() {
                  _gender = value!;
                });
              }),
            )

          ],
        ),
      ),
    );
  }
}
