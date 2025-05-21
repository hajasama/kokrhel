import 'package:flutter/material.dart'; // For Color

enum FinishBehavior { stop, countUp }

class TimerModel {
  String id;
  String headerText;
  int headerTextColorValue; // Store as int (Color.value) for JSON serialization
  int initialDurationInSeconds;
  int remainingDurationInSeconds;
  FinishBehavior finishBehavior;
  String? alarmSoundAssetPath; // Path to sound in assets
  int? maxAlarmTimeInSeconds; // Optional: max duration alarm plays
  bool vibrateOnFinish;
  bool isRunning;
  bool isCountingUp; // True if timer finished and is now counting up

  TimerModel({
    required this.id,
    this.headerText = 'Timer',
    this.headerTextColorValue = 0xFFFFFFFF, // Default to white (Colors.white.value)
    required this.initialDurationInSeconds,
    required this.remainingDurationInSeconds,
    this.finishBehavior = FinishBehavior.stop,
    this.alarmSoundAssetPath,
    this.maxAlarmTimeInSeconds,
    this.vibrateOnFinish = true,
    this.isRunning = false,
    this.isCountingUp = false,
  });

  Color get headerTextColor => Color(headerTextColorValue);
  set headerTextColor(Color color) => headerTextColorValue = color.value;

  // For JSON serialization/deserialization (persistence)
  Map<String, dynamic> toJson() => {
        'id': id,
        'headerText': headerText,
        'headerTextColorValue': headerTextColorValue,
        'initialDurationInSeconds': initialDurationInSeconds,
        'remainingDurationInSeconds': remainingDurationInSeconds,
        'finishBehavior': finishBehavior.toString(), // Store enum as string
        'alarmSoundAssetPath': alarmSoundAssetPath,
        'maxAlarmTimeInSeconds': maxAlarmTimeInSeconds,
        'vibrateOnFinish': vibrateOnFinish,
        'isRunning': isRunning,
        'isCountingUp': isCountingUp,
      };

  factory TimerModel.fromJson(Map<String, dynamic> json) => TimerModel(
        id: json['id'] as String,
        headerText: json['headerText'] as String,
        headerTextColorValue: json['headerTextColorValue'] as int,
        initialDurationInSeconds: json['initialDurationInSeconds'] as int,
        remainingDurationInSeconds: json['remainingDurationInSeconds'] as int,
        finishBehavior: FinishBehavior.values.firstWhere(
          (e) => e.toString() == json['finishBehavior'] as String,
          orElse: () => FinishBehavior.stop, // Default if parsing fails
        ),
        alarmSoundAssetPath: json['alarmSoundAssetPath'] as String?,
        maxAlarmTimeInSeconds: json['maxAlarmTimeInSeconds'] as int?,
        vibrateOnFinish: json['vibrateOnFinish'] as bool,
        isRunning: json['isRunning'] as bool? ?? false, // Handle potential null from older versions
        isCountingUp: json['isCountingUp'] as bool? ?? false, // Handle potential null
      );

  // Helper to reset timer to initial state
  TimerModel copyWithReset() {
    return TimerModel(
      id: id,
      headerText: headerText,
      headerTextColorValue: headerTextColorValue,
      initialDurationInSeconds: initialDurationInSeconds,
      remainingDurationInSeconds: initialDurationInSeconds, // Reset remaining to initial
      finishBehavior: finishBehavior,
      alarmSoundAssetPath: alarmSoundAssetPath,
      maxAlarmTimeInSeconds: maxAlarmTimeInSeconds,
      vibrateOnFinish: vibrateOnFinish,
      isRunning: false, // Not running after reset
      isCountingUp: false, // Not counting up after reset
    );
  }

  // General copyWith method for updates
   TimerModel copyWith({
    String? id,
    String? headerText,
    int? headerTextColorValue,
    int? initialDurationInSeconds,
    int? remainingDurationInSeconds,
    FinishBehavior? finishBehavior,
    String? alarmSoundAssetPath,
    bool clearAlarmSoundAssetPath = false, // Special flag to nullify
    int? maxAlarmTimeInSeconds,
    bool clearMaxAlarmTimeInSeconds = false, // Special flag to nullify
    bool? vibrateOnFinish,
    bool? isRunning,
    bool? isCountingUp,
  }) {
    return TimerModel(
      id: id ?? this.id,
      headerText: headerText ?? this.headerText,
      headerTextColorValue: headerTextColorValue ?? this.headerTextColorValue,
      initialDurationInSeconds: initialDurationInSeconds ?? this.initialDurationInSeconds,
      remainingDurationInSeconds: remainingDurationInSeconds ?? this.remainingDurationInSeconds,
      finishBehavior: finishBehavior ?? this.finishBehavior,
      alarmSoundAssetPath: clearAlarmSoundAssetPath ? null : alarmSoundAssetPath ?? this.alarmSoundAssetPath,
      maxAlarmTimeInSeconds: clearMaxAlarmTimeInSeconds ? null : maxAlarmTimeInSeconds ?? this.maxAlarmTimeInSeconds,
      vibrateOnFinish: vibrateOnFinish ?? this.vibrateOnFinish,
      isRunning: isRunning ?? this.isRunning,
      isCountingUp: isCountingUp ?? this.isCountingUp,
    );
  }
}
