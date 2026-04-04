import 'package:flutter/material.dart';
import '../../../others/mycolors.dart';

class NextPageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NextPageButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      padding: const EdgeInsets.all(kPaddingM),
      shape: const CircleBorder(),
      fillColor: kAccent, // 🔥 main change
      onPressed: onPressed,
      child: const Icon(
        Icons.arrow_forward,
        color: kWhite,
        size: 32,
      ),
    );
  }
}