import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Перехоплення помилок UI
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Text(
              "Помилка рендерингу:\n\n${details.exception}\n\n${details.stack}",
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  };

  // Безпечна ініціалізація Firebase
  try {
    await Firebase.initializeApp();
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
