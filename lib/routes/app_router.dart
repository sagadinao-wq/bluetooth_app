import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Перехоплення та виведення помилок рендерингу безпосередньо на екран замість сірого заповнення
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Виявлено помилку",
                      style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "${details.exception}",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "${details.stack}",
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Безпечна ініціалізація Firebase з захистом від затримки
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint("Таймаут ініціалізації Firebase");
        return Firebase.app();
      },
    );
  } catch (e) {
    debugPrint("Помилка ініціалізації Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vector VBT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        primaryColor: const Color(0xFF6C22FF),
      ),
      routerConfig: appRouter,
    );
  }
}
