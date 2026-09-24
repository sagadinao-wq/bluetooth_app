import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CalibrationScreen extends StatefulWidget {
  final String exercise;
  final String weight;

  const CalibrationScreen({
    super.key,
    required this.exercise,
    required this.weight,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _calibrating = false;
  bool _done = false;

  void _calibrate() {
    setState(() => _calibrating = true);
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _calibrating = false;
        _done = true;
      });
    });
  }

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
              const TopBar(title: "Калібрування"),
              const SizedBox(height: 4),
              Text(
                "${widget.exercise} · ${widget.weight} кг",
                style: const TextStyle(color: kSubColor, fontSize: 13),
              ),
              const Spacer(),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _done
                      ? Container(
                          key: const ValueKey('done'),
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: kGreenColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.black, size: 56),
                        )
                      : Container(
                          key: const ValueKey('idle'),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: kCardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: kDividerColor, width: 2),
                          ),
                          child: _calibrating
                              ? const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: CircularProgressIndicator(color: kCyanColor, strokeWidth: 2.4),
                                )
                              : const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 44),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _done
                    ? "Калібровка завершена"
                    : "Поставте штангу на підлогу або бокс і не рухайте нею",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _done ? kGreenColor : const Color(0xFFD1D1D6),
                  fontSize: 16,
                  fontWeight: _done ? FontWeight.w700 : FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: _done ? "Почати підхід" : (_calibrating ? "Калібрування..." : "Калібрувати"),
                color: _done ? kGreenColor : kCyanColor,
                onTap: _calibrating
                    ? null
                    : (_done
                        ? () => context.push(
                              '/workout/record',
                              extra: {
                                'exercise': widget.exercise,
                                'weight': widget.weight,
                              },
                            )
                        : _calibrate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
