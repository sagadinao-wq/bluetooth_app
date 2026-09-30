import 'package:flutter/material.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

class ProfileDrawerScreen extends StatelessWidget {
  const ProfileDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Верхня шапка з хрестиком справа
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Мій Профіль",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),

            // Пустий контент у нашому стилі
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kDarkCardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: kPurpleAccent.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: kPurpleAccent, size: 64),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Профіль користувача",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Тут відображатимуться детальні налаштування акаунту та статистика",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kSubTextColor, fontSize: 14),
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
}
