import 'package:flutter/material.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class ExerciseSetData {
  int setNumber;
  String weight;
  String reps;
  String? speed;
  bool isCompleted;

  ExerciseSetData({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.speed,
    this.isCompleted = false,
  });
}

class ExerciseCard extends StatefulWidget {
  final String exerciseName;
  final List<ExerciseSetData> sets;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveSet;

  const ExerciseCard({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка вправи
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kPurpleAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPurpleAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: kPurpleAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${widget.sets.length} підходи(-ів)",
                      style: const TextStyle(color: kSubTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, color: kSubTextColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Заголовки стовпчиків
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text("SET", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Center(child: Text("КГ", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("ПОВТ", style: TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text("V_MEAN", style: TextStyle(color: kPurpleAccent, fontSize: 11, fontWeight: FontWeight.bold)))),
                SizedBox(width: 44),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Рядки підходів
          ...widget.sets.map((setData) => _buildSetRow(setData)),

          const SizedBox(height: 12),

          // Кнопки + та - для керування кількістю підходів
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onRemoveSet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: kDarkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: widget.onAddSet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: kDarkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(ExerciseSetData set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: set.isCompleted ? kPurpleAccent.withOpacity(0.1) : kDarkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: set.isCompleted ? kPurpleAccent.withOpacity(0.4) : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          // Номер підходу
          SizedBox(
            width: 30,
            child: Text(
              "${set.setNumber}",
              style: TextStyle(
                color: set.isCompleted ? kPurpleAccent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Вага
          Expanded(
            child: Center(
              child: Text(
                set.weight,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Повторення
          Expanded(
            child: Center(
              child: Text(
                set.reps,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Швидкість V_mean з приладу
          Expanded(
            child: Center(
              child: Text(
                set.speed ?? "—",
                style: const TextStyle(
                  color: kPurpleAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Кнопка виконання підходу
          GestureDetector(
            onTap: () {
              setState(() {
                set.isCompleted = !set.isCompleted;
                if (set.isCompleted && set.speed == null) {
                  set.speed = "0.74 м/с"; // Тимчасовий муляж швидкості від датчика
                }
              });
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: set.isCompleted ? const Color(0xFF10B981) : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                set.isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
