import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:project56/others/mycolors.dart';

import '../introduction_screen_data/onboardingscreen.dart';

class MyConnectionChecker {

  static Future<void> checkconnection(BuildContext context) async {
    bool hasConnection = await InternetConnectionChecker().hasConnection;

    if (!context.mounted) return;

    if (hasConnection) {
      // ✅ Direct navigation (no extra delay needed)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    } else {
      shownetworkerrordialog(context);
    }
  }

  static void shownetworkerrordialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          // 🔥 Title
          title: Row(
            children: const [
              Icon(Icons.wifi_off, color: kPrimaryDark),
              SizedBox(width: 10),
              Text(
                "No Internet",
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),

          // 📄 Content
          content: const Text(
            'Please check your internet connection and try again.',
            style: TextStyle(
              color: kTextSecondary,
            ),
          ),

          // 🎯 Actions
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                checkconnection(context); // retry
              },
              child: const Text(
                "Retry",
                style: TextStyle(color: kAccent),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                // ✅ Instead of exit(0)
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}