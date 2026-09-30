import 'package:flutter/material.dart';
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
  
  // Поточна дата пристрою
  late DateTime _today;
  late DateTime _selectedDate;

  // Назви місяців та днів тижня українською
  final List<String> _monthsUa = [
    'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
    'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'
  ];

  final List<String> _weekDaysUa = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'];

  // Приклад днів із тренуваннями для поточного місяця (дні: 3, 8, 12, 15, 21, 25, 28)
  final Set<int> _workoutDays = {3, 8, 12, 15, 21, 25, 28};

  final BleService _ble = BleService();

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _selectedDate = DateTime(_today.year, _today.month, _today.day);
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Верхня панель з розсувним динамічним календарем
            _buildCalendarHeader(),

            // 2. Основна стрічка тренувань
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSameDay(_selectedDate, _today)
                          ? "Сьогоднішній статус"
                          : "Обрана дата: ${_selectedDate.day} ${_monthsUa[_selectedDate.month - 1].toLowerCase()}",
                      style: const TextStyle(color: kSubTextColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // Картка статусу / швидкого старту
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kDarkCardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kPurpleAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kPurpleAccent.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: kPurpleAccent, size: 28),
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
                                SizedBox(height: 2),
                                Text(
                                  "Перейдіть у вкладку Тренування для запису підходу",
                                  style: TextStyle(color: kSubTextColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      date: _isSameDay(_selectedDate, _today)
                          ? "Сьогодні, ${_today.day} ${_monthsUa[_today.month - 1]}"
                          : "${_selectedDate.day} ${_monthsUa[_selectedDate.month - 1]}",
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

  // Блок календаря з можливістю розгортання
  Widget _buildCalendarHeader() {
    final currentMonthName = _monthsUa[_today.month - 1];

    return Container(
      decoration: const BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Шапка з динамічним місяцем і роком
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "$currentMonthName ${_today.year}",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _isCalendarExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: kPurpleAccent,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCalendarExpanded = !_isCalendarExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kDarkBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Компактний тижневик АБО Повний календар місяця
          AnimatedCrossFade(
            firstChild: _buildDynamicWeekStrip(),
            secondChild: _buildDynamicMonthGrid(),
            crossFadeState: _isCalendarExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // Індикатор потягування шторки
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

  // Динамічна стрічка поточного тижня (від Понеділка до Неділі)
  Widget _buildDynamicWeekStrip() {
    // Знаходимо понеділок поточного тижня
    final monday = _today.subtract(Duration(days: _today.weekday - 1));

    final weekDays = List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return {
        'dayName': _weekDaysUa[i],
        'date': date,
      };
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((item) {
          final date = item['date'] as DateTime;
          final isToday = _isSameDay(date, _today);
          final isSelected = _isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Column(
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
                    color: isToday ? kPurpleAccent : kDarkBg,
                    shape: BoxShape.circle,
                    border: isSelected && !isToday
                        ? Border.all(color: kPurpleAccent, width: 2)
                        : null,
                    boxShadow: isToday
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
                        fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
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

  // Динамічна сітка повного поточного місяця
  Widget _buildDynamicMonthGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_today.year, _today.month);
    final firstDayOfMonth = DateTime(_today.year, _today.month, 1);
    
    // Зсув для початку місяця (понеділок = 0, неділя = 6)
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
                return const SizedBox.shrink(); // Порожні клітинки до початку місяця
              }

              final dayNum = index - startingOffset + 1;
              final date = DateTime(_today.year, _today.month, dayNum);
              final isToday = _isSameDay(date, _today);
              final isSelected = _isSameDay(date, _selectedDate);
              final hasWorkout = _workoutDays.contains(dayNum);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday ? kPurpleAccent : kDarkBg,
                    shape: BoxShape.circle,
                    border: isSelected && !isToday
                        ? Border.all(color: kPurpleAccent, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "$dayNum",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (hasWorkout && !isToday)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: kPurpleAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Віджет картки тренування
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
