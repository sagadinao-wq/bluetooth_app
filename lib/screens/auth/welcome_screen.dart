import '../../constants/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isLoading = false;

  // Настройка PageView для слайдера
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Анімація фонового градієнта
  late AnimationController _gradientController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  final List<Map<String, String>> _slides = [
    {
      "title": "Відстежуй кожен повтор,\nвдосконалюй кожне тренування",
      "subtitle": "Потрібен прилад Vector VBT",
    },
    {
      "title": "Тренуйся розумніше,\nсьогодні та щодня",
      "subtitle": "Точний аналіз швидкості та сили в реальному часі",
    },
    {
      "title": "Досягай цілей завдяки\nточечним даним",
      "subtitle": "Персональна статистика та прогрес кожного підходу",
    },
  ];

  @override
  void initState() {
    super.initState();

    // Автоматична прокрутка слайдів кожні 4 секунди
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });

    // Настройка плавної анимації переливання фону
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _topAlignmentAnimation = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(_gradientController);

    _bottomAlignmentAnimation = AlignmentTween(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(_gradientController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _loginAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInAnonymously();
      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kDarkCardBg,
            content: Text("Не вдалося увійти як гість: $e", style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: [
                  kDarkBg,
                  kPurpleAccent.withOpacity(0.18),
                  kDarkBg,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Логотип Vector VBT
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPurpleAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: kPurpleAccent, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Vector VBT",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const Spacer(),

              // Слайдер цитат
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide["title"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide["subtitle"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kSubTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Полоски-індикатори активного слайда
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 28 : 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Кнопки навігації
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Get Started",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push('/login'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        "Log In",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: kPurpleAccent))
                    else
                      TextButton(
                        onPressed: _loginAnonymously,
                        child: const Text(
                          "Продовжити як гість",
                          style: TextStyle(color: kSubTextColor, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      "Використовуючи Vector VBT, ви погоджуєтеся з Умовами використання та Політикою конфіденційності.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
