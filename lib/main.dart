import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

// Константи кольорів нової теми
const _bg = Color(0xFF0A0A0A);
const _card = Color(0xFF1C1C1E);
const _sub = Color(0xFF8E8E93);
const _red = Color(0xFFFF3B4E);
const _green = Color(0xFF30D158);
const _cyan = Color(0xFF64D2FF);
const _divider = Color(0xFF2C2C2E);

final Guid nusServiceUuid = Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
final Guid nusRxUuid = Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e");
final Guid nusTxUuid = Guid("6e400003-b5a3-f393-e0a9-e50e24dcca9e");

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VBT Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _cyan,
          surface: _card,
        ),
      ),
      home: const MainLoggerScreen(),
    );
  }
}

class MainLoggerScreen extends StatefulWidget {
  const MainLoggerScreen({super.key});

  @override
  State<MainLoggerScreen> createState() => _MainLoggerScreenState();
}

class _MainLoggerScreenState extends State<MainLoggerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<ScanResult> _scanResults = [];
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  bool _isScanning = false;
  bool _isConnected = false;
  bool _isRecording = false;

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
      if (mounted) {
        setState(() {
          _scanResults
            ..clear()
            ..addAll(results.where((r) => r.device.platformName.isNotEmpty));
        });
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connSub = device.connectionState.listen((state) {
        if (mounted) {
          setState(() => _isConnected = state == BluetoothConnectionState.connected);
        }
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
        _showSnackBar("На пристрої не знайдено сервіс UART.");
        return;
      }

      await _txChar!.setNotifyValue(true);
      _notifySub = _txChar!.onValueReceived.listen(_onData);

      if (mounted) {
        setState(() {
          _device = device;
          _isConnected = true;
        });
      }
    } catch (e) {
      _showSnackBar("Помилка підключення: $e");
    }
  }

  void _onData(List<int> bytes) {
    final line = String.fromCharCodes(bytes).trim();
    if (mounted) {
      setState(() => _lastLine = line);
    }
    if (_isRecording && _setStopwatch != null) {
      _samples.add(_Sample(_setStopwatch!.elapsedMilliseconds, line));
    }
  }

  Future<void> _disconnect() async {
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _device?.disconnect();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _device = null;
        _txChar = null;
        _rxChar = null;
      });
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_rxChar == null) return;
    await _rxChar!.write(command.codeUnits, withoutResponse: true);
    _showSnackBar("Команда відправлена: $command");
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
    if (mounted) {
      setState(() => _isRecording = false);
    }
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

      if (mounted) setState(() => _lastSavedPath = path);
      _showSnackBar("Збережено: $path (${_samples.length} відліків)");
    } catch (e) {
      _showSnackBar("Помилка збереження: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
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
      key: _scaffoldKey,
      backgroundColor: _bg,
      endDrawer: DeviceDrawer(
        deviceName: _device?.platformName ?? "VBT Sensor",
        isConnected: _isConnected,
        onDisconnect: _disconnect,
        onReconnect: () {
          if (_device != null) _connect(_device!);
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхня панель: Кнопка Меню та Статус підключення
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _device?.platformName ?? "VBT Controller",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? _green : _red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? "Connected" : "Disconnected",
                        style: TextStyle(
                          color: _isConnected ? _green : _red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _IconButton(
                        icon: Icons.menu_rounded,
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Основний контент екрана
              Expanded(
                child: _isConnected
                    ? _buildRecordingControls()
                    : _buildScanSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Віджет для сканування та вибору пристрою
  Widget _buildScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isScanning ? null : _startScan,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isScanning ? Icons.sync : Icons.search_rounded, color: _cyan),
                const SizedBox(width: 10),
                Text(
                  _isScanning ? "Scanning..." : "Search BLE Device",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, i) {
              final r = _scanResults[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    r.device.platformName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(r.device.remoteId.str, style: const TextStyle(color: _sub)),
                  trailing: Text("${r.rssi} dBm", style: const TextStyle(color: _cyan)),
                  onTap: () => _connect(r.device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Віджет керування підходом (записом)
  Widget _buildRecordingControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isConnected ? () => _sendCommand("PING") : null,
          icon: const Icon(Icons.network_check_rounded),
          label: const Text("Ping Connection"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(18),
            backgroundColor: _card,
            foregroundColor: _cyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRecording ? null : _startSet,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text("Start Set"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRecording ? _stopSet : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text("Stop Set"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRecording
                    ? "Recording... (${_samples.length} samples)"
                    : "Ready for next set",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text("Last Raw Data: $_lastLine", style: const TextStyle(fontSize: 13, color: _sub)),
              if (_lastSavedPath != null) ...[
                const SizedBox(height: 12),
                Text("Saved to: $_lastSavedPath", style: const TextStyle(fontSize: 12, color: _cyan)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Висувна бокова панель Налаштувань та Статусу
class DeviceDrawer extends StatefulWidget {
  final String deviceName;
  final bool isConnected;
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;

  const DeviceDrawer({
    super.key,
    required this.deviceName,
    required this.isConnected,
    required this.onDisconnect,
    required this.onReconnect,
  });

  @override
  State<DeviceDrawer> createState() => _DeviceDrawerState();
}

class _DeviceDrawerState extends State<DeviceDrawer> {
  int _tab = 0; // 0 = Status, 1 = Settings

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _bg,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.deviceName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _IconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _TabBar(
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _tab == 0
                    ? const _StatusPanel()
                    : _SettingsPanel(
                        onDisconnect: widget.onDisconnect,
                        onReconnect: widget.onReconnect,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _TabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _divider, width: 1))),
      child: Row(
        children: [
          _TabItem(text: "Status", active: selected == 0, onTap: () => onChanged(0)),
          const SizedBox(width: 26),
          _TabItem(text: "Settings", active: selected == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({required this.text, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? Colors.white : Colors.transparent, width: 2)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _sub,
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 10),
        const Center(child: Text("Battery Level", style: TextStyle(color: _sub, fontSize: 14))),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (i) => Container(
              width: 36,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: const Color(0xFF2A2A2C), borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: const [
              _InfoRow(label: "Sensor Firmware"),
              _Divider(),
              _InfoRow(label: "Sensor Position"),
              _Divider(),
              _InfoRow(label: "Advanced Calibration"),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: _divider, indent: 20, endIndent: 20);
}

class _InfoRow extends StatelessWidget {
  final String label;
  const _InfoRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFFD1D1D6))),
          const Icon(Icons.warning_rounded, color: _red, size: 20),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;

  const _SettingsPanel({required this.onDisconnect, required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _SectionLabel("Hardware Update"),
        const _SettingsRow(icon: Icons.system_update_alt_rounded, label: "Update Device"),
        const _SectionLabel("Calibration"),
        const _SettingsRow(icon: Icons.tune_rounded, label: "Calibrate device"),
        const _SectionLabel("Reconnect"),
        _SettingsRow(
          icon: Icons.sync_rounded,
          label: "Reconnect",
          onTap: onReconnect,
        ),
        const _SectionLabel("Disconnect device"),
        _SettingsRow(
          icon: Icons.power_settings_new_rounded,
          label: "Disconnect",
          danger: true,
          onTap: onDisconnect,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: const TextStyle(color: _sub, fontSize: 13)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _red : Colors.white;
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: danger ? _red : const Color(0xFFC7C7CC), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF5A5A5E), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
class _Sample {
  final int elapsedMs;
  final String raw;
  _Sample(this.elapsedMs, this.raw);
}
