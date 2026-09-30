import 'dart:async';
import 'package:flutter/material.dart';

class WorkoutSetData {
  int setNumber;
  String weight;
  String reps;
  String? speed;
  bool isCompleted;
  bool isWarmup;

  WorkoutSetData({
    required this.setNumber,
    this.weight = '0',
    this.reps = '0',
    this.speed,
    this.isCompleted = false,
    this.isWarmup = false,
  });
}

class ActiveExercise {
  final String name;
  bool isExpanded;
  List<WorkoutSetData> sets;

  ActiveExercise({
    required this.name,
    this.isExpanded = true,
    List<WorkoutSetData>? sets,
  }) : sets = sets ?? [];
}

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  bool _isWorkoutActive = false;
  bool get isWorkoutActive => _isWorkoutActive;

  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  List<ActiveExercise> exercises = [];

  void startWorkout() {
    if (_isWorkoutActive) return;
    _isWorkoutActive = true;
    _startTime = DateTime.now();
    _elapsedSeconds = 0;
    exercises.clear();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void addExercise(String name) {
    exercises.add(ActiveExercise(name: name));
    notifyListeners();
  }

  void toggleExerciseExpanded(int index) {
    if (index >= 0 && index < exercises.length) {
      exercises[index].isExpanded = !exercises[index].isExpanded;
      notifyListeners();
    }
  }

  void addSet(int exerciseIndex) {
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      final ex = exercises[exerciseIndex];
      final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
      ex.sets.add(
        WorkoutSetData(
          setNumber: ex.sets.length + 1,
          weight: lastSet?.weight ?? '60',
          reps: lastSet?.reps ?? '8',
        ),
      );
      notifyListeners();
    }
  }

  void removeSet(int exerciseIndex) {
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      final ex = exercises[exerciseIndex];
      if (ex.sets.isNotEmpty) {
        ex.sets.removeLast();
        notifyListeners();
      }
    }
  }

  void finishWorkout() {
    _isWorkoutActive = false;
    _timer?.cancel();
    _elapsedSeconds = 0;
    exercises.clear();
    notifyListeners();
  }

  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
