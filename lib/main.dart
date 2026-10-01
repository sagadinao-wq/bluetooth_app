import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Захищена ініціалізація Firebase з таймаутом
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint("Таймаут підключення Firebase");
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
