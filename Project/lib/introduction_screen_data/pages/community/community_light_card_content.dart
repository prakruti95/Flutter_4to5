import 'package:flutter/material.dart';
import '../../../../../others/mycolors.dart';
import '../../icon_container.dart';

class CommunityLightCardContent extends StatelessWidget {
  const CommunityLightCardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        IconContainer(
          icon: Icons.person,
          padding: kPaddingS,
        ),

        IconContainer(
          icon: Icons.group,
          padding: kPaddingM,
        ),

        IconContainer(
          icon: Icons.insert_emoticon,
          padding: kPaddingS,
        ),
      ],
    );
  }
}