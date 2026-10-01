import 'dart:async';
import 'package:flutter/material.dart';
import 'database_service.dart';

class WorkoutSetData {
  int setNumber;
  String weight;
  String reps;
  String? speed;
  bool isCompleted;
  bool isWarmup;

  WorkoutSetData({
    required this.setNumber,
    this.weight = '—',
    this.reps = '—',
    this.speed,
    this.isCompleted = false,
    this.isWarmup = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'speed': speed ?? '—',
      'isCompleted': isCompleted,
      'isWarmup': isWarmup,
    };
  }
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }
}

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final DatabaseService _dbService = DatabaseService();

  bool _isWorkoutActive = false;
  bool get isWorkoutActive => _isWorkoutActive;

  Timer? _timer;
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  List<ActiveExercise> exercises = [];

  void startWorkout() {
    if (_isWorkoutActive) return;
    _isWorkoutActive = true;
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
    if (!_isWorkoutActive) {
      startWorkout();
    }
    exercises.add(ActiveExercise(name: name));
    notifyListeners();
  }

  void removeExercise(int index) {
    if (index >= 0 && index < exercises.length) {
      exercises.removeAt(index);
      notifyListeners();
    }
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
      
      String previousWeight = '—';
      String previousReps = '—';

      if (ex.sets.isNotEmpty) {
        final lastSet = ex.sets.last;
        previousWeight = lastSet.weight;
        previousReps = lastSet.reps;
      }

      ex.sets.add(
        WorkoutSetData(
          setNumber: ex.sets.length + 1,
          weight: previousWeight,
          reps: previousReps,
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

  // Завершення тренування з можливістю збереження у Firebase Cloud Firestore
  Future<void> finishWorkout({bool shouldSave = true}) async {
    if (shouldSave && exercises.isNotEmpty) {
      final workoutData = {
        'durationSeconds': _elapsedSeconds,
        'formattedTime': formattedTime,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

      await _dbService.saveWorkout(workoutData);
    }

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
