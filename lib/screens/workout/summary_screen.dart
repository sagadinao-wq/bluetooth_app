import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SummaryScreen extends StatelessWidget {
  final String exercise;
  final String weight;
  final int durationMs;
  final int samples;

  const SummaryScreen({
    super.key,
    required this.exercise,
    required this.weight,
    required this.durationMs,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = (durationMs / 1000).toStringAsFixed(1);
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Підхід завершено",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => context.go('/workout'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _row("Вправа", exercise),
                    const Divider(height: 1, color: kDividerColor, indent: 20, endIndent: 20),
                    _row("Вага", "$weight кг"),
                    const Divider(height: 1, color: kDividerColor, indent: 20, endIndent: 20),
                    _row("Тривалість", "$seconds с"),
                    const Divider(height: 1, color: kDividerColor, indent: 20, endIndent: 20),
                    _row("Відліків записано", "$samples"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Аналіз повторів і швидкості порахуємо пізніше — зараз зберігаються тільки сирі дані з пристрою.",
                style: TextStyle(color: kSubColor, fontSize: 13, height: 1.4),
              ),
              const Spacer(),
              PrimaryButton(
                label: "Завантажити CSV",
                color: kCyanColor,
                icon: Icons.download_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Файл збережено"), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kSubColor, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
