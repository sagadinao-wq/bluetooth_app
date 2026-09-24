import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class RecordingScreen extends StatefulWidget {
  final String exercise;
  final String weight;

  const RecordingScreen({
    super.key,
    required this.exercise,
    required this.weight,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _recording = false;
  int _elapsedMs = 0;
  int _samples = 0;
  Timer? _timer;

  void _start() {
    setState(() {
      _recording = true;
      _elapsedMs = 0;
      _samples = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _elapsedMs += 50;
        _samples += 5;
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _recording = false);
    context.push(
      '/workout/summary',
      extra: {
        'exercise': widget.exercise,
        'weight': widget.weight,
        'durationMs': _elapsedMs,
        'samples': _samples,
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_elapsedMs / 1000).toStringAsFixed(1);
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: "Запис",
                statusText: _recording ? "Йде запис" : "Готово",
                statusColor: _recording ? kRedColor : kSubColor,
              ),
              const SizedBox(height: 4),
              Text(
                "${widget.exercise} · ${widget.weight} кг",
                style: const TextStyle(color: kSubColor, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  kExerciseImages[widget.exercise] ?? 'assets/exercises/bench.jpg',
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Text(
                      "$seconds с",
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("$_samples відліків", style: const TextStyle(color: kSubColor, fontSize: 15)),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: _recording ? "Завершити підхід" : "Почати запис",
                color: _recording ? kRedColor : kCyanColor,
                onTap: _recording ? _stop : _start,
                icon: _recording ? Icons.stop_rounded : Icons.fiber_manual_record,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
