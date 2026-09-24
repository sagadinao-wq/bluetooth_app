import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _exercises = const ['Жим', 'Присід', 'Станова'];
  int _selected = 0;
  final _weightCtrl = TextEditingController(text: '60');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(
                title: "Підготовка",
                statusText: "Підключено",
                statusColor: kGreenColor,
              ),
              const SizedBox(height: 4),
              const Text(
                "Vector Pin — 7A:3F",
                style: TextStyle(color: kSubColor, fontSize: 13),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.fit_screen_rounded, color: kCyanColor, size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Прикріпіть пристрій на гриф штанги",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFD1D1D6),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text("Вправа", style: TextStyle(color: kSubColor, fontSize: 14)),
              const SizedBox(height: 12),

              Row(
                children: List.generate(_exercises.length, (i) {
                  final active = i == _selected;
                  final name = _exercises[i];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < _exercises.length - 1 ? 10 : 0,
                      ),
                      child: Material(
                        color: active ? kCyanColor : kCardColor,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _selected = i),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      kExerciseImages[name] ?? 'assets/exercises/bench.jpg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: active ? Colors.black : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),
              const Text("Вага, кг", style: TextStyle(color: kSubColor, fontSize: 14)),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const Spacer(),
              PrimaryButton(
                label: "Перейти до калібрування",
                color: kCyanColor,
                onTap: () {
                  context.push(
                    '/workout/calibrate',
                    extra: {
                      'exercise': _exercises[_selected],
                      'weight': _weightCtrl.text,
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
}
