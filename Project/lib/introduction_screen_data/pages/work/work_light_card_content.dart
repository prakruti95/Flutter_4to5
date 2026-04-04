import 'package:flutter/material.dart';
import '../../../../../others/mycolors.dart';
import '../../icon_container.dart';

class WorkLightCardContent extends StatelessWidget {
  const WorkLightCardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        IconContainer(
          icon: Icons.event_seat,
          padding: kPaddingS,
        ),

        IconContainer(
          icon: Icons.business_center,
          padding: kPaddingM,
        ),

        IconContainer(
          icon: Icons.assessment,
          padding: kPaddingS,
        ),
      ],
    );
  }
}