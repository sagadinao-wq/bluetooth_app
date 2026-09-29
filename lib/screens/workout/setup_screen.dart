import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../services/ble_service.dart';

class SetupScreen extends StatefulWidget {
  final String exercise;
  const SetupScreen({super.key, this.exercise = 'Жим'});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _exercises = const ['Жим', 'Присід', 'Станова', 'Інша'];
  int _selectedExercise = 0;
  
  // Тип підходу: true - Робочий (Working set), false - Розминка (Warm up)
  bool _isWorkingSet = true; 
  String _weight = '0'; // Стартова вага 0

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
      if (val == '.') {
        // Додаємо крапку тільки якщо її ще немає
        if (!_weight.contains('.')) {
          _weight += '.';
        }
      } else {
        if (_weight == '0' && val != '.') {
          _weight = val;
        } else if (_weight.length < 6) { // Збільшено ліміт під дробові ваги (напр. 175.5)
          _weight += val;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхня панель: Заголовок + Клікабельний великий кружечок статусу BLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Налаштування підходу",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go('/device'); // Перехід у меню приладу для підключення
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _ble.isConnected ? kGreenColor : kRedColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_ble.isConnected ? kGreenColor : kRedColor).withOpacity(0.5),
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
              const SizedBox(height: 14),

              // 1. Перемикач вправ (Жим, Присід, Станова, Інша)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_exercises.length, (i) {
                    final active = i == _selectedExercise;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_exercises[i]),
                        selected: active,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedExercise = i);
                        },
                        selectedColor: kCyanColor,
                        backgroundColor: kCardColor,
                        labelStyle: TextStyle(
                          color: active ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Перемикач типу підходу
              Row(
                children: [
                  Expanded(
                    child: _setTypeButton(
                      label: "Warm up",
                      subLabel: "Розминка",
                      isSelected: !_isWorkingSet,
                      onTap: () => setState(() => _isWorkingSet = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _setTypeButton(
                      label: "Working set",
                      subLabel: "Робочий підхід",
                      isSelected: _isWorkingSet,
                      onTap: () => setState(() => _isWorkingSet = true),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 3. Табло вводу ваги + Кнопка "Далі" СПРАВА
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Табло ваги
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _weight,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52, // Трохи зменшено шрифт для комфортного розташування дробових чисел
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "кг",
                          style: TextStyle(
                            color: kSubColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Кнопка "Далі" справа
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCyanColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        context.push(
                          '/workout/calibrate',
                          extra: {
                            'exercise': _exercises[_selectedExercise],
                            'setType': _isWorkingSet ? 'Working set' : 'Warm up',
                            'weight': _weight,
                          },
                        );
                      },
                      child: const Row(
                        children: [
                          Text("Далі", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Клавіатура з кнопкою '.' замість 'C'
              Expanded(
                flex: 5,
                child: _buildKeypad(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setTypeButton({
    required String label,
    required String subLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? kCyanColor : kCardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kCyanColor : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(
                color: isSelected ? Colors.black87 : kSubColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'] // Замість 'C' стоїть крапка '.'
    ];

    return Column(
      children: keys.map((row) {
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Material(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
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
                      child: Center(
                        child: Text(
                          key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
