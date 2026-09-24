import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VBT Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const BleApp(),
    );
  }
}

// ===== Nordic UART Service UUID-и =====
// Стандарт, який підтримують готові BLE-бібліотеки для ESP32,
// тож прошивку не доведеться підганяти під довільний формат.
final Guid nusServiceUuid = Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
final Guid nusRxUuid = Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e"); // телефон → пристрій (write)
final Guid nusTxUuid = Guid("6e400003-b5a3-f393-e0a9-e50e24dcca9e"); // пристрій → телефон (notify)

class BleApp extends StatefulWidget {
  const BleApp({super.key});

  @override
  State<BleApp> createState() => _BleAppState();
}

class _BleAppState extends State<BleApp> {
  final List<ScanResult> _scanResults = [];
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar; // notify
  BluetoothCharacteristic? _rxChar; // write
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  bool _isScanning = false;
  bool _isConnected = false;
  bool _isRecording = false;

  // Записані відліки одного підходу: [мс від старту запису, сирий рядок з пристрою]
  final List<_Sample> _samples = [];
  Stopwatch? _setStopwatch;
  String _lastLine = "";
  String? _lastSavedPath;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Android 12+ вимагає ці дозволи в рантаймі окремо від Manifest.
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults
          ..clear()
          ..addAll(results.where((r) => r.device.platformName.isNotEmpty));
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connSub = device.connectionState.listen((state) {
        setState(() => _isConnected = state == BluetoothConnectionState.connected);
        if (state == BluetoothConnectionState.disconnected) {
          _stopRecordingInternal();
        }
      });

      final services = await device.discoverServices();
      for (final s in services) {
        if (s.uuid == nusServiceUuid) {
          for (final c in s.characteristics) {
            if (c.uuid == nusTxUuid) _txChar = c;
            if (c.uuid == nusRxUuid) _rxChar = c;
          }
        }
      }

      if (_txChar == null) {
        _showSnackBar("На пристрої не знайдено сервіс UART. Перевір прошивку ESP32.");
        return;
      }

      await _txChar!.setNotifyValue(true);
      _notifySub = _txChar!.onValueReceived.listen(_onData);

      setState(() {
        _device = device;
        _isConnected = true;
      });
    } catch (e) {
      _showSnackBar("Помилка підключення: $e");
    }
  }

  void _onData(List<int> bytes) {
    final line = String.fromCharCodes(bytes).trim();
    setState(() => _lastLine = line);
    if (_isRecording && _setStopwatch != null) {
      _samples.add(_Sample(_setStopwatch!.elapsedMilliseconds, line));
    }
  }

  Future<void> _disconnect() async {
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _device?.disconnect();
    setState(() {
      _isConnected = false;
      _device = null;
      _txChar = null;
      _rxChar = null;
    });
  }

  Future<void> _sendCommand(String command) async {
    if (_rxChar == null) return;
    await _rxChar!.write(command.codeUnits, withoutResponse: true);
  }

  void _startSet() {
    setState(() {
      _samples.clear();
      _setStopwatch = Stopwatch()..start();
      _isRecording = true;
      _lastSavedPath = null;
    });
    _sendCommand("START");
  }

  Future<void> _stopSet() async {
    _stopRecordingInternal();
    await _sendCommand("STOP");
    await _saveSetToFile();
  }

  void _stopRecordingInternal() {
    _setStopwatch?.stop();
    setState(() => _isRecording = false);
  }

  Future<void> _saveSetToFile() async {
    if (_samples.isEmpty) {
      _showSnackBar("Підхід порожній, немає що зберігати.");
      return;
    }
    try {
      final dir = await getExternalStorageDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = "${dir?.path}/set_$stamp.csv";
      final file = File(path);

      final buffer = StringBuffer("elapsed_ms,raw\n");
      for (final s in _samples) {
        buffer.writeln("${s.elapsedMs},${s.raw}");
      }
      await file.writeAsString(buffer.toString());

      setState(() => _lastSavedPath = path);
      _showSnackBar("Збережено: $path (${_samples.length} відліків)");
    } catch (e) {
      _showSnackBar("Помилка збереження: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VBT Logger"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            if (!_isConnected) _buildScanSection(),
            if (_isConnected) _buildRecordingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isConnected ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: _isConnected ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isConnected
                  ? "Підключено: ${_device?.platformName ?? 'Пристрій'}"
                  : "Не підключено",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: _disconnect,
            ),
        ],
      ),
    );
  }

  Widget _buildScanSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            icon: const Icon(Icons.search),
            label: Text(_isScanning ? "Пошук..." : "Знайти пристрій"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.cyan,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, i) {
                final r = _scanResults[i];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    title: Text(r.device.platformName),
                    subtitle: Text(r.device.remoteId.str),
                    trailing: Text("${r.rssi} dBm"),
                    onTap: () => _connect(r.device),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isRecording ? null : _startSet,
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text("Почати підхід"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(18),
              backgroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isRecording ? _stopSet : null,
            icon: const Icon(Icons.stop),
            label: const Text("Завершити підхід"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(18),
              backgroundColor: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRecording
                ? "Записується... ${_samples.length} відліків"
                : "Готово до запису",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text("Останній пакет: $_lastLine", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (_lastSavedPath != null) ...[
            const SizedBox(height: 12),
            Text("Збережено: $_lastSavedPath", style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
          ],
        ],
      ),
    );
  }
}

class _Sample {
  final int elapsedMs;
  final String raw;
  _Sample(this.elapsedMs, this.raw);
}
