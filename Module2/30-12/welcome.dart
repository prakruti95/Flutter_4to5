import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:test6/uicontrolscreen.dart';

class WelcomeScreen extends StatefulWidget
{
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
typedef MenuEntry = DropdownMenuEntry<String>;
class _WelcomeScreenState extends State<WelcomeScreen>
{
  TextEditingController name = TextEditingController();


  static List<String> citylist = <String>['Rajkot', 'Baroda', 'Ahmedabad', 'Surat'];

  static List<MenuEntry>menuEntries = UnmodifiableListView<MenuEntry>
    (
      citylist.map<MenuEntry>((String name) => MenuEntry(value: name, label: name)),
    );
    String dropdownvalue=citylist.first;
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("Tops Technologies3")),
        body: SingleChildScrollView(
          child: Center
            (
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column
                  (
                  children:
                  [
                    
                      Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSdOuEdroyRsFDVGMiRCgKMtH7d_UE4vG6iuA&s",width: 200,height: 200,),
                      SizedBox(height: 10,),
                      TextFormField(controller: name,decoration: InputDecoration(hintText: "Enter Your Name",border: OutlineInputBorder()),),
                      SizedBox(height: 10,),
                      Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSdOuEdroyRsFDVGMiRCgKMtH7d_UE4vG6iuA&s",width: 200,height: 200,),
                    SizedBox(height: 10,),
                    Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSdOuEdroyRsFDVGMiRCgKMtH7d_UE4vG6iuA&s",width: 200,height: 200,),
          
                    DropdownMenu
                        (
                          dropdownMenuEntries:menuEntries,
                          hintText: "Select Your City",
                          width: 200,
                          onSelected:(value)
                          {
                            setState(()
                            {
                              dropdownvalue = value!;
                            });
                          }
                        ),
          
                      TextButton(onPressed: ()
                      {
                          String data = name.text.toString();
                          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => UiControlScreen(data:data,city:dropdownvalue)));
                      }, child: Text("Submit")),
                    

                  ],
                ),
              ),
            ),
        ),
        floatingActionButton: FloatingActionButton(onPressed: (){},child: Icon(Icons.add),),
       //drawer: Drawer(),
       //bottomNavigationBar:BottomNavigationBar(items: []),
      );
  }
}
