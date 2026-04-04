import 'package:flutter/material.dart';
import '../../../others/mycolors.dart';

class CardsStack extends StatelessWidget {
  final int pageNumber;
  final Widget lightCardChild;
  final Widget darkCardChild;

  const CardsStack({
    super.key,
    required this.pageNumber,
    required this.lightCardChild,
    required this.darkCardChild,
  });

  bool get isOddPageNumber => pageNumber % 2 == 1;

  @override
  Widget build(BuildContext context) {
    final darkCardWidth = MediaQuery.of(context).size.width - 2 * kPaddingL;
    final darkCardHeight = MediaQuery.of(context).size.height / 3;

    return Padding(
      padding: EdgeInsets.only(top: isOddPageNumber ? 25 : 50),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [

          // 🔵 Main Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: kPrimaryDark,
            child: Container(
              width: darkCardWidth,
              height: darkCardHeight,
              padding: EdgeInsets.only(
                top: !isOddPageNumber ? 100 : 0,
                bottom: isOddPageNumber ? 100 : 0,
              ),
              child: Center(child: darkCardChild),
            ),
          ),

          // ⚪ Top Card
          Positioned(
            top: !isOddPageNumber ? -25 : null,
            bottom: isOddPageNumber ? -25 : null,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: kCardBg,
              elevation: 4,
              child: Container(
                width: darkCardWidth * 0.8,
                height: darkCardHeight * 0.5,
                padding: const EdgeInsets.symmetric(horizontal: kPaddingM),
                child: Center(child: lightCardChild),
              ),
            ),
          ),
        ],
      ),
    );
  }
}