import 'package:flutter/material.dart';
import 'package:project56/splashscreen/splashscreen.dart';
import 'package:project56/theme/app_theme.dart'; // ✅ import your theme

class AppOpenPage extends StatelessWidget
{
  const AppOpenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Use your centralized theme
      theme: AppTheme.lightTheme,

      // ✅ Start screen
      home: const Splashscreen(),
    );
  }
}