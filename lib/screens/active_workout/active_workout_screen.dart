import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/workout_service.dart';
import 'widgets/hold_button.dart';
import 'set_preparation_screen.dart';
import 'analysis/set_analysis_screen.dart';

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
  final WorkoutService _workoutService = WorkoutService();

  @override
  void initState() {
    super.initState();
    if (!_workoutService.isWorkoutActive) {
      _workoutService.startWorkout();
    }
    _workoutService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _workoutService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _startSetFlow(String exerciseName, WorkoutSetData set) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetPreparationScreen(
          exerciseName: exerciseName,
          initialWeight: set.weight,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        set.weight = result['weight'] ?? set.weight;
        set.reps = result['reps'] ?? '8';
        set.isWarmup = result['isWarmup'] ?? false;
        set.isCompleted = true;
        set.speed = "0.78 м/с";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            _buildWorkoutStatsHeader(),
            Expanded(
              child: _workoutService.exercises.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _workoutService.exercises.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _workoutService.exercises.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                            child: _buildAddExerciseButton(),
                          );
                        }
                        return _buildDismissibleExerciseCard(index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
            color: kDarkCardBg,
            onSelected: (value) {
              if (value == 'save' || value == 'cancel') {
                _workoutService.finishWorkout();
                context.go('/home');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent),
                    SizedBox(width: 8),
                    Text("Зберегти тренування", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text("Скасувати тренування", style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStatsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Тривалість", _workoutService.formattedTime, isTimer: true),
          _statItem("Обсяг", "0 kg"),
          _statItem("Підходи", "${_calculateTotalSets()}"),
        ],
      ),
    );
  }

  int _calculateTotalSets() {
    int total = 0;
    for (var ex in _workoutService.exercises) {
      total += ex.sets.length;
    }
    return total;
  }

  Widget _statItem(String label, String value, {bool isTimer = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kSubTextColor, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isTimer ? kPurpleAccent : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            Icons.fitness_center_rounded,
            color: kSubTextColor.withOpacity(0.6),
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            "Немає доданих вправ",
            style: TextStyle(color: kSubTextColor, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          _buildAddExerciseButton(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showExerciseSelectionModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          "Додати вправу",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDismissibleExerciseCard(int index) {
    final exercise = _workoutService.exercises[index];
    final isExpanded = exercise.isExpanded;

    return Dismissible(
      key: ValueKey("exercise_${exercise.name}_$index"),
      direction: isExpanded ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _workoutService.removeExercise(index);
      },
      child: _buildExerciseCard(index),
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _workoutService.exercises[index];
    final completedSets = exercise.sets.where((s) => s.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _workoutService.toggleExerciseExpanded(index),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPurpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: kPurpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("$completedSets/${exercise.sets.length} виконано", style: const TextStyle(color: kSubTextColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                    exercise.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: kSubTextColor,
                  ),
                ],
              ),
            ),
          ),

          if (exercise.isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (exercise.sets.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text("SET", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(child: Center(child: Text("KG", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold)))),
                          Expanded(child: Center(child: Text("REPS", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold)))),
                          SizedBox(width: 80),
                        ],
                      ),
                    ),

                  ...exercise.sets.map((set) => _buildSetRow(exercise.name, set)),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: HoldButton(
                          icon: Icons.remove_rounded,
                          fillColor: Colors.redAccent.withOpacity(0.8),
                          onTrigger: () => _workoutService.removeSet(index),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: HoldButton(
                          icon: Icons.add_rounded,
                          fillColor: Colors.greenAccent.withOpacity(0.8),
                          onTrigger: () => _workoutService.addSet(index),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetRow(String exerciseName, WorkoutSetData set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: set.isCompleted ? kPurpleAccent.withOpacity(0.12) : kDarkBg,
        borderRadius: BorderRadius.circular(12),
        border: set.isCompleted ? Border.all(color: kPurpleAccent.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          // Номер підходу
          SizedBox(
            width: 30,
            child: Text(
              "${set.setNumber}",
              style: TextStyle(color: set.isWarmup ? Colors.orangeAccent : Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          // Поле Ваги (прочерк або значення)
          Expanded(
            child: Center(
              child: Text(
                set.weight,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Поле Повторів (прочерк або значення)
          Expanded(
            child: Center(
              child: Text(
                set.reps,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Права частина: Текст "Розпочати >" АБО Дії виконаного підходу
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!set.isCompleted) ...[
                // Кнопка "Розпочати >" з запускним потоком
                GestureDetector(
                  onTap: () => _startSetFlow(exerciseName, set),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kDarkCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: kSubTextColor, size: 16),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Кнопка аналітики 📊
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SetAnalysisScreen(
                          exerciseName: exerciseName,
                          setNumber: set.setNumber,
                          weight: set.weight,
                          reps: set.reps,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: kPurpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kPurpleAccent.withOpacity(0.4)),
                    ),
                    child: const Text("📊", style: TextStyle(fontSize: 13)),
                  ),
                ),

                // Зелена галочка виконання
                GestureDetector(
                  onTap: () {
                    setState(() {
                      set.isCompleted = false;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showExerciseSelectionModal() {
    final availableExercises = [
      'Жим штанги лежачи',
      'Присідання зі штангою',
      'Станова тяга',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: kDarkCardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Оберіть вправу", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...availableExercises.map((name) => ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.add_circle_outline_rounded, color: kPurpleAccent),
                onTap: () {
                  _workoutService.addExercise(name);
                  Navigator.of(context).pop();
                },
              )),
            ],
          ),
        );
      },
    );
  }
}
