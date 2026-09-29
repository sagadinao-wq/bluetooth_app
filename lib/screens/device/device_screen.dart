import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../services/ble_service.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final BleService _ble = BleService();
  bool _hideUnknown = true;
  final TextEditingController _cmdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Підписуємося на оновлення сервісу для перебудови UI
    _ble.addListener(_onBleUpdate);
    if (!_ble.isConnected) {
      _ble.startScan();
    }
  }

  @override
  void dispose() {
    _ble.removeListener(_onBleUpdate);
    _cmdController.dispose();
    super.dispose();
  }

  void _onBleUpdate() {
    if (mounted) setState(() {});
  }

  void _showDeviceDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(_ble.connectedDeviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.battery_charging_full, color: kGreenColor),
              title: const Text("Заряд батареї", style: TextStyle(color: Colors.white)),
              subtitle: Text("${_ble.batteryPercent}% (${_ble.batteryVoltage})", style: const TextStyle(color: kSubColor)),
            ),
            ListTile(
              leading: const Icon(Icons.speed, color: kCyanColor),
              title: const Text("Пінг (Latency)", style: TextStyle(color: Colors.white)),
              subtitle: Text("${_ble.pingMs} ms", style: const TextStyle(color: kSubColor)),
            ),
            ListTile(
              leading: const Icon(Icons.network_cell, color: kCyanColor),
              title: const Text("Рівень сигналу", style: TextStyle(color: Colors.white)),
              subtitle: Text("${_ble.rssi} dBm", style: const TextStyle(color: kSubColor)),
            ),
            const Divider(color: kDividerColor),
            PrimaryButton(
              label: "Заміряти пінг",
              color: kCyanColor,
              icon: Icons.bolt_rounded,
              onTap: () {
                Navigator.pop(context);
                _ble.measurePing();
              },
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: "Калібрувати нуль (Tare ZUPT)",
              color: Colors.amber,
              icon: Icons.filter_center_focus_rounded,
              onTap: () {
                Navigator.pop(context);
                _ble.sendBleCommand("TARE");
              },
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: "Відключити пристрій",
              color: kRedColor,
              icon: Icons.power_settings_new_rounded,
              onTap: () {
                Navigator.pop(context);
                _ble.disconnectDevice();
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
    final filteredResults = _ble.scanResults.where((r) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Vector VBT Sensor",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (_ble.isConnected)
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
                            Text("${_ble.batteryPercent}%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.speed, size: 16, color: kCyanColor),
                            const SizedBox(width: 2),
                            Text("${_ble.pingMs}ms", style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _ble.startScan,
                  color: kCyanColor,
                  backgroundColor: kCardColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _ble.isConnected ? kCyanColor : kDividerColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.developer_board, color: _ble.isConnected ? kCyanColor : kSubColor, size: 22),
                                    const SizedBox(width: 10),
                                    Text(_ble.connectedDeviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (_ble.isConnected ? kGreenColor : kRedColor).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _ble.isConnected ? "Підключено" : "Відключено",
                                    style: TextStyle(color: _ble.isConnected ? kGreenColor : kRedColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),

                            if (_ble.isConnected) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(14)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _vbtMetricTile("Повторень", "${_ble.repCount}", Colors.white),
                                        _vbtMetricTile("V_mean", "${_ble.lastMeanV.toStringAsFixed(2)} м/с", kGreenColor),
                                        _vbtMetricTile("V_peak", "${_ble.lastPeakV.toStringAsFixed(2)} м/с", kCyanColor),
                                      ],
                                    ),
                                    const Divider(color: kDividerColor, height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _vbtMetricTile("Амплітуда (ROM)", "${_ble.lastRom} см", Colors.orangeAccent),
                                        _vbtMetricTile("V_loss (%)", "${_ble.velocityLoss.toStringAsFixed(1)}%",
                                            _ble.velocityLoss > 20 ? kRedColor : Colors.greenAccent),
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
                                      color: _ble.isRecording ? kSubColor : kGreenColor,
                                      icon: Icons.play_arrow_rounded,
                                      onTap: _ble.isRecording ? null : () => _ble.sendBleCommand("START"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: PrimaryButton(
                                      label: "Завершити",
                                      color: !_ble.isRecording ? kSubColor : kRedColor,
                                      icon: Icons.stop_rounded,
                                      onTap: !_ble.isRecording ? null : () => _ble.sendBleCommand("STOP"),
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
                                label: _ble.isScanning ? "Сканування..." : "Сканувати пристрої",
                                color: kCyanColor,
                                icon: Icons.search_rounded,
                                onTap: _ble.isScanning ? null : _ble.startScan,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_ble.isConnected) ...[
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
                                          Clipboard.setData(ClipboardData(text: _ble.logs.join("\n")));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Лог скопійовано"), backgroundColor: kCyanColor),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: kRedColor),
                                        onPressed: _ble.clearLogs,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 130,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                                child: ListView.builder(
                                  itemCount: _ble.logs.length,
                                  itemBuilder: (context, index) {
                                    final log = _ble.logs[index];
                                    final isTx = log.contains("[TX]");
                                    return Text(
                                      log,
                                      style: TextStyle(color: isTx ? kGreenColor : kCyanColor, fontSize: 11, fontFamily: 'monospace'),
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
                                        _ble.sendBleCommand(_cmdController.text.trim());
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

                      if (!_ble.isConnected) ...[
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

                        if (_ble.systemDevices.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, top: 4),
                            child: Text("Спарені в Android", style: TextStyle(color: kCyanColor, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          ..._ble.systemDevices.map((dev) {
                            final name = dev.platformName.isNotEmpty ? dev.platformName : "Bluetooth Device";
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                leading: const Icon(Icons.devices, color: kCyanColor),
                                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                subtitle: Text(dev.remoteId.str, style: const TextStyle(color: kSubColor, fontSize: 12)),
                                trailing: TextButton(
                                  onPressed: () => _ble.connectToDevice(dev, name),
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
                                title: Text(name, style: TextStyle(color: Colors.white, fontWeight: rawName.contains("Vector") ? FontWeight.bold : FontWeight.w600)),
                                subtitle: Text("$mac  ·  ${res.rssi} dBm", style: const TextStyle(color: kSubColor, fontSize: 12)),
                                trailing: TextButton(
                                  onPressed: () => _ble.connectToDevice(res.device, name),
                                  child: const Text("Підключити", style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            );
                          }),
                        ] else if (_ble.isScanning) ...[
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
