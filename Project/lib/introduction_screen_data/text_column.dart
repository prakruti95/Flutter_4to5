import 'package:flutter/material.dart';
import '../../../others/mycolors.dart';

class TextColumn extends StatelessWidget {
  final String title;
  final String text;

  const TextColumn({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        const SizedBox(height: kSpaceS),

        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }
}