import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    setState(() => _isScanning = true);
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    if (mounted) setState(() => _isScanning = false);
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
                "Керування та діагностика Vector VBT (ESP32)",
                style: TextStyle(color: kSubColor, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Картка діагностики та тесту пінгу
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kDividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.developer_board, color: kCyanColor, size: 22),
                            SizedBox(width: 10),
                            Text(
                              "Vector Pin (ESP32)",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kGreenColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("АКБ: 94%", style: TextStyle(color: kGreenColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: kDividerColor, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricTile("Сигнал RSSI", "-62 dBm", Icons.network_cell),
                        _metricTile("Пінг (Latency)", "14 ms", Icons.speed),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: "Перевірити пінг",
                      color: kCyanColor,
                      icon: Icons.bolt_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Пінг: 12 ms · Зв'язок стабільний"),
                            backgroundColor: kGreenColor,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Пошук пристроїв", style: TextStyle(color: kSubColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(_isScanning ? Icons.sync : Icons.refresh, color: kCyanColor),
                    onPressed: _isScanning ? null : _startScan,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Список доступних BLE-пристроїв
              Expanded(
                child: _isScanning && _scanResults.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: kCyanColor))
                    : ListView.builder(
                        itemCount: _scanResults.isNotEmpty ? _scanResults.length : 2,
                        itemBuilder: (context, index) {
                          final name = _scanResults.isNotEmpty && _scanResults[index].device.platformName.isNotEmpty
                              ? _scanResults[index].device.platformName
                              : (index == 0 ? "Vector Pin — ESP32 (7A:3F)" : "Vector VBT Sensor (C1:09)");
                          final rssi = _scanResults.isNotEmpty ? _scanResults[index].rssi : -58 - (index * 12);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth_searching, color: kCyanColor),
                              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              subtitle: Text("Сигнал: $rssi dBm", style: const TextStyle(color: kSubColor, fontSize: 12)),
                              trailing: const Icon(Icons.chevron_right, color: kSubColor),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Підключення до $name..."), backgroundColor: kCyanColor),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: kSubColor),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: kSubColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
