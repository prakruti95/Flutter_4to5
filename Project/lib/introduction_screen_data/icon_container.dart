import 'package:flutter/material.dart';
import '../../../others/mycolors.dart';

class IconContainer extends StatelessWidget {
  final IconData icon;
  final double padding;

  const IconContainer({
    super.key,
    required this.icon,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: kAccent.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 32,
        color: kNature,
      ),
    );
  }
}