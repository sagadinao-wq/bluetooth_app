import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';

class ExerciseSelectScreen extends StatelessWidget {
  const ExerciseSelectScreen({super.key});

  final List<Map<String, dynamic>> exercises = const [
    {'title': 'Присідання зі штангою', 'icon': Icons.fitness_center},
    {'title': 'Жим лежачи', 'icon': Icons.space_dashboard_rounded},
    {'title': 'Станова тяга', 'icon': Icons.vertical_align_top_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text("Оберіть вправу", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kBgColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView.separated(
            itemCount: exercises.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = exercises[index];
              return InkWell(
                onTap: () {
                  context.go('/workout/setup', extra: {'exercise': item['title']});
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData, color: kCyanColor, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: kSubColor, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
