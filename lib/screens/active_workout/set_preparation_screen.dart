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
  int _step = 1; // 1 = Введення ваги/повторів, 2 = Калібрування
  bool _isWarmup = true;
  bool _autoReps = false; // За замовчуванням коліщатко активне
  int _selectedReps = 0;  // Коліщатко стоїть на 0
  late String _weight;

  bool _isWeightFocused = true;

  @override
  void initState() {
    super.initState();
    // Якщо вага не була передана — ставимо прочерки за замовчуванням
    _weight = (widget.initialWeight == '—' || widget.initialWeight == '0' || widget.initialWeight.isEmpty)
        ? '—'
        : widget.initialWeight;
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
    if (!_isWeightFocused) return;
    setState(() {
      // Якщо зараз стоять прочерки — очищаємо їх при першому натисканні цифри
      if (_weight == '—') {
        if (val == '.') return;
        _weight = val;
      } else {
        if (val == '.' && _weight.contains('.')) return;
        // Обмеження максимум 5 символів
        if (_weight.length < 5) {
          _weight += val;
        }
      }
    });
  }

  void _onBackspace() {
    if (!_isWeightFocused) return;
    if (_weight.isNotEmpty && _weight != '—') {
      setState(() {
        _weight = _weight.substring(0, _weight.length - 1);
        if (_weight.isEmpty) {
          _weight = '—';
        }
      });
    }
  }

  void _proceedToNextStep() {
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
        child: _step == 1 ? _buildStep1WeightAndRepsInput() : _buildStep2Calibration(),
      ),
    );
  }

  // ЕКРАН 1: Об'єднаний блок (Вага за замовчуванням '—', Коліщатко на 0, Кнопка далі)
  Widget _buildStep1WeightAndRepsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Шапка з індикатором стану датчика
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exerciseName,
                    style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Введіть вагу",
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Клікабельний плашка-статус датчика
              GestureDetector(
                onTap: () => context.go('/device'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kDarkCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ble.isConnected ? const Color(0xFF10B981).withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _ble.isConnected ? const Color(0xFF10B981) : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _ble.isConnected ? "85% • 12ms" : "Відключено",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Перемикач Warm up / Working set
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeTile("Warm up", "Розминка", _isWarmup, () => setState(() => _isWarmup = true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeTile("Working set", "Робочий підхід", !_isWarmup, () => setState(() => _isWarmup = false)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ГОЛОВНИЙ ПОЄДНАНИЙ БЛОК
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kDarkCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // 1. Введення ваги (Прочерки за замовчуванням + Курсор)
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () => setState(() => _isWeightFocused = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _isWeightFocused ? kDarkBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isWeightFocused ? kPurpleAccent : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Вага, кг", style: TextStyle(color: kSubTextColor, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _weight,
                              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                            if (_isWeightFocused)
                              Container(
                                width: 2,
                                height: 26,
                                margin: const EdgeInsets.only(left: 2),
                                color: kPurpleAccent,
                              ),
                            const SizedBox(width: 4),
                            const Text("kg", style: TextStyle(color: kSubTextColor, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Container(width: 1, height: 50, color: Colors.white10),
              const SizedBox(width: 8),

              // 2. Коліщатко повторів (Починається з 0)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Повтори", style: TextStyle(color: kSubTextColor, fontSize: 11)),
                        GestureDetector(
                          onTap: () => setState(() => _autoReps = !_autoReps),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _autoReps ? kPurpleAccent : Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Авто",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    SizedBox(
                      height: 46,
                      child: _autoReps
                          ? const Center(
                              child: Text(
                                "AUTO",
                                style: TextStyle(color: kPurpleAccent, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            )
                          : ListWheelScrollView.useDelegate(
                              itemExtent: 28,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() => _selectedReps = index);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 31, // Від 0 до 30
                                builder: (context, index) {
                                  final isSelected = index == _selectedReps;
                                  return Center(
                                    child: Text(
                                      "$index",
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : kSubTextColor,
                                        fontSize: isSelected ? 20 : 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 3. Фіолетова кнопка далі ->
              GestureDetector(
                onTap: _proceedToNextStep,
                child: Container(
                  width: 50,
                  height: 58,
                  decoration: BoxDecoration(
                    color: kPurpleAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Кастомна клавіатура
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildKeyboardRow(['1', '2', '3']),
              const SizedBox(height: 10),
              _buildKeyboardRow(['4', '5', '6']),
              const SizedBox(height: 10),
              _buildKeyboardRow(['7', '8', '9']),
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

  Widget _buildTypeTile(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPurpleAccent.withOpacity(0.18) : kDarkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPurpleAccent : Colors.white.withOpacity(0.06),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? kPurpleAccent : kSubTextColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : kSubTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: kSubTextColor, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ЕКРАН 2: Калібрування
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
                width: 12,
                height: 12,
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
            "${_isWarmup ? "Розминка" : "Робочий підхід"} • ${_weight == '—' ? '0' : _weight} kg (${_autoReps ? "AUTO" : "$_selectedReps reps"})",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'weight': _weight == '—' ? '0' : _weight,
                  'isWarmup': _isWarmup,
                  'reps': _autoReps ? 'AUTO' : '$_selectedReps',
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildKeyboardRow(List<String> keys) {
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
