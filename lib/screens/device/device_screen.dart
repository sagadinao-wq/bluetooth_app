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
  bool _hideUnknown = true; // За замовчуванням ховаємо пристрої без імені
  List<ScanResult> _scanResults = [];
  List<BluetoothDevice> _systemDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  String _connectedDeviceName = "Не підключено";
  int _rssi = 0;
  int _pingMs = 0;

  @override
  void initState() {
    super.initState();
    _fetchSystemDevices();
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  // Отримання підключених/спарених у системі Android пристроїв (годинники, навушники)
  Future<void> _fetchSystemDevices() async {
    try {
      final bonded = await FlutterBluePlus.systemDevices;
      if (mounted) {
        setState(() {
          _systemDevices = bonded;
        });
      }
    } catch (_) {}
  }

  // Запуск BLE сканування
  void _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    await _fetchSystemDevices();

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
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

  Future<void> _connectToDevice(BluetoothDevice device, String name) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Підключення до $name..."), backgroundColor: kCyanColor),
    );

    try {
      await device.connect(timeout: const Duration(seconds: 8));
      int rssi = -60;
      try {
        rssi = await device.readRssi();
      } catch (_) {}

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _connectedDeviceName = name;
        _rssi = rssi;
        _pingMs = 12;
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Помилка заміру пінгу"), backgroundColor: kRedColor),
        );
      }
    }
  }

  String _getDeviceName(ScanResult res) {
    if (res.device.platformName.isNotEmpty) return res.device.platformName;
    if (res.advertisementData.advName.isNotEmpty) return res.advertisementData.advName;
    if (res.advertisementData.localName.isNotEmpty) return res.advertisementData.localName;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    // Фільтрація невідомих беконів
    final filteredResults = _scanResults.where((r) {
      final name = _getDeviceName(r);
      if (_hideUnknown && name.isEmpty) return false;
      return true;
    }).toList();

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

              // Панель підключеного пристрою
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

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bluetooth пристрої", style: TextStyle(color: kSubColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      FilterChip(
                        label: Text(_hideUnknown ? "Тільки з ім'ям" : "Усі пристрої", style: const TextStyle(fontSize: 11, color: Colors.white)),
                        selected: _hideUnknown,
                        onSelected: (val) => setState(() => _hideUnknown = val),
                        selectedColor: kCyanColor.withOpacity(0.3),
                        backgroundColor: kCardColor,
                        checkmarkColor: kCyanColor,
                      ),
                      IconButton(
                        icon: Icon(_isScanning ? Icons.sync : Icons.refresh, color: kCyanColor),
                        onPressed: _isScanning ? null : _startScan,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  children: [
                    // Розділ спарених у системі пристроїв (годинники, навушники)
                    if (_systemDevices.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, top: 4),
                        child: Text("Спарені в Android", style: TextStyle(color: kCyanColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      ..._systemDevices.map((dev) {
                        final name = dev.platformName.isNotEmpty ? dev.platformName : "Bluetooth Device";
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: const Icon(Icons.devices, color: kCyanColor),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            subtitle: Text(dev.remoteId.str, style: const TextStyle(color: kSubColor, fontSize: 12)),
                            trailing: TextButton(
                              onPressed: () => _connectToDevice(dev, name),
                              child: const Text("Підключити", style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // Розділ знайдених при скануванні BLE пристроїв
                    if (filteredResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text("Знайдені поблизу", style: TextStyle(color: kSubColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      ...filteredResults.map((res) {
                        final rawName = _getDeviceName(res);
                        final name = rawName.isNotEmpty ? rawName : "Unknown Device";
                        final mac = res.device.remoteId.str;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: Icon(
                              rawName.contains("Vector") || rawName.contains("ESP32") ? Icons.developer_board : Icons.bluetooth,
                              color: rawName.contains("Vector") ? kGreenColor : kCyanColor,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: rawName.contains("Vector") ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text("$mac  ·  ${res.rssi} dBm", style: const TextStyle(color: kSubColor, fontSize: 12)),
                            trailing: TextButton(
                              onPressed: () => _connectToDevice(res.device, name),
                              child: const Text("Підключити", style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }),
                    ] else if (_isScanning) ...[
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator(color: kCyanColor)),
                      ),
                    ] else if (_systemDevices.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text("Пристроїв не знайдено.\nНатисніть оновити для повторного пошуку.", textAlign: TextAlign.center, style: TextStyle(color: kSubColor)),
                        ),
                      ),
                    ],
                  ],
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
