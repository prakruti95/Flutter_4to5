import 'package:flutter/material.dart';
import '../../../../../others/mycolors.dart';

class EducationDarkCardContent extends StatelessWidget {
  const EducationDarkCardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.laptop_mac,
      color: kAccent, // 🔥 updated
      size: 96,
    );
  }
}