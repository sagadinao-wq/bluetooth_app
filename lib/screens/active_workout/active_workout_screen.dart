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
        set.speed = null;
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
          GestureDetector(
            onTap: () => context.go('/device'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kDarkCardBg,
                borderRadius: BorderRadius.circular(16),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
            color: kDarkCardBg,
            onSelected: (value) async {
              if (value == 'save') {
                await _workoutService.finishWorkout(shouldSave: true);
                if (context.mounted) context.go('/home');
              } else if (value == 'cancel') {
                await _workoutService.finishWorkout(shouldSave: false);
                if (context.mounted) context.go('/home');
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
          _statItem("Обсяг", "${_calculateTotalVolume()} kg"),
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
    final bool hasCompletedSets = completedSets > 0;

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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasCompletedSets) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openExerciseAnalysis(exercise.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kPurpleAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kPurpleAccent.withOpacity(0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("📈", style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text("Аналіз", style: TextStyle(color: kPurpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                          SizedBox(width: 50),
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
          SizedBox(
            width: 30,
            child: Text(
              "${set.setNumber}",
              style: TextStyle(color: set.isWarmup ? Colors.orangeAccent : Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                set.weight,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                set.reps,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!set.isCompleted) ...[
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

// Новий повноекранний режим аналізу з темним градієнтом та червоним круглим хрестиком
class ExerciseAnalysisFullScreen extends StatelessWidget {
  final String exerciseName;

  const ExerciseAnalysisFullScreen({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF120C24),
              kDarkBg,
              Color(0xFF16161E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Шапка: Назва вправи та виділена червона кнопка закриття
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Аналіз вправи",
                          style: TextStyle(color: kSubTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exerciseName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Повноекранний скрол під майбутній обсяг аналітичних даних
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
                      const Text(
                        "Детальна аналітика вправи",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Тут відображатимуться графіки швидкості (V_mean / V_peak), втрата швидкості (Velocity Loss) та динаміка втоми за підходами.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kSubTextColor, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 300), // Запас для вертикального скролу
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
