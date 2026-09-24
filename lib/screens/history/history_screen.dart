import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: "Історія"),
              const SizedBox(height: 8),
              const Text("Минулі підходи та сесії", style: TextStyle(color: kSubColor, fontSize: 14)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _historyTile("Жим лежачи", "80 кг · 5 повторів", "Сьогодні, 18:30"),
                    const SizedBox(height: 10),
                    _historyTile("Присідання", "110 кг · 3 повтори", "Вчора, 19:15"),
                    const SizedBox(height: 10),
                    _historyTile("Станова тяга", "140 кг · 1 повтор", "22 Вер, 17:00"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTile(String exercise, String details, String date) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(details, style: const TextStyle(color: kCyanColor, fontSize: 14)),
            ],
          ),
          Text(date, style: const TextStyle(color: kSubColor, fontSize: 12)),
        ],
      ),
    );
  }
}
