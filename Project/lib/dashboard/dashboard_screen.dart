import 'package:flutter/material.dart';
import 'package:project56/authentication/signin/loginscreen.dart';
import 'package:project56/dashboard/download/DownloadScreen.dart';
import 'package:project56/dashboard/home/HomeScreen.dart';
import 'package:project56/others/mycolors.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DashboardScreen extends StatefulWidget
{
  @override
  State<DashboardScreen> createState() => _DasboardScreenState();
}

class _DasboardScreenState extends State<DashboardScreen>
{

  String mynum = "";
  late SharedPreferences sharedPreferences;
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>
  [
    HomeScreen(),
    DownloadScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print(_selectedIndex);
    });
  }
  @override
  void initState()
  {
    // TODO: implement initState
    //super.initState();
    checkdata();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(
        title: Text("Welcome $mynum",style: TextStyle(color: Colors.white),),
        automaticallyImplyLeading: false,
        backgroundColor: kTextSecondary,
        actions:
        [
          IconButton(onPressed: ()
          {
            sharedPreferences.setBool("tops", true);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));

          }, icon: Icon(Icons.logout,color: Colors.white,))
        ],
      ),
      body: Center
        (
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      backgroundColor: kCardBg,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home"
            //title: Text('Home'),
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.download),
              label: "Download"
            //title: Text('Download'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kTextPrimary,
        backgroundColor: kTextSecondary,
        unselectedItemColor: kWhite,
        onTap: _onItemTapped,
      ),
    );
  }

  void checkdata()async
  {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(()
    {
      mynum = sharedPreferences.getString("mymob")!;
    });

  }
}