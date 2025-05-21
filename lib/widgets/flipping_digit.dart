import 'package:flutter/material.dart';
import 'dart:async';

class FlippingDigit extends StatefulWidget {
  final int currentValue;
  final TextStyle style;
  final Duration animationDuration;

  const FlippingDigit({
    super.key,
    required this.currentValue,
    required this.style,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<FlippingDigit> createState() => _FlippingDigitState();
}

class _FlippingDigitState extends State<FlippingDigit> {
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.currentValue;
  }

  @override
  void didUpdateWidget(FlippingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentValue != oldWidget.currentValue) {
      // Update display value. Animation will be handled by AnimatedSwitcher.
      setState(() {
        _displayValue = widget.currentValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.animationDuration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Determine if it's an increment or decrement for slide direction
        // This logic is a bit simplified; for true digit-by-digit flip,
        // we'd need to know the previous value more directly if it wraps around (e.g. 9 to 0)
        // For now, a simple vertical slide.
        final inAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.8), // Slide in from bottom
          end: const Offset(0.0, 0.0),
        ).animate(animation);
        final outAnimation = Tween<Offset>(
          begin: const Offset(0.0, -0.8), // Slide out to top
          end: const Offset(0.0, 0.0),
        ).animate(animation);

        // If the child key is different, it means the value has changed.
        // We want the new value to slide in and the old value to slide out.
        // AnimatedSwitcher handles one child at a time.
        // To make it look like the old one slides out and new one slides in,
        // we can use a SlideTransition.
        // A simpler approach for "minimal" might be a fade.
        // Let's try a fade first for "minimal" as requested.
        return FadeTransition(opacity: animation, child: child);

        // For a slide effect (commented out):
        // return ClipRect( // Clip to prevent overflow during animation
        //   child: SlideTransition(
        //     position: Tween<Offset>(
        //       // A bit tricky to get perfect up/down for old/new with one child.
        //       // Let's make both slide in the same direction for simplicity.
        //       begin: const Offset(0.0, 0.8), // New value slides in from bottom
        //       end: Offset.zero,
        //     ).animate(animation),
        //     child: child,
        //   ),
        // );
      },
      child: Text(
        _displayValue.toString(),
        key: ValueKey<int>(_displayValue), // Important for AnimatedSwitcher to detect change
        style: widget.style,
      ),
    );
  }
}
