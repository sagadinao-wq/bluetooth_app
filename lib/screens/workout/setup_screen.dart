import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ble_service.dart';

// Акцентні кольори під оригінальний дизайн
const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class SetupScreen extends StatefulWidget {
  final String exercise;
  const SetupScreen({super.key, this.exercise = 'Станова тяга'});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _exercises = const ['Жим лежачи', 'Присідання', 'Станова тяга', 'Інша вправа'];
  int _selectedExercise = 2; // Станова тяга за замовчуванням
  
  // Тип підходу: false - Розминка (Warm up), true - Робочий підхід (Working set)
  bool _isWorkingSet = true; 
  String _weight = '170'; // Початкове значення для демонстрації

  final BleService _ble = BleService();

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onBleUpdate);
    final idx = _exercises.indexOf(widget.exercise);
    if (idx != -1) _selectedExercise = idx;
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
      if (val == '.' || val == ',') {
        if (!_weight.contains('.') && _weight.length < 5) {
          _weight += '.';
        }
      } else {
        if (_weight == '0' && val != '.') {
          _weight = val;
        } else if (_weight.length < 5) { // Обмеження в 5 символів
          _weight += val;
        }
      }
    });
  }

  bool get _hasValidWeight {
    final parsed = double.tryParse(_weight) ?? 0;
    return parsed > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Верхня панель зі збереженим статусом підключення BLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _exercises[_selectedExercise],
                        style: const TextStyle(color: kSubTextColor, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Введіть вагу",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
              const SizedBox(height: 6),

              const Text(
                "Оберіть тип підходу для оцінки вашої готовності.",
                style: TextStyle(color: kSubTextColor, fontSize: 12, height: 1.3),
              ),
              const SizedBox(height: 16),

              // 2. Типи підходу (Тільки 2 сети: Розминка / Робочий підхід)
              Row(
                children: [
                  Expanded(
                    child: _buildRadioSetTile(
                      title: "Warm up",
                      subtitle: "Розминка",
                      isSelected: !_isWorkingSet,
                      onTap: () => setState(() => _isWorkingSet = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRadioSetTile(
                      title: "Working set",
                      subtitle: "Робочий підхід",
                      isSelected: _isWorkingSet,
                      onTap: () => setState(() => _isWorkingSet = true),
                    ),
                  ),
                ],
              ),

              // 3. Центральна зона: Введення ваги та кнопка "Далі"
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kDarkCardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Показник ваги з миготливим курсором
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _weight,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Вертикальна риска курсору
                            Container(
                              margin: const EdgeInsets.only(left: 2, right: 8),
                              width: 2,
                              height: 42,
                              color: kPurpleAccent,
                            ),
                            const Text(
                              "kg",
                              style: TextStyle(
                                color: Color(0xFF3A3A4C),
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // Фіолетова кнопка "Далі" (з'являється при вазі > 0)
                        if (_hasValidWeight)
                          InkWell(
                            onTap: () {
                              context.push(
                                '/workout/calibrate',
                                extra: {
                                  'exercise': _exercises[_selectedExercise],
                                  'setType': _isWorkingSet ? 'Working set' : 'Warm up',
                                  'weight': _weight,
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 72,
                              height: 120,
                              decoration: BoxDecoration(
                                color: kPurpleAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Стилізована клавіатура
              SizedBox(
                height: 240,
                child: _buildCustomKeypad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Віджет картки вибору типу підходу
  Widget _buildRadioSetTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: kDarkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPurpleAccent.withOpacity(0.6) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kPurpleAccent : kSubTextColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPurpleAccent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: kSubTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Віджет клавіатури
  Widget _buildCustomKeypad() {
    final keys = [
      [
        {'num': '1', 'sub': },
        {'num': '2', 'sub': },
        {'num': '3', 'sub': }
      ],
      [
        {'num': '4', 'sub': },
        {'num': '5', 'sub': },
        {'num': '6', 'sub': }
      ],
      [
        {'num': '7', 'sub': },
        {'num': '8', 'sub': },
        {'num': '9', 'sub': }
      ],
      [
        {'num': ',', 'sub': },
        {'num': '0', 'sub': },
        {'num': '⌫', 'sub': }
      ],
    ];

    return Column(
      children: keys.map((row) {
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: row.map((item) {
              final key = item['num']!;
              final sub = item['sub']!;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Material(
                    color: kDarkCardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (key == '⌫') {
                          setState(() {
                            if (_weight.length > 1) {
                              _weight = _weight.substring(0, _weight.length - 1);
                              if (_weight.isEmpty) _weight = '0';
                            } else {
                              _weight = '0';
                            }
                          });
                        } else {
                          _onKeyPress(key);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub,
                              style: const TextStyle(
                                color: kSubTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
