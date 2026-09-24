import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
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
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  String _connectedDeviceName = "Не підключено";
  int _rssi = 0;
  int _pingMs = 0;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  // Запуск реального сканування BLE пристроїв навколо
  void _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    // Підписуємося на реальний потік знайдених BLE пристроїв
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка сканування: $e"), backgroundColor: kRedColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // Підключення до реального пристрою
  Future<void> _connectToDevice(BluetoothDevice device) async {
    final name = device.platformName.isNotEmpty ? device.platformName : device.remoteId.str;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Підключення до $name..."), backgroundColor: kCyanColor),
    );

    try {
      await device.connect(timeout: const Duration(seconds: 8));
      final rssi = await device.readRssi();

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _connectedDeviceName = name;
        _rssi = rssi;
        _pingMs = 14; // Базовий ping після встановлення з'єднання
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Успішно підключено до $name"), backgroundColor: kGreenColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Не вдалося підключитися: $e"), backgroundColor: kRedColor),
        );
      }
    }
  }

  // Відключення від пристрою
  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }

    setState(() {
      _connectedDevice = null;
      _isConnected = false;
      _connectedDeviceName = "Не підключено";
      _rssi = 0;
      _pingMs = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пристрій відключено"), backgroundColor: kRedColor),
      );
    }
  }

  // Замір реального пінгу (Latency test через RSSI read)
  Future<void> _measurePing() async {
    if (!_isConnected || _connectedDevice == null) return;

    final stopwatch = Stopwatch()..start();
    try {
      final newRssi = await _connectedDevice!.readRssi();
      stopwatch.stop();

      setState(() {
        _rssi = newRssi;
        _pingMs = stopwatch.elapsedMilliseconds;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Пінг: $_pingMs ms · Сигнал: $_rssi dBm"),
            backgroundColor: kGreenColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Помилка заміру пінгу"), backgroundColor: kRedColor),
        );
      }
    }
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
                "Керування та діагностика Vector VBT",
                style: TextStyle(color: kSubColor, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Картка підключеного пристрою
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _isConnected ? kCyanColor : kDividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.developer_board,
                                color: _isConnected ? kCyanColor : kSubColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _connectedDeviceName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_isConnected ? kGreenColor : kRedColor).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isConnected ? "Підключено" : "Відключено",
                            style: TextStyle(
                              color: _isConnected ? kGreenColor : kRedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: kDividerColor, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricTile("Сигнал RSSI", _isConnected ? "$_rssi dBm" : "—", Icons.network_cell),
                        _metricTile("Пінг (Latency)", _isConnected ? "$_pingMs ms" : "—", Icons.speed),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (_isConnected) ...[
                          Expanded(
                            child: PrimaryButton(
                              label: "Замір пінгу",
                              color: kCyanColor,
                              icon: Icons.bolt_rounded,
                              onTap: _measurePing,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: "Відключити",
                              color: kRedColor,
                              icon: Icons.power_settings_new_rounded,
                              onTap: _disconnectDevice,
                            ),
                          ),
                        ] else
                          Expanded(
                            child: PrimaryButton(
                              label: "Сканувати пристрої",
                              color: kCyanColor,
                              icon: Icons.search_rounded,
                              onTap: _isScanning ? null : _startScan,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Знайдені Bluetooth пристрої", style: TextStyle(color: kSubColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(_isScanning ? Icons.sync : Icons.refresh, color: kCyanColor),
                    onPressed: _isScanning ? null : _startScan,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Реальний список усіх знайдених BLE-пристроїв
              Expanded(
                child: _isScanning && _scanResults.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: kCyanColor),
                            SizedBox(height: 12),
                            Text("Шукаємо реальні Bluetooth пристрої...", style: TextStyle(color: kSubColor)),
                          ],
                        ),
                      )
                    : _scanResults.isEmpty
                        ? const Center(
                            child: Text(
                              "Пристроїв не знайдено.\nПеревірте, чи увімкнено Bluetooth та GPS на телефоні.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kSubColor),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _scanResults.length,
                            itemBuilder: (context, index) {
                              final result = _scanResults[index];
                              final device = result.device;
                              final name = device.platformName.isNotEmpty ? device.platformName : "Unknown Device";
                              final mac = device.remoteId.str;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: kCardColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.bluetooth, color: kCyanColor),
                                  title: Text(
                                    name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text("$mac  ·  ${result.rssi} dBm", style: const TextStyle(color: kSubColor, fontSize: 12)),
                                  trailing: TextButton(
                                    onPressed: () => _connectToDevice(device),
                                    child: const Text("Підключити", style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
                                  ),
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
