import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';
import '../adminlogin.dart';



class AdminFront extends StatefulWidget
{
  @override
  FrontPage createState() => FrontPage();
}

class FrontPage extends State<AdminFront>
{
  late SharedPreferences logindata;

  @override
  void initState() {
    super.initState();
    initial();
  }

  void initial() async
  {
    logindata = await SharedPreferences.getInstance();
    logindata.setBool('ewishesadmin', false);

  }

  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>
  [
    //AdminHome(),
    //AdminUpload(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: Text('E wishes', style: TextStyle(color: kGold),),
        automaticallyImplyLeading: false,
        backgroundColor: kDarkBrown,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.logout,
              color: kGold,
            ),
            onPressed: () {
              logindata.setBool('ewishesadmin', true);

              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminLoginApp()));
            },
          ),
        ],
      ),
      body: Center(
        //child: _widgetOptions.elementAt(_selectedIndex),
      ),
      backgroundColor: kLightGold,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Upload',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kGold,
        backgroundColor: kDarkBrown,
        unselectedItemColor: kTerracotta,
        onTap: _onItemTapped,
      ),
    );
  }
}