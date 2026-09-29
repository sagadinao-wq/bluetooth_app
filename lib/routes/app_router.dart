import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/onboarding/onboarding_screen.dart';
import '../screens/workout/setup_screen.dart';
import '../screens/workout/calibration_screen.dart';
import '../screens/workout/recording_screen.dart';
import '../screens/workout/summary_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/device/device_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../constants/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/workout', // Або '/splash' за вашим вибором
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // StatefulShellRoute.indexedStack зберігає екрани в пам'яті (Bluetooth не розриватиметься!)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: kCardColor,
            selectedItemColor: kCyanColor,
            unselectedItemColor: kSubColor,
            currentIndex: navigationShell.currentIndex,
            onTap: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Тренування'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Історія'),
              BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Прилад'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профіль'),
            ],
          ),
        );
      },
      branches: [
        // Вкладка 0: Тренування
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              builder: (context, state) => const SetupScreen(),
              routes: [
                GoRoute(
                  path: 'calibrate',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>;
                    return CalibrationScreen(
                      exercise: m['exercise'] ?? 'Жим',
                      weight: m['weight'] ?? '60',
                    );
                  },
                ),
                GoRoute(
                  path: 'record',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>;
                    return RecordingScreen(
                      exercise: m['exercise'] ?? 'Жим',
                      weight: m['weight'] ?? '60',
                    );
                  },
                ),
                GoRoute(
                  path: 'summary',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>;
                    return SummaryScreen(
                      exercise: m['exercise'] ?? 'Жим',
                      weight: m['weight'] ?? '60',
                      durationMs: m['durationMs'] ?? 0,
                      samples: m['samples'] ?? 0,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Вкладка 1: Історія
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),

        // Вкладка 2: Прилад (Vector VBT Sensor)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/device',
              builder: (context, state) => const DeviceScreen(),
            ),
          ],
        ),

        // Вкладка 3: Профіль
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
