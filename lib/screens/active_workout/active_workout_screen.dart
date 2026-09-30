import 'package:flutter/material.dart';
import 'widgets/exercise_card.dart';
import 'widgets/bottom_workout_bar.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // Список вправ активного тренування
  final List<Map<String, dynamic>> _exercises = [
    {
      'title': 'Жим штанги лежачи',
      'sets': [
        ExerciseSetData(setNumber: 1, weight: '80', reps: '10', speed: '0.82 м/с', isCompleted: true),
        ExerciseSetData(setNumber: 2, weight: '80', reps: '8', isCompleted: false),
        ExerciseSetData(setNumber: 3, weight: '80', reps: '8', isCompleted: false),
      ],
    },
    {
      'title': 'Станова тяга',
      'sets': [
        ExerciseSetData(setNumber: 1, weight: '140', reps: '5', isCompleted: false),
        ExerciseSetData(setNumber: 2, weight: '140', reps: '5', isCompleted: false),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Верхній хідер з таймером та BLE
            _buildWorkoutHeader(),

            // 2. Список картка вправ
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ..._exercises.map((ex) {
                      return ExerciseCard(
                        exerciseName: ex['title'],
                        sets: ex['sets'],
                        onAddSet: () {
                          setState(() {
                            final sets = ex['sets'] as List<ExerciseSetData>;
                            final lastSet = sets.isNotEmpty ? sets.last : null;
                            sets.add(
                              ExerciseSetData(
                                setNumber: sets.length + 1,
                                weight: lastSet?.weight ?? '50',
                                reps: lastSet?.reps ?? '8',
                              ),
                            );
                          });
                        },
                        onRemoveSet: () {
                          setState(() {
                            final sets = ex['sets'] as List<ExerciseSetData>;
                            if (sets.length > 1) {
                              sets.removeLast();
                            }
                          });
                        },
                      );
                    }),

                    const SizedBox(height: 8),

                    // Кнопка додати нову вправу
                    InkWell(
                      onTap: _addNewExerciseModal,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: kDarkCardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: kPurpleAccent.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: kPurpleAccent, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Додати вправу",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80), // Відступ для нижнього док-бару
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. Плаваюча нижня шторка швидкого запуску
      bottomSheet: BottomWorkoutBar(
        activeExercise: _exercises.isNotEmpty ? _exercises.first['title'] : "Вправа",
        activeSet: 2,
        onStartPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Запис підходу розпочато через Bluetooth!"),
              backgroundColor: kPurpleAccent,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  // Верхній хідер тренування
  Widget _buildWorkoutHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Таймер тренування
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kDarkBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_rounded, color: kSubTextColor, size: 16),
                SizedBox(width: 6),
                Text(
                  "00:24:15",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),

          // Статус Bluetooth датчика
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPurpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPurpleAccent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bluetooth_connected_rounded, color: kPurpleAccent, size: 16),
                SizedBox(width: 6),
                Text("ESP32 OK", style: TextStyle(color: kPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Завершити тренування
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
          ),
        ],
      ),
    );
  }

  // Модальне вікно вибору вправи
  void _addNewExerciseModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDarkCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final exercisesList = ['Присідання зі штангою', 'Армійський жим', 'Підтягування', 'Жим гантелей під кутом'];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Оберіть вправу",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...exercisesList.map(
                (name) => ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.add_circle_outline_rounded, color: kPurpleAccent),
                  onTap: () {
                    setState(() {
                      _exercises.add({
                        'title': name,
                        'sets': [ExerciseSetData(setNumber: 1, weight: '60', reps: '10')],
                      });
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
