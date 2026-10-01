import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BleStatus { disconnected, scanning, connecting, connected, reconnecting }

class BleService extends ChangeNotifier {
  // Singleton паттерн
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // UUIDs под прошивку ESP32
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String batteryCharUuid = "a23e4210-901e-42cc-8e99-8d6973e659aa";

  // Состояние и статусы
  BleStatus status = BleStatus.disconnected;
  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  String connectedDeviceName = "Не підключено";

  // Метрики
  int rssi = -65;
  int pingMs = 15;
  bool isPinging = false;
  int batteryPercent = 85;
  String batteryVoltage = "3.90V";

  // VBT Метрики подхода
  bool isRecording = false;
  int repCount = 0;
  double lastMeanV = 0.0;
  double lastPeakV = 0.0;
  int lastRom = 0;
  double bestMeanV = 0.0;
  double velocityLoss = 0.0;

  // Терминал / Логи
  final List<String> logs = [];

  // BLE Характеристики и подписки
  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _batteryChar;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<List<int>>? _batterySubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _autoReconnectTimer;

  List<ScanResult> scanResults = [];
  List<BluetoothDevice> systemDevices = [];

  // Геттеры для отображения статуса в TopBar
  bool get isConnected => status == BleStatus.connected;

  String get statusText {
    switch (status) {
      case BleStatus.connected:
        return "Підключено";
      case BleStatus.connecting:
        return "З'єднання...";
      case BleStatus.reconnecting:
        return "Повтор...";
      case BleStatus.scanning:
        return "Пошук...";
      case BleStatus.disconnected:
      default:
        return "Відключено";
    }
  }

  Color get statusColor {
    switch (status) {
      case BleStatus.connected:
        return const Color(0xFF32D74B);
      case BleStatus.connecting:
      case BleStatus.reconnecting:
      case BleStatus.scanning:
        return const Color(0xFF00C2FF);
      case BleStatus.disconnected:
      default:
        return const Color(0xFFFF3B4E);
    }
  }

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
    if (status == BleStatus.scanning) return;
    status = BleStatus.scanning;
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
      if (status == BleStatus.scanning) {
        status = BleStatus.disconnected;
      }
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device, [String? name]) async {
    await disconnectDevice();

    status = BleStatus.connecting;
    connectedDeviceName = name ?? (device.platformName.isNotEmpty ? device.platformName : "Vector Pin");
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 8));

      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleUnexpectedDisconnect();
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
      status = BleStatus.connected;
      _autoReconnectTimer?.cancel();
      addLog("Connected to $connectedDeviceName");
      notifyListeners();
      return true;
    } catch (e) {
      addLog("Err connect: $e", isTx: true);
      _handleUnexpectedDisconnect();
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
    isPinging = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      final newRssi = await connectedDevice!.readRssi();
      stopwatch.stop();
      rssi = newRssi;
      pingMs = stopwatch.elapsedMilliseconds;
      addLog("Ping: $pingMs ms, RSSI: $rssi dBm");
    } catch (_) {
      pingMs = -1;
    } finally {
      isPinging = false;
      notifyListeners();
    }
  }

  void _handleUnexpectedDisconnect() {
    if (connectedDevice == null) {
      _resetState();
      return;
    }
    status = BleStatus.reconnecting;
    notifyListeners();

    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (connectedDevice != null) {
        try {
          await connectedDevice!.connect(autoConnect: false);
          status = BleStatus.connected;
          timer.cancel();
          addLog("Reconnected automatically");
          notifyListeners();
        } catch (_) {}
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> disconnectDevice() async {
    _autoReconnectTimer?.cancel();
    await _scanSubscription?.cancel();
    await _connSub?.cancel();
    await _dataSubscription?.cancel();
    await _batterySubscription?.cancel();

    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
    }

    _resetState();
  }

  void _resetState() {
    connectedDevice = null;
    status = BleStatus.disconnected;
    connectedDeviceName = "Не підключено";
    isRecording = false;
    _dataChar = null;
    _batteryChar = null;
    pingMs = 0;
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
