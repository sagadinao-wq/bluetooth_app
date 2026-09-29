import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Поля акумулятора
  int _batteryPercent = 85;
  String _batteryVoltage = "3.90V";

  // UUIDs згідно з прошивкою ESP32
  final String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String _batteryCharUuid = "a23e4210-901e-42cc-8e99-8d6973e659aa";

  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _batteryChar;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<List<int>>? _batterySubscription;

  // Поля детальної VBT статистики підходу
  bool _isRecording = false;
  int _repCount = 0;
  double _lastMeanV = 0.0;
  double _lastPeakV = 0.0;
  int _lastRom = 0;
  double _bestMeanV = 0.0;
  double _velocityLoss = 0.0;

  // Термінал / Консоль логів
  final List<String> _logs = [];
  final TextEditingController _cmdController = TextEditingController();

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
    _batterySubscription?.cancel();
    _cmdController.dispose();
    super.dispose();
  }

  void _addLog(String log, {bool isTx = false}) {
    final timeStr = DateTime.now().toString().substring(11, 19);
    final prefix = isTx ? "➔ [TX]" : "⬅ [RX]";
    if (mounted) {
      setState(() {
        _logs.insert(0, "[$timeStr] $prefix $log");
      });
    }
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
      
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            // Підписка на якісні/VBT дані
            if (char.uuid.toString().toLowerCase() == _dataCharUuid.toLowerCase()) {
              _dataChar = char;
              await _dataChar!.setNotifyValue(true);
              _dataSubscription = _dataChar!.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String msg = utf8.decode(value);
                  _addLog(msg, isTx: false);
                  _processIncomingBleData(msg);
                }
              });
            }
            // Підписка на дані акумулятора (Напруга та Відсотки)
            if (char.uuid.toString().toLowerCase() == _batteryCharUuid.toLowerCase()) {
              _batteryChar = char;
              await _batteryChar!.setNotifyValue(true);
              _batterySubscription = _batteryChar!.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String payload = utf8.decode(value);
                  _addLog("Batt: $payload", isTx: false);
                  _processIncomingBatteryData(payload);
                }
              });
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

      _addLog("Connected to $name");

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

  void _processIncomingBatteryData(String payload) {
    // Парсинг формату видачі ESP32 "3.92V,85%" або "3.92V"
    List<String> parts = payload.split(',');
    if (parts.length == 2) {
      setState(() {
        _batteryVoltage = parts[0];
        _batteryPercent = int.tryParse(parts[1].replaceAll('%', '')) ?? _batteryPercent;
      });
    } else if (payload.contains('V')) {
      setState(() {
        _batteryVoltage = payload;
      });
    }
  }

  void _processIncomingBleData(String msg) {
    if (msg == "SET_START") {
      setState(() {
        _isRecording = true;
      });
    } else if (msg.contains("rep")) {
      try {
        Map<String, dynamic> data = jsonDecode(msg);
        double meanV = (data["mean_v"] ?? 0.0).toDouble();
        double peakV = (data["peak_v"] ?? 0.0).toDouble();
        int rom = (data["rom"] ?? 0).toInt();

        setState(() {
          _isRecording = false;
          _repCount++;
          _lastMeanV = meanV;
          _lastPeakV = peakV;
          _lastRom = rom;

          if (_bestMeanV == 0.0 || meanV > _bestMeanV) {
            _bestMeanV = meanV;
          }
          if (_bestMeanV > 0) {
            _velocityLoss = ((_bestMeanV - meanV) / _bestMeanV) * 100;
            if (_velocityLoss < 0) _velocityLoss = 0;
          }
        });
      } catch (_) {
        // Простий текст, якщо не JSON
      }
    }
  }

  Future<void> _disconnectDevice() async {
    _dataSubscription?.cancel();
    _batterySubscription?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }

    setState(() {
      _connectedDevice = null;
      _isConnected = false;
      _connectedDeviceName = "Не підключено";
      _isRecording = false;
    });

    _addLog("Disconnected from device");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пристрій відключено"), backgroundColor: kRedColor),
      );
    }
  }

  Future<void> _sendBleCommand(String command) async {
    if (_dataChar != null && _isConnected) {
      try {
        await _dataChar!.write(utf8.encode(command));
        _addLog(command, isTx: true);
      } catch (e) {
        _addLog("Err send: $e", isTx: true);
      }
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

      _addLog("Ping: $_pingMs ms, RSSI: $_rssi dBm");

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
              subtitle: Text("$_batteryPercent% ($_batteryVoltage)", style: const TextStyle(color: kSubColor)),
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
            const Divider(color: kDividerColor),
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
              label: "Калібрувати нуль (Tare ZUPT)",
              color: Colors.amber,
              icon: Icons.filter_center_focus_rounded,
              onTap: () {
                Navigator.pop(context);
                _sendBleCommand("TARE");
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
              // Верхній заголовок та компактна плашка стану
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
                      // Панель стану та розширених VBT-метрик
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
                              // Деталізоване табло метрик
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: kBgColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _vbtMetricTile("Повторень", "$_repCount", Colors.white),
                                        _vbtMetricTile("V_mean", "${_lastMeanV.toStringAsFixed(2)} м/с", kGreenColor),
                                        _vbtMetricTile("V_peak", "${_lastPeakV.toStringAsFixed(2)} м/с", kCyanColor),
                                      ],
                                    ),
                                    const Divider(color: kDividerColor, height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _vbtMetricTile("Амплітуда (ROM)", "$_lastRom см", Colors.orangeAccent),
                                        _vbtMetricTile("V_loss (%)", "${_velocityLoss.toStringAsFixed(1)}%",
                                            _velocityLoss > 20 ? kRedColor : Colors.greenAccent),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                              _sendBleCommand("STOP");
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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

                      // БЛОК BLE КОНСОЛІ / ТЕРМІНАЛА ЛОГІВ
                      if (_isConnected) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kCardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("BLE Монітор (Термінал)", style: TextStyle(color: kSubColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 18, color: kCyanColor),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: _logs.join("\n")));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Лог скопійовано"), backgroundColor: kCyanColor),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: kRedColor),
                                        onPressed: () => setState(() => _logs.clear()),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 130,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListView.builder(
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    final log = _logs[index];
                                    final isTx = log.contains("[TX]");
                                    return Text(
                                      log,
                                      style: TextStyle(
                                        color: isTx ? kGreenColor : kCyanColor,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _cmdController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: "Команда (напр. TARE, READ)",
                                        hintStyle: const TextStyle(color: kSubColor, fontSize: 12),
                                        isDense: true,
                                        filled: true,
                                        fillColor: kBgColor,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    style: IconButton.styleFrom(backgroundColor: kCyanColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                                    onPressed: () {
                                      if (_cmdController.text.trim().isNotEmpty) {
                                        _sendBleCommand(_cmdController.text.trim());
                                        _cmdController.clear();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Якщо ПРИСТРІЙ НЕ ПІДКЛЮЧЕНО — показуємо список пристроїв BLE
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

  Widget _vbtMetricTile(String title, String value, Color valColor) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: kSubColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
