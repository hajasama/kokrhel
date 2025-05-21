import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:kokrhel_app/models/timer_model.dart';
import 'package:kokrhel_app/providers/timer_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AddEditTimerScreen extends StatefulWidget {
  final TimerModel? existingTimer;

  const AddEditTimerScreen({super.key, this.existingTimer});

  @override
  State<AddEditTimerScreen> createState() => _AddEditTimerScreenState();
}

class _AddEditTimerScreenState extends State<AddEditTimerScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _headerText;
  late int _hours, _minutes, _seconds;
  late Color _headerColor;
  late FinishBehavior _finishBehavior;
  late bool _vibrateOnFinish;
  String? _alarmSoundAssetPath;
  int? _maxAlarmTimeInSeconds; // We'll add UI for this later

  final _uuid = const Uuid();

  // List of available sound assets (relative to assets/ folder)
  final List<Map<String, String?>> _availableSounds = [
    {'name': 'None', 'path': null},
    {'name': 'Bell', 'path': 'sounds/bell.mp3'},
    {'name': 'Bird Chirp', 'path': 'sounds/bird-chirp.mp3'},
    {'name': 'Bright Bell', 'path': 'sounds/bright-bell.mp3'},
    {'name': 'Hand Bell', 'path': 'sounds/hand-bell-373.mp3'},
    {'name': 'Kohout', 'path': 'sounds/kohout.mp3'},
    {'name': 'Tibet Singing Bowl', 'path': 'sounds/tibet-singing-bowl.mp3'},
    {'name': 'Zen Deep', 'path': 'sounds/zen-deep.mp3'},
    {'name': 'Zen Gong', 'path': 'sounds/zen-gong.mp3'},
    {'name': 'Zen Tone', 'path': 'sounds/zen-tone.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTimer != null) {
      final timer = widget.existingTimer!;
      _headerText = timer.headerText;
      _headerColor = timer.headerTextColor;
      _finishBehavior = timer.finishBehavior;
      _vibrateOnFinish = timer.vibrateOnFinish;
      _alarmSoundAssetPath = timer.alarmSoundAssetPath;
      _maxAlarmTimeInSeconds = timer.maxAlarmTimeInSeconds;

      int totalSeconds = timer.initialDurationInSeconds;
      _hours = totalSeconds ~/ 3600;
      totalSeconds %= 3600;
      _minutes = totalSeconds ~/ 60;
      _seconds = totalSeconds % 60;
    } else {
      _headerText = 'My Timer';
      _hours = 0;
      _minutes = 1; // Default to 1 minute
      _seconds = 0;
      _headerColor = Colors.white; // Default color
      _finishBehavior = FinishBehavior.stop;
      _vibrateOnFinish = true;
      _alarmSoundAssetPath = null; // Or a default sound
      _maxAlarmTimeInSeconds = null;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final totalDurationInSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
      if (totalDurationInSeconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total duration must be greater than 0 seconds.')),
        );
        return;
      }

      final timerProvider = Provider.of<TimerProvider>(context, listen: false);

      if (widget.existingTimer != null) {
        // Update existing timer
        final updatedTimer = widget.existingTimer!.copyWith(
          headerText: _headerText,
          headerTextColorValue: _headerColor.value,
          initialDurationInSeconds: totalDurationInSeconds,
          // If it's an existing timer, we might want to decide if remainingDuration should also reset
          // For now, let's assume editing resets it or it's handled by the provider.
          // Let's make editing reset the remaining duration to the new initial for simplicity here.
          remainingDurationInSeconds: totalDurationInSeconds,
          finishBehavior: _finishBehavior,
          vibrateOnFinish: _vibrateOnFinish,
          alarmSoundAssetPath: _alarmSoundAssetPath,
          maxAlarmTimeInSeconds: _maxAlarmTimeInSeconds,
          isRunning: false, // Stop timer when editing, user can restart
          isCountingUp: false,
        );
        timerProvider.updateTimer(updatedTimer);
      } else {
        // Add new timer
        final newTimer = TimerModel(
          id: _uuid.v4(),
          headerText: _headerText,
          headerTextColorValue: _headerColor.value,
          initialDurationInSeconds: totalDurationInSeconds,
          remainingDurationInSeconds: totalDurationInSeconds,
          finishBehavior: _finishBehavior,
          vibrateOnFinish: _vibrateOnFinish,
          alarmSoundAssetPath: _alarmSoundAssetPath,
          maxAlarmTimeInSeconds: _maxAlarmTimeInSeconds,
        );
        timerProvider.addTimer(newTimer);
      }
      Navigator.of(context).pop();
    }
  }

  Widget _buildDurationField(String label, int initialValue, ValueChanged<int> onChanged, {int maxValue = 59}) {
    return Expanded(
      child: TextFormField(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        initialValue: initialValue.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          final val = int.tryParse(value);
          if (val == null) return 'Invalid';
          if (val < 0) return '>=0';
          if (label != 'H' && val > maxValue) return '<=${maxValue}'; // Hours can be > 59
          return null;
        },
        onSaved: (value) => onChanged(int.parse(value!)),
      ),
    );
  }

  // Placeholder for color picker
  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickerColor = _headerColor;
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              // enableAlpha: false, // Optional: disable alpha selection
              // displayThumbColor: true, // Optional: show current color thumb
              // showLabel: true, // Optional: show HEX, RGB, HSV labels
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                setState(() => _headerColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTimer == null ? 'Add New Timer' : 'Edit Timer'),
        // actions: [ // Save icon removed
        //   IconButton(
        //     icon: const Icon(Icons.save),
        //     onPressed: _submitForm,
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _headerText,
                decoration: const InputDecoration(labelText: 'Header Text', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter header text';
                  return null;
                },
                onSaved: (value) => _headerText = value!,
              ),
              const SizedBox(height: 20),
              const Text('Initial Duration:', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  _buildDurationField('H', _hours, (val) => _hours = val, maxValue: 99), // Hours
                  const SizedBox(width: 8),
                  const Text(':', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  _buildDurationField('M', _minutes, (val) => _minutes = val), // Minutes
                  const SizedBox(width: 8),
                  const Text(':', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  _buildDurationField('S', _seconds, (val) => _seconds = val), // Seconds
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Header Text Color'),
                trailing: CircleAvatar(backgroundColor: _headerColor, radius: 15),
                onTap: _pickColor, // Placeholder for actual color picker
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<FinishBehavior>(
                decoration: const InputDecoration(labelText: 'After Timer Finishes', border: OutlineInputBorder()),
                value: _finishBehavior,
                items: FinishBehavior.values.map((behavior) {
                  return DropdownMenuItem(
                    value: behavior,
                    child: Text(behavior == FinishBehavior.stop ? 'Stop' : 'Count Up'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _finishBehavior = value!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Vibrate on Finish'),
                value: _vibrateOnFinish,
                onChanged: (value) => setState(() => _vibrateOnFinish = value),
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(labelText: 'Alarm Sound', border: OutlineInputBorder()),
                value: _alarmSoundAssetPath,
                items: _availableSounds.map((sound) {
                  return DropdownMenuItem<String?>(
                    value: sound['path'],
                    child: Text(sound['name']!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _alarmSoundAssetPath = value),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _maxAlarmTimeInSeconds?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Max Alarm Duration (seconds)',
                  hintText: 'e.g., 30 (leave empty for continuous)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _maxAlarmTimeInSeconds = int.tryParse(value);
                  } else {
                    _maxAlarmTimeInSeconds = null; // No limit
                  }
                },
              ),
              const SizedBox(height: 20), // Adjusted spacing
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(widget.existingTimer == null ? 'Add Timer' : 'Save Changes', style: const TextStyle(color: Colors.white)),
              ),
              if (widget.existingTimer != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: Icon(Icons.delete_forever, color: Colors.red[400]),
                  label: Text('Delete Timer', style: TextStyle(color: Colors.red[400])),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete "${widget.existingTimer!.headerText}"? This action cannot be undone.'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                              child: const Text('DELETE'),
                              onPressed: () {
                                Provider.of<TimerProvider>(context, listen: false).removeTimer(widget.existingTimer!.id);
                                Navigator.of(ctx).pop(); // Close dialog
                                Navigator.of(context).pop(); // Close edit screen
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
