import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/ble_service.dart';

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

  final List<String> _monthsUa = [
    'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
    'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'
  ];

  final List<String> _weekDaysUa = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'];

  // Дні поточного місяця з тренуваннями
  final Set<int> _workoutDays = {3, 8, 12, 15, 21, 25, 28};

  final BleService _ble = BleService();

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _selectedDate = DateTime(_today.year, _today.month, _today.day);
    _weekPageController = PageController(initialPage: 1000);
    _ble.addListener(_onBleUpdate);
  }

  @override
  void dispose() {
    _weekPageController.dispose();
    _ble.removeListener(_onBleUpdate);
    super.dispose();
  }

  void _onBleUpdate() {
    if (mounted) setState(() {});
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Верхня панель з календарем
            _buildCalendarHeader(),

            // 2. Основна стрічка з історією
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

                    // Світліша виділена картка швидкого старту
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/workout'),
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

                    // Муляжі тренувань
                    _buildWorkoutDummyCard(
                      title: "Силове тренування — Жим & Тяга",
                      date: "${_selectedDate.day} ${_monthsUa[_selectedDate.month - 1]}",
                      volume: "4,820 кг",
                      setsCount: "8 підходів",
                      bestSpeed: "0.82 м/с",
                    ),
                    const SizedBox(height: 12),
                    _buildWorkoutDummyCard(
                      title: "День ніг — Присідання",
                      date: "28 Вересня",
                      volume: "6,150 кг",
                      setsCount: "10 підходів",
                      bestSpeed: "0.68 м/с",
                    ),
                    const SizedBox(height: 12),
                    _buildWorkoutDummyCard(
                      title: "Верх тіла — Важка станова",
                      date: "25 Вересня",
                      volume: "5,400 кг",
                      setsCount: "6 підходів",
                      bestSpeed: "0.55 м/с",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Блок календаря
  Widget _buildCalendarHeader() {
    final monthName = _monthsUa[_selectedDate.month - 1];

    return Container(
      decoration: const BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Шапка з назвою місяця по центру та стрілочками ВПРИТУЛ
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Стрілочка вліво впритул
                GestureDetector(
                  onTap: () => _changeDay(-1),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.arrow_back_ios_rounded, color: kPurpleAccent, size: 18),
                  ),
                ),

                // Назва місяця по центру (клікабельна без залишків стрілочок розгортання)
                GestureDetector(
                  onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                    child: Text(
                      monthName,
                      key: ValueKey(monthName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Стрілочка вправо впритул
                GestureDetector(
                  onTap: () => _changeDay(1),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.arrow_forward_ios_rounded, color: kPurpleAccent, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Перемикач: Згорнута стрічка АБО Розгорнута сітка
          AnimatedCrossFade(
            firstChild: SizedBox(
              height: 70,
              child: PageView.builder(
                controller: _weekPageController,
                itemBuilder: (context, pageIndex) {
                  return _buildWeekPage(pageIndex);
                },
              ),
            ),
            secondChild: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    _changeMonth(1); // Свайп вліво по всій сітці -> наступний місяць
                  } else if (details.primaryVelocity! > 0) {
                    _changeMonth(-1); // Свайп вправо по всій сітці -> попередній місяць
                  }
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey("${_selectedDate.year}-${_selectedDate.month}"),
                  child: _buildDynamicMonthGrid(),
                ),
              ),
            ),
            crossFadeState: _isCalendarExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          // Ручка-індикатор для потягування
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

  // Сторінка тижня
  Widget _buildWeekPage(int pageIndex) {
    final pageOffset = pageIndex - 1000;
    final currentMonday = _today.subtract(Duration(days: _today.weekday - 1)).add(Duration(days: pageOffset * 7));

    final weekDays = List.generate(7, (i) {
      final date = currentMonday.add(Duration(days: i));
      return {
        'dayName': _weekDaysUa[i],
        'date': date,
      };
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((item) {
          final date = item['date'] as DateTime;
          final isToday = _isSameDay(date, _today);
          final isSelected = _isSameDay(date, _selectedDate);
          final hasWorkout = _workoutDays.contains(date.day) && date.month == _today.month;

          final isPurple = isToday || hasWorkout;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['dayName'].toString(),
                  style: const TextStyle(color: kSubTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPurple ? kPurpleAccent : kDarkBg,
                    shape: BoxShape.circle,
                    // Підсвітка білим обводком при натисканні
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

  // Повний календар місяця
  Widget _buildDynamicMonthGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
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
              final date = DateTime(_selectedDate.year, _selectedDate.month, dayNum);
              final isToday = _isSameDay(date, _today);
              final isSelected = _isSameDay(date, _selectedDate);
              final hasWorkout = _workoutDays.contains(dayNum) && date.month == _today.month;

              final isPurple = isToday || hasWorkout;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isPurple ? kPurpleAccent : kDarkBg,
                    shape: BoxShape.circle,
                    // Білий кружечок/обводок підсвічування обраної дати
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

  Widget _buildWorkoutDummyCard({
    required String title,
    required String date,
    required String volume,
    required String setsCount,
    required String bestSpeed,
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
              _metricTile("Max V_mean", bestSpeed),
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
