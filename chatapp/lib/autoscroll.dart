import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AutoScrollStatusText extends StatefulWidget {
  final String text;
  final bool isOnline;

  const AutoScrollStatusText({
    Key? key,
    required this.text,
    required this.isOnline,
  }) : super(key: key);

  @override
  _AutoScrollStatusTextState createState() => _AutoScrollStatusTextState();
}

class _AutoScrollStatusTextState extends State<AutoScrollStatusText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;
  bool _needsScroll = false;
  double _scrollSpeed = 50.0; // Pixels per second - Increase this for faster speed

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Check after build if text needs scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollNeeded();
    });
  }

  void _checkIfScrollNeeded() {
    // Wait for render
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          setState(() {
            _needsScroll = true;
          });
          _startAutoScroll();
        }
      }
    });
  }

  void _startAutoScroll() {
    // Calculate duration based on text length and desired speed
    final textLength = widget.text.length;
    final durationSeconds = textLength / 5; // Adjust divisor for speed

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: durationSeconds.toInt().clamp(2, 10)),
    );

    _controller.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final value = _controller.value * maxScroll;
        _scrollController.jumpTo(value);
      }
    });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_needsScroll) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        physics: NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            Text(
              widget.text,
              style: TextStyle(
                fontSize: 12,
                color: widget.isOnline ? Colors.green : Colors.grey,
              ),
            ),
            SizedBox(width: 40), // More space for better visibility
          ],
        ),
      ),
    );
  }
}