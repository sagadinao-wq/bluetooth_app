import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/workout_service.dart';
import '../../services/ble_service.dart';
import 'widgets/hold_button.dart';
import 'set_preparation_screen.dart';

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
  final BleService _bleService = BleService();

  @override
  void initState() {
    super.initState();
    if (!_workoutService.isWorkoutActive) {
      _workoutService.startWorkout();
    }
    _workoutService.addListener(_onServiceUpdate);
    _bleService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _workoutService.removeListener(_onServiceUpdate);
    _bleService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  // --- ЛОГІКА ДІЙ ---

  void _startSetFlow(String exerciseName, WorkoutSetData set) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetPreparationScreen(
          exerciseName: exerciseName,
          initialWeight: set.weight,
          initialReps: set.reps,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        set.weight = result['weight'] ?? set.weight;
        set.reps = result['reps'] ?? 'AUTO';
        set.isWarmup = result['isWarmup'] ?? false;
        set.isCompleted = true;
        set.speed = null; // Очищуємо швидкість до отримання даних з датчика
      });
    }
  }

  void _openExerciseAnalysis(String exerciseName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseAnalysisFullScreen(exerciseName: exerciseName),
      ),
    );
  }

  void _attemptFinishWorkout() async {
    final completedSets = _calculateTotalCompletedSets();

    if (completedSets == 0) {
      // Захист від порожнього тренування
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent.withOpacity(0.95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Виконайте хоча б один підхід, щоб завершити тренування!",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Якщо все ок - зберігаємо і виходимо
    await _workoutService.finishWorkout(shouldSave: true);
    if (mounted) context.go('/home');
  }

  void _cancelWorkout() async {
    await _workoutService.finishWorkout(shouldSave: false);
    if (mounted) context.go('/home');
  }

  // --- ПІДРАХУНКИ ---

  int _calculateTotalCompletedSets() {
    int total = 0;
    for (var ex in _workoutService.exercises) {
      total += ex.sets.where((s) => s.isCompleted).length;
    }
    return total;
  }

  int _calculateTotalVolume() {
    int total = 0;
    for (var ex in _workoutService.exercises) {
      for (var set in ex.sets) {
        if (set.isCompleted) {
          final w = int.tryParse(set.weight) ?? 0;
          final r = int.tryParse(set.reps) ?? 0;
          total += w * r;
        }
      }
    }
    return total;
  }

  // --- ВІДЖЕТИ ---

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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
    final hasCompletedSets = _calculateTotalCompletedSets() > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          ),
          
          // Статус датчика
          GestureDetector(
            onTap: () => context.go('/device'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kDarkCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _bleService.isConnected
                      ? const Color(0xFF10B981).withOpacity(0.4)
                      : Colors.redAccent.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _bleService.isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _bleService.isConnected ? "Підключено" : "Датчик відключено",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Меню завершення
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 28),
            color: kDarkCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'save') _attemptFinishWorkout();
              if (value == 'cancel') _cancelWorkout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(
                      Icons.stop_circle_outlined,
                      color: hasCompletedSets ? Colors.redAccent : Colors.white38,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Завершити тренування",
                      style: TextStyle(
                        color: hasCompletedSets ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.white54),
                    SizedBox(width: 12),
                    Text("Скасувати (без збереження)", style: TextStyle(color: Colors.white54)),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem("Тривалість", _workoutService.formattedTime, isTimer: true),
          _statItem("Обсяг", "${_calculateTotalVolume()} kg"),
          _statItem("Підходи", "${_calculateTotalCompletedSets()}"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, {bool isTimer = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kSubTextColor, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: isTimer ? kPurpleAccent : Colors.white,
            fontSize: 18,
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
          Icon(Icons.fitness_center_rounded, color: kSubTextColor.withOpacity(0.3), size: 80),
          const SizedBox(height: 16),
          const Text("Тренування порожнє", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Додайте першу вправу, щоб почати запис підходів та відстежувати обсяг.",
            textAlign: TextAlign.center,
            style: TextStyle(color: kSubTextColor, fontSize: 14),
          ),
          const Spacer(),
          _buildAddExerciseButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _showExerciseSelectionModal(),
        icon: const Icon(Icons.add_circle_outline_rounded, color: kPurpleAccent),
        label: const Text("Додати вправу", style: TextStyle(color: kPurpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: kPurpleAccent.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleExerciseCard(int index) {
    final exercise = _workoutService.exercises[index];
    final isExpanded = exercise.isExpanded;

    return Dismissible(
      key: ValueKey("exercise_${exercise.name}_$index"),
      direction: isExpanded ? DismissDirection.none : DismissDirection.horizontal,
      background: _buildSwipeBackground(Icons.swap_horiz_rounded, Colors.blueAccent, Alignment.centerLeft, "Замінити"),
      secondaryBackground: _buildSwipeBackground(Icons.delete_outline_rounded, Colors.redAccent, Alignment.centerRight, "Видалити"),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showExerciseSelectionModal(replaceIndex: index);
          return false;
        } else {
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _workoutService.removeExercise(index);
        }
      },
      child: _buildExerciseCard(index),
    );
  }

  Widget _buildSwipeBackground(IconData icon, Color color, Alignment alignment, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      alignment: alignment,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(int index) {
    final exercise = _workoutService.exercises[index];
    final hasCompletedSets = exercise.sets.any((s) => s.isCompleted);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _workoutService.toggleExerciseExpanded(index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPurpleAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: kPurpleAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasCompletedSets && exercise.isExpanded) ...[
                    GestureDetector(
                      onTap: () => _openExerciseAnalysis(exercise.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPurpleAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.show_chart_rounded, color: kPurpleAccent, size: 14),
                            SizedBox(width: 4),
                            Text("Аналіз", style: TextStyle(color: kPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    exercise.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          
          if (exercise.isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  if (exercise.sets.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text("SET", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(child: Center(child: Text("KG", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold)))),
                          Expanded(child: Center(child: Text("REPS", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold)))),
                          SizedBox(width: 48),
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
                          fillColor: kDarkCardBg,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: set.isCompleted ? const Color(0xFF24D086).withOpacity(0.1) : kDarkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: set.isCompleted ? const Color(0xFF24D086).withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                set.isWarmup ? "W" : "${set.setNumber}",
                style: TextStyle(
                  color: set.isWarmup ? Colors.amber : (set.isCompleted ? const Color(0xFF24D086) : Colors.white),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: Text(
                set.weight.isEmpty ? "-" : set.weight,
                style: TextStyle(color: set.isCompleted ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: Text(
                set.reps.isEmpty ? "-" : set.reps,
                style: TextStyle(color: set.isCompleted ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          
          GestureDetector(
            onTap: () {
              if (set.isCompleted) {
                setState(() => set.isCompleted = false);
              } else {
                _startSetFlow(exerciseName, set);
              }
            },
            child: Container(
              width: 48,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: set.isCompleted ? const Color(0xFF24D086) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                set.isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: set.isCompleted ? Colors.white : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseSelectionModal({int? replaceIndex}) {
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
              Text(
                replaceIndex != null ? "Замінити на:" : "Оберіть вправу", 
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              ...availableExercises.map((name) => ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                trailing: Icon(
                  replaceIndex != null ? Icons.swap_horiz_rounded : Icons.add_circle_outline_rounded, 
                  color: replaceIndex != null ? Colors.blueAccent : kPurpleAccent
                ),
                onTap: () {
                  if (replaceIndex != null) {
                    _workoutService.removeExercise(replaceIndex);
                    _workoutService.addExercise(name);
                  } else {
                    _workoutService.addExercise(name);
                  }
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

class ExerciseAnalysisFullScreen extends StatelessWidget {
  final String exerciseName;

  const ExerciseAnalysisFullScreen({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF120C24), kDarkBg, Color(0xFF16161E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Аналіз вправи", style: TextStyle(color: kSubTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(exerciseName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kDarkCardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: kPurpleAccent.withOpacity(0.4), width: 2),
                        ),
                        child: const Text("📈", style: TextStyle(fontSize: 50)),
                      ),
                      const SizedBox(height: 24),
                      const Text("Детальна аналітика вправи", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text(
                        "Тут відображатимуться графіки швидкості (V_mean / V_peak), втрата швидкості (Velocity Loss) та динаміка втоми за підходами.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kSubTextColor, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
