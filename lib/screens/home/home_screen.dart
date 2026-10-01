import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ble_service.dart';
import '../../services/database_service.dart';
import '../profile/profile_drawer_screen.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCalendarExpanded = false;

  late DateTime _today;
  late DateTime _selectedDate;

  late PageController _weekPageController;
  late PageController _monthPageController;

  final List<String> _monthsUa = [
    'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
    'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'
  ];

  final List<String> _weekDaysUa = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'];

  final BleService _ble = BleService();
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _selectedDate = DateTime(_today.year, _today.month, _today.day);

    _weekPageController = PageController(initialPage: 1000);
    _monthPageController = PageController(initialPage: 1000);

    _ble.addListener(_onBleUpdate);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _monthPageController.dispose();
    _ble.removeListener(_onBleUpdate);
    super.dispose();
  }

  void _onBleUpdate() {
    if (mounted) setState(() {});
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Повернення до сьогоднішнього дня
  void _resetToToday() {
    setState(() {
      _selectedDate = DateTime(_today.year, _today.month, _today.day);
    });
    if (_weekPageController.hasClients) {
      _weekPageController.animateToPage(
        1000,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    if (_monthPageController.hasClients) {
      _monthPageController.animateToPage(
        1000,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Плавне відкриття екрана профілю зліва
  void _openProfileDrawer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileDrawerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Початок зліва
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _onWeekPageChanged(int pageIndex) {
    final pageOffset = pageIndex - 1000;
    final currentMonday = _today.subtract(Duration(days: _today.weekday - 1)).add(Duration(days: pageOffset * 7));
    final midWeekDay = currentMonday.add(const Duration(days: 3));

    if (midWeekDay.month != _selectedDate.month || midWeekDay.year != _selectedDate.year) {
      setState(() {
        _selectedDate = DateTime(
          midWeekDay.year,
          midWeekDay.month,
          _selectedDate.day.clamp(1, DateUtils.getDaysInMonth(midWeekDay.year, midWeekDay.month)),
        );
      });
    }
  }

  void _onMonthPageChanged(int pageIndex) {
    final pageOffset = pageIndex - 1000;
    final targetMonth = DateTime(_today.year, _today.month + pageOffset, 1);

    setState(() {
      _selectedDate = DateTime(
        targetMonth.year,
        targetMonth.month,
        _selectedDate.day.clamp(1, DateUtils.getDaysInMonth(targetMonth.year, targetMonth.month)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _dbService.getUserWorkouts(),
          builder: (context, snapshot) {
            final workouts = snapshot.data ?? [];

            // Формуємо сет днів, коли були тренування, з бази даних
            final Set<int> workoutDays = {};
            for (var w in workouts) {
              if (w['createdAt'] != null) {
                final date = (w['createdAt'] as dynamic).toDate();
                if (date.month == _selectedDate.month && date.year == _selectedDate.year) {
                  workoutDays.add(date.day);
                }
              }
            }

            return Column(
              children: [
                // 1. Верхня панель з інтерактивним календарем
                _buildCalendarHeader(workoutDays),

                // 2. Основна стрічка з карткою старту та реальною історією
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSameDay(_selectedDate, _today)
                              ? "Обрана дата: Сьогодні"
                              : "Обрана дата: ${_selectedDate.day} ${_monthsUa[_selectedDate.month - 1].toLowerCase()}",
                          style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),

                        // Картка швидкого старту
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await Future.delayed(const Duration(milliseconds: 60));
                              if (context.mounted) {
                                context.go('/workout');
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF231A3D),
                                    kDarkCardBg,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kPurpleAccent.withOpacity(0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPurpleAccent.withOpacity(0.15),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kPurpleAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: kPurpleAccent.withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Готові до тренування?",
                                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          "Оберіть вправу та почніть запис підходу",
                                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          "Історія тренувань",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Динамічний список тренувань із Firestore замість муляжів
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(color: kPurpleAccent),
                            ),
                          )
                        else if (workouts.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: kDarkCardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.history_toggle_off_rounded, color: kSubTextColor.withOpacity(0.5), size: 48),
                                const SizedBox(height: 10),
                                const Text(
                                  "Немає збережених тренувань",
                                  style: TextStyle(color: kSubTextColor, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: workouts.length,
                            itemBuilder: (context, index) {
                              final item = workouts[index];
                              final exercises = (item['exercises'] as List?) ?? [];
                              final time = item['formattedTime'] ?? '00:00';

                              // Обчислення об'єму та підходів
                              int totalVolume = 0;
                              int totalSets = 0;
                              for (var ex in exercises) {
                                final sets = (ex['sets'] as List?) ?? [];
                                totalSets += sets.length;
                                for (var s in sets) {
                                  if (s['isCompleted'] == true) {
                                    final w = int.tryParse(s['weight']?.toString() ?? '') ?? 0;
                                    final r = int.tryParse(s['reps']?.toString() ?? '') ?? 0;
                                    totalVolume += w * r;
                                  }
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: _buildWorkoutRealCard(
                                  title: exercises.isNotEmpty ? exercises.map((e) => e['name']).join(', ') : "Тренування",
                                  date: "${_selectedDate.day} ${_monthsUa[_selectedDate.month - 1]}",
                                  volume: "$totalVolume кг",
                                  setsCount: "$totalSets підходів",
                                  time: time,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Блок календаря з лівою та правою кнопками
  Widget _buildCalendarHeader(Set<int> workoutDays) {
    final monthName = _monthsUa[_selectedDate.month - 1];
    final isNotToday = !_isSameDay(_selectedDate, _today);

    return Container(
      decoration: const BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Шапка: [Профіль Ліворуч] --- [Назва місяця] --- [Сьогодні Праворуч]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _openProfileDrawer,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kDarkBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPurpleAccent.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                  ),
                ),

                // Назва місяця
                GestureDetector(
                  onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                  child: Text(
                    monthName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(
                  width: 36,
                  height: 36,
                  child: isNotToday
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: _resetToToday,
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kPurpleAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: kPurpleAccent),
                            ),
                            child: const Icon(Icons.today_rounded, color: kPurpleAccent, size: 18),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Перемикання: Згорнутий тиждень АБО Повний календар місяця
          _isCalendarExpanded
              ? SizedBox(
                  height: 280,
                  child: PageView.builder(
                    controller: _monthPageController,
                    onPageChanged: _onMonthPageChanged,
                    itemBuilder: (context, pageIndex) {
                      final pageOffset = pageIndex - 1000;
                      final monthDate = DateTime(_today.year, _today.month + pageOffset, 1);
                      return _buildMonthGridForDate(monthDate, workoutDays);
                    },
                  ),
                )
              : SizedBox(
                  height: 70,
                  child: PageView.builder(
                    controller: _weekPageController,
                    onPageChanged: _onWeekPageChanged,
                    itemBuilder: (context, pageIndex) {
                      return _buildWeekPage(pageIndex, workoutDays);
                    },
                  ),
                ),

          // Ручка-індикатор
          GestureDetector(
            onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Згорнутий тиждень з чітким вирівнюванням днів тижня
  Widget _buildWeekPage(int pageIndex, Set<int> workoutDays) {
    final pageOffset = pageIndex - 1000;
    final currentMonday = _today.subtract(Duration(days: _today.weekday - 1)).add(Duration(days: pageOffset * 7));

    final weekDays = List.generate(7, (i) {
      final date = currentMonday.add(Duration(days: i));
      return {
        'dayName': _isSameDay(date, _today) ? "Сьогодні" : _weekDaysUa[i],
        'date': date,
      };
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((item) {
          final date = item['date'] as DateTime;
          final isToday = _isSameDay(date, _today);
          final isSelected = _isSameDay(date, _selectedDate);
          final hasWorkout = workoutDays.contains(date.day) && date.month == _selectedDate.month;

          final isPurple = isToday || hasWorkout;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 14,
                  child: Center(
                    child: Text(
                      item['dayName'].toString(),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: kSubTextColor,
                        fontSize: isToday ? 10 : 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: isToday ? -0.3 : 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPurple ? kPurpleAccent : kDarkBg,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    boxShadow: isPurple
                        ? [
                            BoxShadow(
                              color: kPurpleAccent.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "${date.day}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isPurple || isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Розгорнута сітка для конкретного місяця
  Widget _buildMonthGridForDate(DateTime monthDate, Set<int> workoutDays) {
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final startingOffset = firstDayOfMonth.weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDaysUa
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: kSubTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + startingOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < startingOffset) {
                return const SizedBox.shrink();
              }

              final dayNum = index - startingOffset + 1;
              final date = DateTime(monthDate.year, monthDate.month, dayNum);
              final isToday = _isSameDay(date, _today);
              final isSelected = _isSameDay(date, _selectedDate);
              final hasWorkout = workoutDays.contains(dayNum) && date.month == _selectedDate.month;

              final isPurple = isToday || hasWorkout;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isPurple ? kPurpleAccent : kDarkBg,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      "$dayNum",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isPurple || isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutRealCard({
    required String title,
    required String date,
    required String volume,
    required String setsCount,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(color: kSubTextColor, fontSize: 12)),
              const Icon(Icons.arrow_forward_ios_rounded, color: kSubTextColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile("Об'єм", volume),
              _metricTile("Підходи", setsCount),
              _metricTile("Тривалість", time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kSubTextColor, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
