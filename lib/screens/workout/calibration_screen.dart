import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../services/ble_service.dart';

class CalibrationScreen extends StatelessWidget {
  final String exercise;
  final String setType;
  final String weight;

  const CalibrationScreen({
    super.key,
    required this.exercise,
    required this.setType,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Text("$exercise · $weight кг", style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.phonelink_setup_rounded, color: kCyanColor, size: 80),
              const SizedBox(height: 24),
              const Text(
                "Закріпіть сенсор на штанзі",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Переконайтеся, що штанга знаходиться в нерухомому положенні у вихідній точці перед початком підходу.",
                style: TextStyle(color: kSubColor, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyanColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // Автоматичне калібрування ZUPT
                    BleService().sendBleCommand("TARE");
                    BleService().sendBleCommand("START");

                    context.go('/workout/record', extra: {
                      'exercise': exercise,
                      'setType': setType,
                      'weight': weight,
                    });
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text("Автоматичне калібрування та старт", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
