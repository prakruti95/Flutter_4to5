import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project56/others/check_connectivity.dart';
import 'package:project56/others/mycolors.dart';

import '../introduction_screen_data/onboardingscreen.dart';

class Splashscreen extends StatefulWidget
{
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
{

  @override
  void initState() {
   // super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // ✅ Internet check (optional but useful)
    await MyConnectionChecker.checkconnection(context);

    // ✅ Splash delay (animation show time)
    await Future.delayed(const Duration(seconds: 5));

    // ✅ Safety check (important)
    if (!mounted) return;

    // ✅ Navigation (change route if needed)
   // Navigator.pushReplacementNamed(context, '/home');
    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark, // 🎨 from your theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 🔥 Lottie Animation
            Lottie.asset(
              'assets/splash_logo.json',
              width: 160,
              height: 160,
            ),

            const SizedBox(height: 20),

            // 🏷 App Name
            const Text(
              "My App",
              style: TextStyle(
                color: kWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            // ✨ Tagline (optional but looks premium)
            const Text(
              "Explore • Download • Share",
              style: TextStyle(
                color: kAccent,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}