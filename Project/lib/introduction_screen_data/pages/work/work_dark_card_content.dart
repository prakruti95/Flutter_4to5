import 'package:flutter/material.dart';
import '../../../../../others/mycolors.dart';

class WorkDarkCardContent extends StatelessWidget {
  const WorkDarkCardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.person_pin,
              color: kAccent, // 🔥 updated
              size: 32,
            ),
          ],
        ),

        const SizedBox(height: kSpaceM),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Icon(Icons.person, color: kAccent, size: 32),
            Icon(Icons.group, color: kAccent, size: 32),
            Icon(Icons.insert_emoticon, color: kAccent, size: 32),
          ],
        ),
      ],
    );
  }
}