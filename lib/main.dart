import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const MyApp());

// ===== палітра, та сама що й на попередньому макеті =====
const _bg = Color(0xFF0A0A0A);
const _card = Color(0xFF1C1C1E);
const _card2 = Color(0xFF232325);
const _sub = Color(0xFF8E8E93);
const _red = Color(0xFFFF3B4E);
const _green = Color(0xFF32D74B);
const _divider = Color(0xFF2C2C2E);

// шлях до фото береться з назви вправи; файли лежать в assets/exercises/
const Map<String, String> _exerciseImages = {
  'Жим': 'assets/exercises/bench.jpg',
  'Присід': 'assets/exercises/squat.jpg',
  'Станова': 'assets/exercises/deadlift.jpg',
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: _bg),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/setup':
            page = const SetupScreen();
            break;
          case '/calibrate':
            page = SetupData.of(settings.arguments);
            break;
          default:
            page = const DeviceScreen();
        }
        return _fadeSlideRoute(page, settings);
      },
      initialRoute: '/',
    );
  }
}

Route _fadeSlideRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// маленький хелпер, щоб передати дані вправи/ваги в екран калібрування через onGenerateRoute
class SetupData {
  static Widget of(Object? args) {
    final m = args as Map<String, dynamic>;
    return CalibrationScreen(exercise: m['exercise'], weight: m['weight']);
  }
}

// ===== спільні дрібні віджети =====

class _TopBar extends StatelessWidget {
  final String title;
  final String? statusText;
  final Color? statusColor;
  const _TopBar({required this.title, this.statusText, this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop())
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _RoundIconButton(icon: Icons.chevron_left, onTap: () => Navigator.of(context).pop()),
              ),
            Text(title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white)),
          ],
        ),
        if (statusText != null)
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(statusText!, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  const _PrimaryButton({required this.label, required this.onTap, this.color = Colors.white, this.icon});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color : _card2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: enabled ? Colors.black : _sub),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: enabled ? Colors.black : _sub)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 1. Вибір пристрою =====

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _scanning = true;
  final List<String> _found = [];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _found.addAll(['Gpath Pin — 7A:3F', 'Gpath Pin — C1:09']);
        _scanning = false;
      });
    });
  }

  void _connect(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    Timer(const Duration(milliseconds: 700), () {
      Navigator.of(context).pop(); // закрити діалог
      Navigator.of(context).pushNamed('/setup', arguments: {'device': name});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(title: "Підключення"),
              const SizedBox(height: 8),
              const Text("Знайдені пристрої поруч", style: TextStyle(color: _sub, fontSize: 14)),
              const SizedBox(height: 24),
              if (_scanning)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(children: [
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                      SizedBox(height: 16),
                      Text("Пошук...", style: TextStyle(color: _sub)),
                    ]),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _found.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => Material(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _connect(_found[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(_found[i],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                              const Icon(Icons.chevron_right, color: Color(0xFF5A5A5E), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 2. Прикріпіть на штангу + вправа + вага =====

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final device = args?['device'] as String? ?? 'Gpath Pin';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(title: "Підготовка", statusText: "Підключено", statusColor: _green),
              const SizedBox(height: 4),
              Text(device, style: const TextStyle(color: _sub, fontSize: 13)),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: const [
                    Icon(Icons.fit_screen_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Прикріпіть пристрій на гриф штанги",
                        style: TextStyle(fontSize: 15, color: Color(0xFFD1D1D6), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text("Вправа", style: TextStyle(color: _sub, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(_exercises.length, (i) {
                  final active = i == _selected;
                  final name = _exercises[i];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _exercises.length - 1 ? 10 : 0),
                      child: Material(
                        color: active ? Colors.white : _card,
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
                                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                                    clipBehavior: Clip.antiAlias,
                                    child: ColorFiltered(
                                      colorFilter: active
                                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                          : const ColorFilter.matrix(<double>[
                                              0.2126, 0.7152, 0.0722, 0, 0,
                                              0.2126, 0.7152, 0.0722, 0, 0,
                                              0.2126, 0.7152, 0.0722, 0, 0,
                                              0, 0, 0, 1, 0,
                                            ]),
                                      child: Image.asset(_exerciseImages[name]!, fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: active ? Colors.black : Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),
              const Text("Вага, кг", style: TextStyle(color: _sub, fontSize: 14)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 16)),
                ),
              ),

              const Spacer(),
              _PrimaryButton(
                label: "Далі",
                onTap: () {
                  Navigator.of(context).pushNamed('/calibrate', arguments: {
                    'exercise': _exercises[_selected],
                    'weight': _weightCtrl.text,
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 3. Калібрування =====

class CalibrationScreen extends StatefulWidget {
  final String exercise;
  final String weight;
  const CalibrationScreen({super.key, required this.exercise, required this.weight});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _calibrating = false;
  bool _done = false;

  void _calibrate() {
    setState(() => _calibrating = true);
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _calibrating = false;
        _done = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(title: "Калібрування"),
              const SizedBox(height: 4),
              Text("${widget.exercise} · ${widget.weight} кг", style: const TextStyle(color: _sub, fontSize: 13)),
              const Spacer(),

              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                  child: _done
                      ? Container(
                          key: const ValueKey('done'),
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.black, size: 56),
                        )
                      : Container(
                          key: const ValueKey('idle'),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _card,
                            shape: BoxShape.circle,
                            border: Border.all(color: _divider, width: 2),
                          ),
                          child: _calibrating
                              ? const Padding(
                                  padding: EdgeInsets.all(28),
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                )
                              : const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 44),
                        ),
                ),
              ),

              const SizedBox(height: 28),
              Text(
                _done ? "Калібровка завершена" : "Поставте штангу на підлогу або бокс і не рухайте нею",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _done ? _green : const Color(0xFFD1D1D6),
                    fontSize: 16,
                    fontWeight: _done ? FontWeight.w700 : FontWeight.w400,
                    height: 1.4),
              ),

              const Spacer(),
              _PrimaryButton(
                label: _done ? "Почати підхід" : (_calibrating ? "Калібрування..." : "Калібрувати"),
                color: _done ? _green : Colors.white,
                onTap: _calibrating
                    ? null
                    : (_done
                        ? () => Navigator.of(context).push(_fadeSlideRoute(
                              RecordingScreen(exercise: widget.exercise, weight: widget.weight),
                              const RouteSettings(name: '/record'),
                            ))
                        : _calibrate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 4. Запис підходу =====

class RecordingScreen extends StatefulWidget {
  final String exercise;
  final String weight;
  const RecordingScreen({super.key, required this.exercise, required this.weight});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _recording = false;
  int _elapsedMs = 0;
  int _samples = 0;
  Timer? _timer;

  void _start() {
    setState(() {
      _recording = true;
      _elapsedMs = 0;
      _samples = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _elapsedMs += 50;
        _samples += 5; // імітація ~100 Гц потоку з пристрою
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _recording = false);
    Navigator.of(context).push(_fadeSlideRoute(
      SummaryScreen(exercise: widget.exercise, weight: widget.weight, durationMs: _elapsedMs, samples: _samples),
      const RouteSettings(name: '/summary'),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_elapsedMs / 1000).toStringAsFixed(1);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(title: "Запис", statusText: _recording ? "Йде запис" : "Готово", statusColor: _recording ? _red : _sub),
              const SizedBox(height: 4),
              Text("${widget.exercise} · ${widget.weight} кг", style: const TextStyle(color: _sub, fontSize: 13)),
              const SizedBox(height: 18),
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18)),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(_exerciseImages[widget.exercise]!, fit: BoxFit.contain),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Text("$seconds с",
                        style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
                    const SizedBox(height: 8),
                    Text("$_samples відліків", style: const TextStyle(color: _sub, fontSize: 15)),
                  ],
                ),
              ),
              const Spacer(),
              _PrimaryButton(
                label: _recording ? "Завершити підхід" : "Почати запис",
                color: _recording ? _red : Colors.white,
                onTap: _recording ? _stop : _start,
                icon: _recording ? Icons.stop_rounded : Icons.fiber_manual_record,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 5. Підсумок =====

class SummaryScreen extends StatelessWidget {
  final String exercise;
  final String weight;
  final int durationMs;
  final int samples;
  const SummaryScreen({
    super.key,
    required this.exercise,
    required this.weight,
    required this.durationMs,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = (durationMs / 1000).toStringAsFixed(1);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Підхід завершено",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                  _RoundIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).popUntil((r) => r.settings.name == '/setup'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _row("Вправа", exercise),
                    const Divider(height: 1, color: _divider, indent: 20, endIndent: 20),
                    _row("Вага", "$weight кг"),
                    const Divider(height: 1, color: _divider, indent: 20, endIndent: 20),
                    _row("Тривалість", "$seconds с"),
                    const Divider(height: 1, color: _divider, indent: 20, endIndent: 20),
                    _row("Відліків записано", "$samples"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Аналіз повторів і швидкості порахуємо пізніше — зараз зберігаються тільки сирі дані з пристрою.",
                style: TextStyle(color: _sub, fontSize: 13, height: 1.4),
              ),
              const Spacer(),
              _PrimaryButton(
                label: "Завантажити файл",
                icon: Icons.download_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Файл збережено"), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _sub, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
