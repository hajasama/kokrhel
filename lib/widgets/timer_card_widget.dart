import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kokrhel_app/models/timer_model.dart';
import 'package:kokrhel_app/providers/timer_provider.dart';
import 'package:kokrhel_app/screens/add_edit_timer_screen.dart';
// import 'package:google_fonts/google_fonts.dart'; // No longer needed as Lato is bundled
import 'package:kokrhel_app/widgets/animated_time_display.dart';

class TimerCardWidget extends StatelessWidget {
  final TimerModel timer;

  const TimerCardWidget({super.key, required this.timer});

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    // Unique key for Dismissible that changes when timer state relevant to swipe action changes
    // This helps reset the Dismissible's visual state after an action.
    // Using remainingDurationInSeconds ensures it resets after a reset action.
    // For navigation, it might not auto-reset visually without further state management in this widget
    // or its parent if the list item itself isn't fully rebuilt.
    final dismissibleKey = ValueKey('${timer.id}_${timer.remainingDurationInSeconds}_${timer.isRunning}');

    return Dismissible(
      key: dismissibleKey,
      background: Container( // Right swipe background (Reset)
        color: Colors.black,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.refresh, color: Colors.white54),
            SizedBox(width: 8),
            Text('Reset', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container( // Left swipe background (Options)
        color: Colors.black,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text('Options', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.settings_outlined, color: Colors.white54),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) { // Swiped Right (Reset)
          timerProvider.resetTimer(timer.id);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('${timer.headerText} reset')),
          // ); // Notification removed
          return false; // Prevent actual dismiss, force snap back
        } else if (direction == DismissDirection.endToStart) { // Swiped Left (Open Options)
          // Ensure context is still valid before navigating
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddEditTimerScreen(existingTimer: timer),
              ),
            );
          }
          return false; // Prevent actual dismiss, force snap back
        }
        return false; // Should not happen if directions are limited
      },
      // onDismissed is no longer needed as actions are handled in confirmDismiss
      child: GestureDetector( // Keep GestureDetector for tap-to-play/pause
        onTap: () {
          if (timer.isRunning) {
            timerProvider.pauseTimer(timer.id);
          } else {
            timerProvider.startTimer(timer.id);
          }
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 79, // Increased size by 15% (69 * 1.15 = 79.35)
                  height: 79, // Increased size by 15%
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800]?.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (timer.initialDurationInSeconds > 0)
                        SizedBox(
                          width: 79, // Increased size by 15%
                          height: 79, // Increased size by 15%
                        child: CircularProgressIndicator(
                          value: timer.initialDurationInSeconds > 0
                              ? timer.remainingDurationInSeconds / timer.initialDurationInSeconds
                              : 1.0, // Show full if initial is 0 (or handle as error)
                          strokeWidth: 4, // Thickness of the line
                          backgroundColor: Colors.grey[700], // Track color for the "empty" part
                          valueColor: AlwaysStoppedAnimation<Color>(
                            timer.isRunning ? Colors.greenAccent : Colors.blueGrey[600]!, // Color of the "remaining" part
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        timer.headerText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: timer.headerTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    AnimatedTimeDisplay(
                      totalSeconds: timer.remainingDurationInSeconds,
                      digitStyle: TextStyle( // Use bundled Lato font
                        fontFamily: 'Lato',
                        fontSize: 62,
                        fontWeight: FontWeight.w100,
                        color: Colors.blue[300],
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
