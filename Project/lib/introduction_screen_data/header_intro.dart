import 'package:flutter/material.dart';
import '../others/mycolors.dart';

class Header extends StatelessWidget {
  final VoidCallback onSkip;

  const Header({
    super.key,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Top padding set to 60px as requested
      // Horizontal padding (kPaddingL) keeps it away from screen edges
      padding: const EdgeInsets.only(
        top: kPaddingT,
        left: kPaddingL,
        right: kPaddingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Aligns Skip text vertically with Logo
        children: <Widget>[
          // TOPS Technologies Logo
          Image.asset(
            'assets/logo.png',
            height: 50,
            width: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.school,
              color: kCardBg,
              size: 40,
            ),
          ),

          // Skip Button
          GestureDetector(
            onTap: onSkip,
            behavior: HitTestBehavior.opaque, // Makes the empty space around 'Skip' clickable
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: kAccent, // Updated to your Blue Grey theme
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}