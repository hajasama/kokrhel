import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:kokrhel_app/models/timer_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class TimerProvider with ChangeNotifier {
  List<TimerModel> _timers = [];
  final Uuid _uuid = const Uuid();
  static const String _timersKey = 'kokrhel_timers';

  // Map to keep track of active Dart Timers for each Kokrhel TimerModel
  final Map<String, Timer> _activeCountdownTimers = {};
  // Map to keep track of AudioPlayers for currently sounding alarms
  final Map<String, AudioPlayer> _activeAlarmPlayers = {};
  // Map to keep track of timers that limit alarm duration
  final Map<String, Timer> _alarmDurationLimitTimers = {};

  List<TimerModel> get timers => _timers;

  TimerProvider() {
    _loadTimers();
  }

  // --- Persistence ---
  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timersString = prefs.getString(_timersKey);
    if (timersString != null) {
      final List<dynamic> timersJson = jsonDecode(timersString) as List<dynamic>;
      _timers = timersJson.map((json) => TimerModel.fromJson(json as Map<String, dynamic>)).toList();
      // Ensure any timers that were running are correctly handled (e.g., restart or mark as paused)
      // For now, we'll just load them. Active state restoration can be complex.
      // We might also want to re-initialize any active countdowns here if the app was killed.
    }
    notifyListeners();
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String timersString = jsonEncode(_timers.map((timer) => timer.toJson()).toList());
    await prefs.setString(_timersKey, timersString);
  }

  // --- CRUD Operations ---
  void addTimer(TimerModel timer) {
    // Ensure new timers get a unique ID if not already provided (though usually generated before calling this)
    final newTimer = timer.id.isEmpty ? timer.copyWith(id: _uuid.v4()) : timer;
    _timers.add(newTimer);
    _saveTimers();
    notifyListeners();
  }

  void updateTimer(TimerModel updatedTimer) {
    final index = _timers.indexWhere((timer) => timer.id == updatedTimer.id);
    if (index != -1) {
      // If the timer was running and its duration changes, we might need to restart its Dart Timer
      if (_timers[index].isRunning && _activeCountdownTimers.containsKey(updatedTimer.id)) {
        if (_timers[index].initialDurationInSeconds != updatedTimer.initialDurationInSeconds ||
            _timers[index].remainingDurationInSeconds != updatedTimer.remainingDurationInSeconds) {
          _stopDartTimer(updatedTimer.id);
          if (updatedTimer.isRunning) {
            _startDartTimer(updatedTimer);
          }
        }
      }
      _timers[index] = updatedTimer;
      _saveTimers();
      notifyListeners();
    }
  }

  void removeTimer(String id) {
    _stopDartTimer(id);
    _stopAlarmSound(id); // Ensure alarm sound & limit timer are stopped
    _timers.removeWhere((timer) => timer.id == id);
    _saveTimers();
    notifyListeners();
  }

  // --- Timer Control ---
  void startTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index != -1 && !_timers[index].isRunning && _timers[index].remainingDurationInSeconds > 0) {
      _timers[index] = _timers[index].copyWith(isRunning: true, isCountingUp: false);
      _startDartTimer(_timers[index]);
      _saveTimers(); // Save state change
      notifyListeners();
    }
  }

  void pauseTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index != -1 && _timers[index].isRunning) {
      _timers[index] = _timers[index].copyWith(isRunning: false);
      _stopDartTimer(id);
      // Optionally stop alarm sound on pause, or let it continue based on preference.
      // For now, let's assume pausing the timer itself doesn't immediately stop an already-triggered alarm
      // unless the alarm's own max duration is hit.
      // If we want pause to stop alarms: _stopAlarmSound(id);
      _saveTimers(); // Save state change
      notifyListeners();
    }
  }

  void resetTimer(String id) {
    final index = _timers.indexWhere((timer) => timer.id == id);
    if (index != -1) {
      _stopDartTimer(id);
      _stopAlarmSound(id); // Ensure alarm sound & limit timer are stopped on reset
      _timers[index] = _timers[index].copyWithReset(); // Uses the helper in TimerModel
      _saveTimers();
      notifyListeners();
    }
  }

  void _startDartTimer(TimerModel timerModel) {
    // Cancel any existing timer for this ID before starting a new one
    _activeCountdownTimers[timerModel.id]?.cancel();

    if (!timerModel.isRunning || timerModel.remainingDurationInSeconds <= 0) {
      return; // Don't start if not supposed to be running or no time left
    }

    _activeCountdownTimers[timerModel.id] = Timer.periodic(const Duration(seconds: 1), (dartTimer) {
      final currentIndex = _timers.indexWhere((t) => t.id == timerModel.id);
      if (currentIndex == -1 || !_timers[currentIndex].isRunning) {
        dartTimer.cancel(); // Stop if timer removed or paused
        _activeCountdownTimers.remove(timerModel.id);
        return;
      }

      if (_timers[currentIndex].isCountingUp) { // Handle count-up logic
        _timers[currentIndex] = _timers[currentIndex].copyWith(
          remainingDurationInSeconds: _timers[currentIndex].remainingDurationInSeconds + 1,
        );
      } else { // Handle countdown logic
         _timers[currentIndex] = _timers[currentIndex].copyWith(
          remainingDurationInSeconds: _timers[currentIndex].remainingDurationInSeconds - 1,
        );
        if (_timers[currentIndex].remainingDurationInSeconds <= 0) {
          _handleTimerFinish(_timers[currentIndex], dartTimer);
        }
      }
      _saveTimers(); // Persist every tick for resilience, can be optimized
      notifyListeners();
    });
  }

  void _stopDartTimer(String id) {
    _activeCountdownTimers[id]?.cancel();
    _activeCountdownTimers.remove(id);
  }

  void _handleTimerFinish(TimerModel finishedTimer, Timer dartTimer) {
    // Play sound, vibrate (to be implemented)
    // print('Timer ${finishedTimer.id} finished!');
    _playSound(finishedTimer.id, finishedTimer.alarmSoundAssetPath, finishedTimer.maxAlarmTimeInSeconds);
    _vibrate(finishedTimer.vibrateOnFinish, finishedTimer.maxAlarmTimeInSeconds);


    if (finishedTimer.finishBehavior == FinishBehavior.stop) {
      dartTimer.cancel();
      _activeCountdownTimers.remove(finishedTimer.id);
      updateTimer(finishedTimer.copyWith(isRunning: false, remainingDurationInSeconds: 0));
    } else if (finishedTimer.finishBehavior == FinishBehavior.countUp) {
      // Timer continues, but now counts up
      updateTimer(finishedTimer.copyWith(isCountingUp: true, remainingDurationInSeconds: 0));
      // The existing dartTimer will now handle count-up logic in _startDartTimer's callback
    }
  }

  // Placeholder for sound and vibration
  Future<void> _playSound(String timerId, String? soundPath, int? maxDurationSeconds) async {
    if (soundPath == null || soundPath.isEmpty) return;

    // Stop any existing player for this timer ID
    await _activeAlarmPlayers[timerId]?.stop();
    await _activeAlarmPlayers[timerId]?.dispose();
    _activeAlarmPlayers.remove(timerId);
    _alarmDurationLimitTimers[timerId]?.cancel();
    _alarmDurationLimitTimers.remove(timerId);

    try {
      final player = AudioPlayer();
      _activeAlarmPlayers[timerId] = player;
      await player.play(AssetSource(soundPath));

      player.onPlayerComplete.first.then((_) {
        // Clean up when sound naturally finishes
        _activeAlarmPlayers[timerId]?.dispose();
        _activeAlarmPlayers.remove(timerId);
        _alarmDurationLimitTimers[timerId]?.cancel(); // Cancel limit timer if sound finishes first
        _alarmDurationLimitTimers.remove(timerId);
      });

      if (maxDurationSeconds != null && maxDurationSeconds > 0) {
        _alarmDurationLimitTimers[timerId] = Timer(Duration(seconds: maxDurationSeconds), () {
          _stopAlarmSound(timerId);
        });
      }
    } catch (e) {
      // print("Error playing sound for $timerId: $e");
      _activeAlarmPlayers.remove(timerId); // Clean up on error
    }
  }

  Future<void> _stopAlarmSound(String timerId) async {
    await _activeAlarmPlayers[timerId]?.stop();
    await _activeAlarmPlayers[timerId]?.dispose();
    _activeAlarmPlayers.remove(timerId);
    _alarmDurationLimitTimers[timerId]?.cancel(); // Also cancel the limit timer
    _alarmDurationLimitTimers.remove(timerId);
    // If vibration was also tied to this, might stop it here too, or manage separately
    Vibration.cancel(); // Stop any ongoing vibration
  }

  Future<void> _vibrate(bool shouldVibrate, int? maxDurationSeconds) async {
    if (!shouldVibrate) return;
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {
        // Vibration.vibrate(); // Standard vibration
        // For maxDurationSeconds, we'd typically want a pattern or to stop it.
        // Since Vibration.cancel() is called in _stopAlarmSound,
        // a simple vibrate() here will be stopped if the alarm sound stops.
        // If sound is 'None' but vibration is on with max duration, this needs more thought.
        // For now, let's assume vibration stops when sound stops or max duration is hit.
        Vibration.vibrate();
      }
    } catch (e) {
      // print("Error vibrating: $e");
    }
  }

  @override
  void dispose() {
    // Cancel all active Dart Timers when the provider is disposed
    _activeCountdownTimers.forEach((_, dartTimer) => dartTimer.cancel());
    _activeCountdownTimers.clear();
    _activeAlarmPlayers.forEach((_, player) {
      player.stop();
      player.dispose();
    });
    _activeAlarmPlayers.clear();
    _alarmDurationLimitTimers.forEach((_, timer) => timer.cancel());
    _alarmDurationLimitTimers.clear();
    super.dispose();
  }
}
