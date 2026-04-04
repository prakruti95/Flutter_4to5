import 'package:flutter/material.dart';
import 'package:project56/authentication/signin/loginscreen.dart';
import 'package:project56/introduction_screen_data/pages/community/community_dark_card_content.dart';
import 'package:project56/introduction_screen_data/pages/community/community_light_card_content.dart';
import 'package:project56/introduction_screen_data/pages/community/community_text_column.dart';
import 'package:project56/introduction_screen_data/pages/onboarding_page.dart';
import 'package:project56/introduction_screen_data/pages/relationships/index.dart';
import 'package:project56/introduction_screen_data/pages/work/work_dark_card_content.dart';
import 'package:project56/introduction_screen_data/pages/work/work_light_card_content.dart';
import 'package:project56/introduction_screen_data/pages/work/work_text_column.dart';

import '../../others/mycolors.dart';
import 'header_intro.dart';
import 'next_page_button.dart';
import 'onboarding_page_indicator.dart'; // ✅ use your theme

class OnboardingScreen extends StatefulWidget
{
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg, // ✅ fixed

      body: SafeArea(
        child: Column(
          children: [

            // 🔝 Header
            Header(onSkip: _goToLogin),

            // 📄 Pages
            Expanded(child: _getPage()),

            // 🔘 Indicator + Button
            OnboardingPageIndicator(
              currentPage: _currentPage,
              child: NextPageButton(onPressed: _nextPage),
            ),
          ],
        ),
      ),
    );
  }

  // 🔁 Navigate to login
  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  // 🔄 Change page
  void _setNextPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  // 👉 Next button logic
  void _nextPage() {
    if (_currentPage < 3)
    {
      _setNextPage(_currentPage + 1);
    } else
    {
      _goToLogin();
    }
  }

  // 📄 Page builder
  Widget _getPage() {
    switch (_currentPage) {
      case 1:
        return const OnboardingPage(
          number: 1,
          lightCardChild: CommunityLightCardContent(),
          darkCardChild: CommunityDarkCardContent(),
          textColumn: CommunityTextColumn(),
        );

      case 2:
        return const OnboardingPage(
          number: 2,
          lightCardChild: WorkLightCardContent(), // ⚠️ replace if different
          darkCardChild: WorkDarkCardContent(),
          textColumn:WorkTextColumn(),
        );

      case 3:
        return const OnboardingPage(
          number: 3,
          lightCardChild: EducationLightCardContent(),
          darkCardChild: EducationDarkCardContent(),
          textColumn: EducationTextColumn(),
        );

      default:
        return const SizedBox();
    }
  }
}