import 'package:flutter/material.dart';
import 'package:kokrhel_app/widgets/flipping_digit.dart';

class AnimatedTimeDisplay extends StatelessWidget {
  final int totalSeconds;
  final TextStyle digitStyle;
  final TextStyle separatorStyle;

  const AnimatedTimeDisplay({
    super.key,
    required this.totalSeconds,
    required this.digitStyle,
    TextStyle? separatorStyle,
  }) : separatorStyle = separatorStyle ?? digitStyle;

  @override
  Widget build(BuildContext context) {
    int displaySeconds = totalSeconds;
    if (displaySeconds < 0) displaySeconds = 0; // Ensure non-negative

    final duration = Duration(seconds: displaySeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // Helper to build a two-digit segment (e.g., for MM or SS)
    Widget buildSegment(int value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlippingDigit(currentValue: value ~/ 10, style: digitStyle), // Tens digit
          FlippingDigit(currentValue: value % 10, style: digitStyle),  // Ones digit
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min, // Take up only necessary space
      children: <Widget>[
        buildSegment(hours),
        Text(':', style: separatorStyle),
        buildSegment(minutes),
        Text(':', style: separatorStyle),
        buildSegment(seconds),
      ],
    );
  }
}
