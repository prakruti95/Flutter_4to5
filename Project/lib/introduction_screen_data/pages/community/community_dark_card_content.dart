import 'package:flutter/material.dart';
import '../../../../../others/mycolors.dart';

class CommunityDarkCardContent extends StatelessWidget {
  const CommunityDarkCardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [

        Padding(
          padding: EdgeInsets.only(top: kPaddingL),
          child: Icon(
            Icons.brush,
            color: kAccent, // 🔥 updated
            size: 32,
          ),
        ),

        Padding(
          padding: EdgeInsets.only(bottom: kPaddingL),
          child: Icon(
            Icons.camera_alt,
            color: kAccent,
            size: 32,
          ),
        ),

        Padding(
          padding: EdgeInsets.only(top: kPaddingL),
          child: Icon(
            Icons.straighten,
            color: kAccent,
            size: 32,
          ),
        ),
      ],
    );
  }
}