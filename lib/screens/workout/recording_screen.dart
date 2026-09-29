import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../services/ble_service.dart';

class RecordingScreen extends StatefulWidget {
  final String exercise;
  final String setType;
  final String weight;

  const RecordingScreen({
    super.key,
    required this.exercise,
    required this.setType,
    required this.weight,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final BleService _ble = BleService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _ble.addListener(_checkBleState);
  }

  @override
  void dispose() {
    _animController.dispose();
    _ble.removeListener(_checkBleState);
    super.dispose();
  }

  // Якщо підхід зупинено з датчика кнопкою 1 або авто-стопом
  void _checkBleState() {
    if (!_ble.isRecording && mounted) {
      _finishRecording();
    }
  }

  void _finishRecording() {
    _ble.sendBleCommand("STOP");
    context.go('/workout/summary', extra: {
      'exercise': widget.exercise,
      'setType': widget.setType,
      'weight': widget.weight,
      'repCount': _ble.repCount,
      'bestV': _ble.lastMeanV,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${widget.exercise} · ${widget.weight} кг",
                style: const TextStyle(color: kSubColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),

              // Анімований пульсуючий круг
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  double scale = 1.0 + (_animController.value * 0.25);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kCyanColor.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: kCyanColor.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Нижня кнопка завершення підходу
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRedColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _finishRecording,
                  icon: const Icon(Icons.stop_rounded, size: 28),
                  label: const Text("Завершити підхід", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
