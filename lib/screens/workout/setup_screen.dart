import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SetupScreen extends StatefulWidget {
  final String exercise;
  const SetupScreen({super.key, this.exercise = 'Жим'});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _exercises = const ['Жим', 'Присід', 'Станова'];
  int _selectedExercise = 0;
  
  // Тип підходу: true - Робочий (Working set), false - Розминка (Warm up)
  bool _isWorkingSet = true; 
  String _weight = '60';

  @override
  void initState() {
    super.initState();
    final idx = _exercises.indexOf(widget.exercise);
    if (idx != -1) _selectedExercise = idx;
  }

  void _onKeyPress(String val) {
    setState(() {
      if (val == 'C') {
        _weight = '0';
      } else {
        if (_weight == '0') {
          _weight = val;
        } else if (_weight.length < 3) {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(
                title: "Налаштування підходу",
                statusText: "Підключено",
                statusColor: kGreenColor,
              ),
              const SizedBox(height: 16),

              // 1. Перемикач вправ
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
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

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

              // 3. Табло вводу ваги
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _weight,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "кг",
                      style: TextStyle(
                        color: kSubColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Цифрова клавіатура
              _buildKeypad(),

              const SizedBox(height: 16),

              // 5. Кнопка "Далі"
              PrimaryButton(
                label: "Далі",
                color: kCyanColor,
                icon: Icons.arrow_forward_rounded,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? kCyanColor : kCardColor,
          borderRadius: BorderRadius.circular(14),
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
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: TextStyle(
                color: isSelected ? Colors.black87 : kSubColor,
                fontSize: 11,
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
      ['C', '0', '⌫']
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            return InkWell(
              onTap: () {
                if (key == '⌫') {
                  setState(() {
                    if (_weight.length > 1) {
                      _weight = _weight.substring(0, _weight.length - 1);
                    } else {
                      _weight = '0';
                    }
                  });
                } else {
                  _onKeyPress(key);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: 75,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
