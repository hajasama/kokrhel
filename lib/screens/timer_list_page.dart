import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kokrhel_app/providers/timer_provider.dart';
import 'package:kokrhel_app/models/timer_model.dart';
import 'package:kokrhel_app/screens/add_edit_timer_screen.dart';
import 'package:kokrhel_app/widgets/timer_card_widget.dart';

class TimerListPage extends StatelessWidget {
  const TimerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the TimerProvider
    final timerProvider = Provider.of<TimerProvider>(context);
    final List<TimerModel> timers = timerProvider.timers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('kokrhel'),
      ),
      body: timers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No timers yet. Tap the + button to add your first timer!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            )
          : ListView.builder(
              itemCount: timers.length,
              itemBuilder: (context, index) {
                final timer = timers[index];
                return TimerCardWidget(timer: timer);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditTimerScreen(), // Navigate to AddEditTimerScreen
            ),
          );
        },
        tooltip: 'Add Timer',
        child: const Icon(Icons.add),
      ),
    );
  }
}
