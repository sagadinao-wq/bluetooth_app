import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ble_service.dart';

// Ті самі кольори, що й на 1-му екрані
const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class CalibrationScreen extends StatefulWidget {
  final String exercise;
  final String setType;
  final String weight;

  const CalibrationScreen({
    super.key,
    required this.exercise,
    required this.setType,
    required this.weight,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final BleService _ble = BleService();

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onBleUpdate);
  }

  @override
  void dispose() {
    _ble.removeListener(_onBleUpdate);
    super.dispose();
  }

  void _onBleUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Плавний темно-фіолетовий градієнт на фоні
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF230B48), // М'яке фіолетове світіння зверху
              kDarkBg,
              kDarkBg,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Верхня панель: Назад + Округлений бейдж + Індикатор BLE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка Назад
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kDarkCardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),

                    // Округлена фіолетова плашка зверху
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPurpleAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kPurpleAccent.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, color: kPurpleAccent, size: 14),
                          SizedBox(width: 6),
                          Text(
                            "Інструкція підготовки",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Світловий кружечок статусу BLE
                    GestureDetector(
                      onTap: () => context.go('/device'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _ble.isConnected ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                            boxShadow: [
                              BoxShadow(
                                color: (_ble.isConnected ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Інформація про обрану вправу та вагу
                Text(
                  widget.exercise,
                  style: const TextStyle(color: kSubTextColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  "${widget.setType == 'Working set' ? 'Робочий підхід' : 'Розминка'} · ${widget.weight} kg",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 2. Центральна зона: Сувора текстова підказка
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: kDarkCardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: kPurpleAccent.withOpacity(0.3), width: 1.5),
                            ),
                            child: const Icon(
                              Icons.phonelink_setup_rounded,
                              color: kPurpleAccent,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Закріпіть сенсор на штанзі",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Переконайтеся, що штанга знаходиться в нерухомому положенні у вихідній точці перед початком підходу.",
                            style: TextStyle(
                              color: kSubTextColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Нижня сувора фіолетова кнопка розстарту
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurpleAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // Відправляємо команди автокалібрування та старт на ESP32
                      _ble.sendBleCommand("TARE");
                      _ble.sendBleCommand("START");

                      context.go(
                        '/workout/record',
                        extra: {
                          'exercise': widget.exercise,
                          'setType': widget.setType,
                          'weight': widget.weight,
                        },
                      );
                    },
                    child: const Text(
                      "Калібрувати та розпочати підхід",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
