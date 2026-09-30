import 'package:flutter/material.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);

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
  int _step = 1; // 1 = Введення ваги, 2 = Калібрування сенсора
  bool _isWarmup = false;
  late String _weight;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight == '—' ? '100' : widget.initialWeight;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: _step == 1 ? _buildStep1WeightInput() : _buildStep2Calibration(),
      ),
    );
  }

  // Крок 1: Введення ваги підходу (Скріншот 1)
  Widget _buildStep1WeightInput() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.exerciseName, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                const SizedBox(height: 4),
                const Text("Введіть вагу", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        // Перемикач Розминка / Робочий підхід
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isWarmup = true),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isWarmup ? kPurpleAccent.withOpacity(0.2) : kDarkCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _isWarmup ? kPurpleAccent : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Warm up", style: TextStyle(color: _isWarmup ? kPurpleAccent : Colors.white, fontWeight: FontWeight.bold)),
                        const Text("Розминка", style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: !_isWarmup ? kPurpleAccent.withOpacity(0.2) : kDarkCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: !_isWarmup ? kPurpleAccent : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Working set", style: TextStyle(color: !_isWarmup ? kPurpleAccent : Colors.white, fontWeight: FontWeight.bold)),
                        const Text("Робочий підхід", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Головне табло з вагою
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kDarkCardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(_weight.isEmpty ? '0' : _weight, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Text("kg", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 22)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _step = 2),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kPurpleAccent, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Клавіатура
        Container(
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

  // Крок 2: Калібрування та закріплення сенсора (Скріншот 2)
  Widget _buildStep2Calibration() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.exerciseName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            "${_isWarmup ? "Розминка" : "Робочий підхід"} • $_weight kg",
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          // Анімаційна іконка сенсора
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kPurpleAccent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: kPurpleAccent.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.phonelink_setup_rounded, color: kPurpleAccent, size: 64),
          ),
          const SizedBox(height: 24),
          const Text(
            "Закріпіть сенсор на штанзі",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Переконайтеся, що штанга знаходиться в нерухомому положенні у вихідній точці перед початком підходу.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Spacer(),

          // Головна кнопка запуску
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({'weight': _weight, 'isWarmup': _isWarmup});
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
