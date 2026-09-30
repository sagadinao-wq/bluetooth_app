import 'package:flutter/material.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class SetAnalysisScreen extends StatelessWidget {
  final String exerciseName;
  final int setNumber;
  final String weight;
  final String reps;

  const SetAnalysisScreen({
    super.key,
    required this.exerciseName,
    required this.setNumber,
    required this.weight,
    required this.reps,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Аналіз підходу #$setNumber ($weight kg × $reps)",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF231A3D),
                        kDarkCardBg,
                        Color(0xFF110E1B),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: kPurpleAccent.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: kPurpleAccent.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kPurpleAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: kPurpleAccent.withOpacity(0.6), width: 2),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: kPurpleAccent,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Повний аналіз цього підходу\nбуде скоро",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          "Тут буде відображатися графік швидкості кожного повтору, амплітуда руху (ROM), пікова потужність та індекси втоми.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kSubTextColor, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
