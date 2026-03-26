import 'package:flutter/material.dart';
import 'package:myproviderex/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget 
{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
{
  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
      (
        appBar: AppBar(title: Text("Switch Theme"),),
        body: Center
          (
          child: Consumer<ThemeProvider>(builder: (context,value,child)
          {
              return Row
                (
                  children:
                  [
                    Text(
                      value.isDark ? "Dark Mode" : "Light Mode",
                      style: TextStyle(fontSize: 18),
                    ),

                    SizedBox(width: 10),

                    Switch(
                      value: value.isDark,
                      onChanged: (value1)
                      {
                        value.toggleTheme(value1);
                      },
                    ),

                  ],
                );
          },)
        ),
      );
  }
}
