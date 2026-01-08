import 'package:flutter/material.dart';

import 'listex.dart';

class MyDrawer extends StatefulWidget
{
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer>
{
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
       (
        appBar: AppBar(title: Text("My Navigation Drawer"),),
        body: Center
          (

          ),
        drawer: Drawer
          (
            child: ListView
              (
                children:
                [
                  UserAccountsDrawerHeader(
                    accountName: Text("Abhishek Mishra"),
                    accountEmail: Text("abhishekm977@gmail.com"),
                    currentAccountPictureSize: Size.square(72.0),
                    currentAccountPicture: CircleAvatar
                      (
                        backgroundColor: Colors.orange,
                        radius: 50.00 ,

                      child: Text
                        (
                         "A",
                         style: TextStyle(fontSize: 40.0),
                      ),
                    ),
                  ),

                  ListTile(
                    leading: Icon(Icons.home), title: Text("Home"),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings), title: Text("Settings"),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.contacts), title: Text("Contact Us"),
                    onTap: ()
                    {
                      Navigator.push(context,MaterialPageRoute(builder: (context) => ListEx()));
                     // Navigator.pop(context);
                    },
                  ),
                ],
              ),
          ),
       );
  }
}
