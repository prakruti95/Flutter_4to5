import 'package:flutter/material.dart';
import 'package:myproviderex/theme_provider.dart';
import 'package:provider/provider.dart';

import 'home.dart';

class MyApp2 extends StatefulWidget
{
  const MyApp2({super.key});

  @override
  State<MyApp2> createState() => _MyApp2State();
}

class _MyApp2State extends State<MyApp2>
{
  @override
  Widget build(BuildContext context)
  {
    return Consumer<ThemeProvider>(builder:(context, themeProvider, child)
    {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: HomeScreen(),
      );
    });
  }
}
