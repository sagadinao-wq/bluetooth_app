import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';

class SummaryScreen extends StatelessWidget {
  final String exercise;
  final String setType;
  final String weight;
  final int repCount;
  final double bestV;

  const SummaryScreen({
    super.key,
    required this.exercise,
    required this.setType,
    required this.weight,
    required this.repCount,
    required this.bestV,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text("Підсумок підходу", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    Text(exercise, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("$setType · $weight кг", style: const TextStyle(color: kSubColor, fontSize: 14)),
                    const Divider(color: kDividerColor, height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryTile("Повторень", "$repCount"),
                        _summaryTile("Краща V_mean", "${bestV.toStringAsFixed(2)} м/с"),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyanColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    context.go('/workout');
                  },
                  child: const Text("Готово", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kSubColor, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: kCyanColor, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
