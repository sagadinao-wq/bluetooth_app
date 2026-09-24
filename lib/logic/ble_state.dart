import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

enum BleStatus { disconnected, scanning, connecting, connected, reconnecting }

class BleStateProvider extends ChangeNotifier {
  BleStatus _status = BleStatus.disconnected;
  BluetoothDevice? _connectedDevice;
  String _deviceName = "Не підключено";
  int _batteryLevel = 100;
  int _rssi = -100;
  int _pingMs = 0;
  bool _isPinging = false;
  
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _autoReconnectTimer;

  // Геттери для UI
  BleStatus get status => _status;
  String get deviceName => _deviceName;
  int get batteryLevel => _batteryLevel;
  int get rssi => _rssi;
  int get pingMs => _pingMs;
  bool get isPinging => _isPinging;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Статус для TopBar
  String get statusText {
    switch (_status) {
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
    switch (_status) {
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

  // Початок сканування
  Future<void> startScan() async {
    if (_status == BleStatus.scanning) return;
    _status = BleStatus.scanning;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      _status = BleStatus.disconnected;
      notifyListeners();
    }
  }

  // Підключення до обраного ESP32
  Future<void> connectToDevice(BluetoothDevice device) async {
    _status = BleStatus.connecting;
    _deviceName = device.platformName.isNotEmpty ? device.platformName : "Vector Pin";
    notifyListeners();

    try {
      await device.connect(autoConnect: false);
      _connectedDevice = device;
      _status = BleStatus.connected;

      // Відстеження розриву зв'язку для Авто-перепідключення
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleUnexpectedDisconnect();
        }
      });

      await updateRssi();
      notifyListeners();
    } catch (e) {
      _handleUnexpectedDisconnect();
    }
  }

  // Замір пінгу (Ping Latency Test)
  Future<void> measurePing() async {
    if (_connectedDevice == null || _status != BleStatus.connected) return;

    _isPinging = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    try {
      // Використовуємо реальний запит RSSI як замір RTT затримки з'єднання
      _rssi = await _connectedDevice!.readRssi();
      stopwatch.stop();
      _pingMs = stopwatch.elapsedMilliseconds;
    } catch (_) {
      _pingMs = -1;
    } finally {
      _isPinging = false;
      notifyListeners();
    }
  }

  // Оновлення рівню сигналу RSSI
  Future<void> updateRssi() async {
    if (_connectedDevice != null && _status == BleStatus.connected) {
      try {
        _rssi = await _connectedDevice!.readRssi();
        notifyListeners();
      } catch (_) {}
    }
  }

  // Логіка автоматичного перепідключення
  void _handleUnexpectedDisconnect() {
    if (_connectedDevice == null) return;
    _status = BleStatus.reconnecting;
    notifyListeners();

    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_connectedDevice != null) {
        try {
          await _connectedDevice!.connect(autoConnect: false);
          _status = BleStatus.connected;
          timer.cancel();
          notifyListeners();
        } catch (_) {}
      } else {
        timer.cancel();
      }
    });
  }

  // Примусове відключення
  Future<void> disconnect() async {
    _autoReconnectTimer?.cancel();
    _connSub?.cancel();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectedDevice = null;
    _status = BleStatus.disconnected;
    _deviceName = "Не підключено";
    _pingMs = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _autoReconnectTimer?.cancel();
    super.dispose();
  }
}
