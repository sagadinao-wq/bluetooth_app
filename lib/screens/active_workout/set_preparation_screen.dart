import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ble_service.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class SetPreparationScreen extends StatefulWidget {
  final String exerciseName;
  final String initialWeight;

  const SetPreparationScreen({
    super.key,
    required this.exerciseName,
    required this.initialWeight,
  });

  @override
  State<SetPreparationScreen> createState() => _SetPreparationScreenState();
}

class _SetPreparationScreenState extends State<SetPreparationScreen> {
  final BleService _ble = BleService();
  int _step = 1; // 1 = Введення ваги, 2 = Калібрування
  bool _isWarmup = true;
  bool _autoReps = true;
  String _targetReps = '8';
  late String _weight;

  @override
  void initState() {
    super.initState();
    _weight = (widget.initialWeight == '—' || widget.initialWeight == '0') ? '100.7' : widget.initialWeight;
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

  void _onKeyPress(String val) {
    setState(() {
      if (val == '.' && _weight.contains('.')) return;
      _weight += val;
    });
  }

  void _onBackspace() {
    if (_weight.isNotEmpty) {
      setState(() {
        _weight = _weight.substring(0, _weight.length - 1);
      });
    }
  }

  void _proceedToNextStep() {
    // Перевіряємо стан підключення приладу
    if (!_ble.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Прилад не підключено! Перехід у меню приладу..."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/device');
      return;
    }
    setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: _step == 1 ? _buildStep1WeightInput() : _buildStep2Calibration(),
      ),
    );
  }

  // ЕКРАН 1: Введення ваги підходу (Точне відтворення за скріншотом)
  Widget _buildStep1WeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Верхня панель з назвою вправи та індикатором BLE
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exerciseName,
                    style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Введіть вагу",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Оберіть тип підходу для оцінки вашої готовності.",
                    style: TextStyle(color: kSubTextColor, fontSize: 12),
                  ),
                ],
              ),
              // Індикатор підключення BLE (Зелена / Червона крапка)
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Перемикач типу підходу: Warm up / Working set
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isWarmup = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isWarmup ? kPurpleAccent.withOpacity(0.18) : kDarkCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isWarmup ? kPurpleAccent : Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isWarmup ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: _isWarmup ? kPurpleAccent : kSubTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Warm up",
                              style: TextStyle(
                                color: _isWarmup ? Colors.white : kSubTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              "Розминка",
                              style: TextStyle(color: kSubTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isWarmup = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isWarmup ? kPurpleAccent.withOpacity(0.18) : kDarkCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !_isWarmup ? kPurpleAccent : Colors.white.withOpacity(0.06),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          !_isWarmup ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: !_isWarmup ? kPurpleAccent : kSubTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Working set",
                              style: TextStyle(
                                color: !_isWarmup ? Colors.white : kSubTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              "Робочий підхід",
                              style: TextStyle(color: kSubTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Налаштування вимірювання повторів
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: kDarkCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.autorenew_rounded, color: kPurpleAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _autoReps ? "Автовизначення повторів" : "Цільові повтори: $_targetReps",
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Switch(
                  value: _autoReps,
                  activeColor: kPurpleAccent,
                  onChanged: (val) => setState(() => _autoReps = val),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Поле підсумкового табло ваги
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: kDarkCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossBaseline.alphabetic,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _weight.isEmpty ? '0' : _weight,
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "kg",
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _proceedToNextStep,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: kPurpleAccent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kPurpleAccent.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Кастомна цифрова клавіатура
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 10),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 10),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 10),
              Row(
                children: [
                  _btn('.', onTap: () => _onKeyPress('.')),
                  const SizedBox(width: 10),
                  _btn('0', onTap: () => _onKeyPress('0')),
                  const SizedBox(width: 10),
                  _btn('', icon: Icons.backspace_outlined, onTap: _onBackspace),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ЕКРАН 2: Калібрування та закріплення сенсора (Точне відтворення за скріншотом)
  Widget _buildStep2Calibration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: kDarkCardBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: kPurpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPurpleAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: kPurpleAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Інструкція підготовки",
                      style: TextStyle(color: kPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            widget.exerciseName,
            style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            "${_isWarmup ? "Розминка" : "Робочий підхід"} • $_weight kg",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          // Анімаційний елемент сенсора
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: kPurpleAccent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: kPurpleAccent.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.phonelink_setup_rounded,
              color: kPurpleAccent,
              size: 60,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "Закріпіть сенсор на штанзі",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Переконайтеся, що штанга знаходиться в нерухомому положенні у вихідній точці перед початком підходу.",
              textAlign: TextAlign.center,
              style: TextStyle(color: kSubTextColor, fontSize: 13, height: 1.4),
            ),
          ),
          const Spacer(),

          // Кнопка Калібрувати та розпочати підхід
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'weight': _weight,
                  'isWarmup': _isWarmup,
                  'reps': _autoReps ? '8' : _targetReps,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: const Text(
                "Калібрувати та розпочати підхід",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((k) => _btn(k, onTap: () => _onKeyPress(k))).toList(),
    );
  }

  Widget _btn(String text, {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: kDarkCardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, color: Colors.white, size: 22)
                  : Text(text, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
