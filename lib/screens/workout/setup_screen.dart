import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';

class SetupScreen extends StatefulWidget {
  final String exercise;
  const SetupScreen({super.key, this.exercise = 'Жим лежачи'});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _setType = 'Working set'; // 'Warm up' або 'Working set'
  String _weight = '100';

  void _onKeyPress(String val) {
    setState(() {
      if (val == 'C') {
        _weight = '0';
      } else {
        if (_weight == '0') {
          _weight = val;
        } else if (_weight.length < 4) {
          _weight += val;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Text(widget.exercise, style: const TextStyle(color: kSubColor, fontSize: 16)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Введіть вагу", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Перемикач типу підходу: Розминка / Робочий
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Розминка")),
                      selected: _setType == 'Warm up',
                      onSelected: (selected) {
                        if (selected) setState(() => _setType = 'Warm up');
                      },
                      selectedColor: kCyanColor,
                      backgroundColor: kCardColor,
                      labelStyle: TextStyle(color: _setType == 'Warm up' ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Робочий підхід")),
                      selected: _setType == 'Working set',
                      onSelected: (selected) {
                        if (selected) setState(() => _setType = 'Working set');
                      },
                      selectedColor: kCyanColor,
                      backgroundColor: kCardColor,
                      labelStyle: TextStyle(color: _setType == 'Working set' ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Відображення введеної ваги
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(_weight, style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Text("кг", style: TextStyle(color: kSubColor, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),

              const Spacer(),

              // Клавіатура введення ваги
              _buildKeypad(),

              const SizedBox(height: 16),

              // Кнопка далі
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyanColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    context.go('/workout/calibrate', extra: {
                      'exercise': widget.exercise,
                      'setType': _setType,
                      'weight': _weight,
                    });
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Далі", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 22),
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
              borderRadius: BorderRadius.circular(40),
              child: Container(
                margin: const EdgeInsets.all(6),
                width: 70,
                height: 55,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(key, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
