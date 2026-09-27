import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _isScanning = false;
  bool _hideUnknown = true;
  List<ScanResult> _scanResults = [];
  List<BluetoothDevice> _systemDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  String _connectedDeviceName = "Не підключено";
  int _rssi = -65;
  int _pingMs = 15;
  int _batteryPercent = 85;

  // UUIDs згідно з прошивкою ESP32
  final String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String _batteryCharUuid = "a23e4210-901e-42cc-8e99-8d6973e659aa";

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _batteryChar;
  StreamSubscription<List<int>>? _dataSubscription;

  // Поля запису підходу
  bool _isRecording = false;
  int _repCount = 0;
  double _lastVelocity = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSystemDevices();
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

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

  Future<void> _startScan() async {
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
      
      // Пошук сервісів та характеристик для синхронізації
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _dataCharUuid.toLowerCase()) {
              _dataChar = char;
              await _dataChar!.setNotifyValue(true);
              // Слухаємо дані від фізичної кнопки 1 ESP32
              _dataSubscription = _dataChar!.lastValueStream.listen((value) {
                String msg = utf8.decode(value);
                if (msg == "SET_START") {
                  setState(() => _isRecording = true);
                } else if (msg.contains("rep")) {
                  setState(() {
                    _isRecording = false;
                    _repCount++;
                    _lastVelocity = 0.68; // Приклад розпарсеного значення
                  });
                }
              });
            }
            if (char.uuid.toString().toLowerCase() == _batteryCharUuid.toLowerCase()) {
              _batteryChar = char;
            }
          }
        }
      }

      int rssi = -60;
      try {
        rssi = await device.readRssi();
      } catch (_) {}

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _connectedDeviceName = name;
        _rssi = rssi;
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
    _dataSubscription?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }

    setState(() {
      _connectedDevice = null;
      _isConnected = false;
      _connectedDeviceName = "Не підключено";
      _isRecording = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пристрій відключено"), backgroundColor: kRedColor),
      );
    }
  }

  // Надсилання команди на ESP32 з додатку
  Future<void> _sendBleCommand(String command) async {
    if (_dataChar != null && _isConnected) {
      try {
        await _dataChar!.write(utf8.encode(command));
      } catch (_) {}
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
    } catch (_) {}
  }

  // Діалогове вікно детальної статистики та заміру пінгу
  void _showDeviceDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(_connectedDeviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.battery_charging_full, color: kGreenColor),
              title: const Text("Заряд батареї", style: TextStyle(color: Colors.white)),
              subtitle: Text("$_batteryPercent% (3.9V)", style: const TextStyle(color: kSubColor)),
            ),
            ListTile(
              leading: const Icon(Icons.speed, color: kCyanColor),
              title: const Text("Пінг (Latency)", style: TextStyle(color: Colors.white)),
              subtitle: Text("$_pingMs ms", style: const TextStyle(color: kSubColor)),
            ),
            ListTile(
              leading: const Icon(Icons.network_cell, color: kCyanColor),
              title: const Text("Рівень сигналу", style: TextStyle(color: Colors.white)),
              subtitle: Text("$_rssi dBm", style: const TextStyle(color: kSubColor)),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: "Заміряти пінг",
              color: kCyanColor,
              icon: Icons.bolt_rounded,
              onTap: () {
                Navigator.pop(context);
                _measurePing();
              },
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: "Відключити пристрій",
              color: kRedColor,
              icon: Icons.power_settings_new_rounded,
              onTap: () {
                Navigator.pop(context);
                _disconnectDevice();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDeviceName(ScanResult res) {
    if (res.device.platformName.isNotEmpty) return res.device.platformName;
    if (res.advertisementData.advName.isNotEmpty) return res.advertisementData.advName;
    if (res.advertisementData.localName.isNotEmpty) return res.advertisementData.localName;
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final filteredResults = _scanResults.where((r) {
      final name = _getDeviceName(r);
      if (_hideUnknown && name.isEmpty) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхня панель з інформаційним блоком праворуч
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Vector VBT Sensor",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_isConnected)
                    GestureDetector(
                      onTap: _showDeviceDetailsDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kCyanColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.battery_charging_full, size: 16, color: kGreenColor),
                            const SizedBox(width: 4),
                            Text("$_batteryPercent%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.speed, size: 16, color: kCyanColor),
                            const SizedBox(width: 2),
                            Text("${_pingMs}ms", style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _startScan,
                  color: kCyanColor,
                  backgroundColor: kCardColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Панель стану та керування підходом
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.developer_board,
                                      color: _isConnected ? kCyanColor : kSubColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _connectedDeviceName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
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

                            if (_isConnected) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Text("Повторень: $_repCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text("V_mean: ${_lastVelocity.toStringAsFixed(2)} м/с", style: const TextStyle(color: kGreenColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Розділені окремі кнопки «Почати запис» та «Завершити підхід»
                              Row(
                                children: [
                                  Expanded(
                                    child: PrimaryButton(
                                      label: "Почати запис",
                                      color: _isRecording ? kSubColor : kGreenColor,
                                      icon: Icons.play_arrow_rounded,
                                      onTap: _isRecording
                                          ? null
                                          : () {
                                              setState(() => _isRecording = true);
                                              _sendBleCommand("START");
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PrimaryButton(
                                      label: "Завершити",
                                      color: !_isRecording ? kSubColor : kRedColor,
                                      icon: Icons.stop_rounded,
                                      onTap: !_isRecording
                                          ? null
                                          : () {
                                              setState(() {
                                                _isRecording = false;
                                                _repCount++;
                                                _lastVelocity = 0.71;
                                              });
                                              _sendBleCommand("STOP");
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Яскраво виділена кнопка «Скачати CSV сесії»
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kCyanColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Збереження CSV файлу..."), backgroundColor: kGreenColor),
                                    );
                                  },
                                  icon: const Icon(Icons.download_rounded, color: Colors.black),
                                  label: const Text("Скачати CSV сесії", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              PrimaryButton(
                                label: _isScanning ? "Сканування..." : "Сканувати пристрої",
                                color: kCyanColor,
                                icon: Icons.search_rounded,
                                onTap: _isScanning ? null : _startScan,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Якщо ПРИСТРІЙ ПІДКЛЮЧЕНО — список інших пристроїв ПРИХОВУЄТЬСЯ
                      if (!_isConnected) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Bluetooth пристрої", style: TextStyle(color: kSubColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            FilterChip(
                              label: Text(_hideUnknown ? "Тільки з ім'ям" : "Усі пристрої", style: const TextStyle(fontSize: 11, color: Colors.white)),
                              selected: _hideUnknown,
                              onSelected: (val) => setState(() => _hideUnknown = val),
                              selectedColor: kCyanColor.withOpacity(0.3),
                              backgroundColor: kCardColor,
                              checkmarkColor: kCyanColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

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

                        if (filteredResults.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text("Знайдені поблизу (потягніть вниз для оновлення)", style: TextStyle(color: kSubColor, fontSize: 12, fontWeight: FontWeight.w600)),
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
                        ],
                      ],
                    ],
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
