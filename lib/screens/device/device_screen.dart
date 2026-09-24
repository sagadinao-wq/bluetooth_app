import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _scanning = true;
  final List<String> _found = [];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _found.addAll(['Vector Pin — 7A:3F', 'Vector Pin — C1:09']);
        _scanning = false;
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
              const TopBar(title: "Прилад"),
              const SizedBox(height: 8),
              const Text(
                "Пошук та керування Vector VBT датчиком",
                style: TextStyle(color: kSubColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_scanning)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: kCyanColor, strokeWidth: 2.4),
                        SizedBox(height: 16),
                        Text("Сканування BLE пристроїв...", style: TextStyle(color: kSubColor)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _found.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => Material(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Підключено до ${_found[i]}"),
                              backgroundColor: kGreenColor,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_rounded, color: kCyanColor, size: 22),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _found[i],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: kSubColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
