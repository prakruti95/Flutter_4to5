import 'package:flutter/material.dart';
import '../../../../../others/mycolors.dart';
import '../../icon_container.dart';

class EducationLightCardContent extends StatelessWidget {
  const EducationLightCardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        IconContainer(
          icon: Icons.brush,
          padding: kPaddingS,
        ),

        IconContainer(
          icon: Icons.camera_alt,
          padding: kPaddingM,
        ),

        IconContainer(
          icon: Icons.straighten,
          padding: kPaddingS,
        ),
      ],
    );
  }
}