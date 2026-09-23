import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const BluetoothApp(),
    );
  }
}

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({super.key});

  @override
  State<BluetoothApp> createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? _connection;
  BluetoothDevice? _selectedDevice;

  List<BluetoothDevice> _devicesList = [];
  bool _isConnected = false;
  bool _isRecording = false;
  List<String> _receivedData = [];

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint("Помилка отримання пристроїв: $e");
    }
    setState(() {
      _devicesList = devices;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _selectedDevice = device;
    });

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _isConnected = true;
      });

      _connection!.input!.listen((data) {
        String incoming = utf8.decode(data);
        if (_isRecording) {
          setState(() {
            _receivedData.add("${DateTime.now()}: $incoming");
          });
        }
      }).onDone(() {
        setState(() {
          _isConnected = false;
        });
      });
    } catch (e) {
      _showSnackBar("Помилка підключення: $e");
      setState(() {
        _isConnected = false;
      });
    }
  }

  void _disconnect() async {
    await _connection?.close();
    setState(() {
      _isConnected = false;
      _isRecording = false;
    });
  }

  void _sendCommand(String command) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(utf8.encode(command));
      await _connection!.output.allSent;
      _showSnackBar("Відправлено команду: $command");
    }
  }

  Future<void> _saveDataToFile() async {
    if (_receivedData.isEmpty) {
      _showSnackBar("Немає даних для збереження!");
      return;
    }

    try {
      final directory = await getExternalStorageDirectory();
      final path = "${directory?.path}/bluetooth_data_${DateTime.now().millisecondsSinceEpoch}.txt";
      final file = File(path);

      await file.writeAsString(_receivedData.join("\n"));
      _showSnackBar("Файл збережено: $path");
    } catch (e) {
      _showSnackBar("Помилка збереження файлу: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Control"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<BluetoothDevice>(
                isExpanded: true,
                hint: const Text("Оберіть Bluetooth пристрій"),
                value: _selectedDevice,
                underline: const SizedBox(),
                items: _devicesList.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name ?? device.address),
                  );
                }).toList(),
                onChanged: (device) {
                  if (device != null) {
                    _connectToDevice(device);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            Container(
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
                          ? "Підключено до: ${_selectedDevice?.name ?? 'Пристрій'}"
                          : "Статус: Не підключено",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_isConnected)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: _disconnect,
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isConnected ? () => _sendCommand("PING") : null,
              icon: const Icon(Icons.network_check),
              label: const Text("Перевірити з'єднання"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.cyan,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected && !_isRecording
                        ? () {
                            setState(() => _isRecording = true);
                            _sendCommand("START");
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Увімкнути запис"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected && _isRecording
                        ? () {
                            setState(() => _isRecording = false);
                            _sendCommand("STOP");
                          }
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("Вимкнути запис"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _receivedData.isNotEmpty ? _saveDataToFile : null,
              icon: const Icon(Icons.download),
              label: Text("Скачати файл (${_receivedData.length} записів)"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
