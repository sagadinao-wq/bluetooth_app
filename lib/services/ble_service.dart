import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService extends ChangeNotifier {
  // Singleton патерн (один єдиний екземпляр на весь додаток)
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // UUIDs згідно з прошивкою ESP32
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String batteryCharUuid = "a23e4210-901e-42cc-8e99-8d6973e659aa";

  // Стан підключення
  BluetoothDevice? connectedDevice;
  bool isConnected = false;
  bool isScanning = false;
  String connectedDeviceName = "Не підключено";

  // Метрики
  int rssi = -65;
  int pingMs = 15;
  int batteryPercent = 85;
  String batteryVoltage = "3.90V";

  // VBT Метрики підходу
  bool isRecording = false;
  int repCount = 0;
  double lastMeanV = 0.0;
  double lastPeakV = 0.0;
  int lastRom = 0;
  double bestMeanV = 0.0;
  double velocityLoss = 0.0;

  // Термінал / Логи
  final List<String> logs = [];

  // BLE Характеристики
  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _batteryChar;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<List<int>>? _batterySubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  List<ScanResult> scanResults = [];
  List<BluetoothDevice> systemDevices = [];

  void addLog(String log, {bool isTx = false}) {
    final timeStr = DateTime.now().toString().substring(11, 19);
    final prefix = isTx ? "➔ [TX]" : "⬅ [RX]";
    logs.insert(0, "[$timeStr] $prefix $log");
    notifyListeners();
  }

  Future<void> fetchSystemDevices() async {
    try {
      systemDevices = await FlutterBluePlus.systemDevices;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> startScan() async {
    if (isScanning) return;
    isScanning = true;
    scanResults.clear();
    notifyListeners();

    await fetchSystemDevices();

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      addLog("Err scan: $e", isTx: true);
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device, String name) async {
    // Скасовуємо старі з'єднання та підписки перед новим підключенням
    await disconnectDevice();

    try {
      await device.connect(timeout: const Duration(seconds: 8));

      // Слухаємо зміну стану підключення
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnected();
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == dataCharUuid.toLowerCase()) {
              _dataChar = char;
              await _dataChar!.setNotifyValue(true);
              
              await _dataSubscription?.cancel();
              _dataSubscription = _dataChar!.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String msg = utf8.decode(value);
                  addLog(msg, isTx: false);
                  _processIncomingBleData(msg);
                }
              });
            }
            if (char.uuid.toString().toLowerCase() == batteryCharUuid.toLowerCase()) {
              _batteryChar = char;
              await _batteryChar!.setNotifyValue(true);

              await _batterySubscription?.cancel();
              _batterySubscription = _batteryChar!.lastValueStream.listen((value) {
                if (value.isNotEmpty) {
                  String payload = utf8.decode(value);
                  addLog("Batt: $payload", isTx: false);
                  _processIncomingBatteryData(payload);
                }
              });
            }
          }
        }
      }

      try {
        rssi = await device.readRssi();
      } catch (_) {}

      connectedDevice = device;
      isConnected = true;
      connectedDeviceName = name;
      addLog("Connected to $name");
      notifyListeners();
      return true;
    } catch (e) {
      addLog("Err connect: $e", isTx: true);
      await disconnectDevice();
      return false;
    }
  }

  void _processIncomingBatteryData(String payload) {
    List<String> parts = payload.split(',');
    if (parts.length == 2) {
      batteryVoltage = parts[0];
      batteryPercent = int.tryParse(parts[1].replaceAll('%', '')) ?? batteryPercent;
    } else if (payload.contains('V')) {
      batteryVoltage = payload;
    }
    notifyListeners();
  }

  void _processIncomingBleData(String msg) {
    if (msg == "SET_START") {
      isRecording = true;
    } else if (msg.contains("rep")) {
      try {
        Map<String, dynamic> data = jsonDecode(msg);
        double meanV = (data["mean_v"] ?? 0.0).toDouble();
        double peakV = (data["peak_v"] ?? 0.0).toDouble();
        int rom = (data["rom"] ?? 0).toInt();

        isRecording = false;
        repCount++;
        lastMeanV = meanV;
        lastPeakV = peakV;
        lastRom = rom;

        if (bestMeanV == 0.0 || meanV > bestMeanV) {
          bestMeanV = meanV;
        }
        if (bestMeanV > 0) {
          velocityLoss = ((bestMeanV - meanV) / bestMeanV) * 100;
          if (velocityLoss < 0) velocityLoss = 0;
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> sendBleCommand(String command) async {
    if (_dataChar != null && isConnected) {
      try {
        await _dataChar!.write(utf8.encode(command));
        if (command == "START") isRecording = true;
        if (command == "STOP") isRecording = false;
        addLog(command, isTx: true);
      } catch (e) {
        addLog("Err send: $e", isTx: true);
      }
      notifyListeners();
    }
  }

  Future<void> measurePing() async {
    if (!isConnected || connectedDevice == null) return;
    final stopwatch = Stopwatch()..start();
    try {
      final newRssi = await connectedDevice!.readRssi();
      stopwatch.stop();
      rssi = newRssi;
      pingMs = stopwatch.elapsedMilliseconds;
      addLog("Ping: $pingMs ms, RSSI: $rssi dBm");
      notifyListeners();
    } catch (_) {}
  }

  Future<void> disconnectDevice() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await _connSub?.cancel();
    _connSub = null;

    await _dataSubscription?.cancel();
    _dataSubscription = null;

    await _batterySubscription?.cancel();
    _batterySubscription = null;

    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
    }

    _handleDisconnected();
  }

  void _handleDisconnected() {
    connectedDevice = null;
    isConnected = false;
    connectedDeviceName = "Не підключено";
    isRecording = false;
    _dataChar = null;
    _batteryChar = null;
    addLog("Disconnected");
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectDevice();
    super.dispose();
  }
}
