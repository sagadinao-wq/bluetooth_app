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
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: kCardColor,
            selectedItemColor: kCyanColor,
            unselectedItemColor: kSubColor,
            currentIndex: _calculateSelectedIndex(state.uri.toString()),
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/workout');
                  break;
                case 1:
                  context.go('/history');
                  break;
                case 2:
                  context.go('/device');
                  break;
                case 3:
                  context.go('/profile');
                  break;
              }
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
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/device',
          builder: (context, state) => const DeviceScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/history')) return 1;
  if (location.startsWith('/device')) return 2;
  if (location.startsWith('/profile')) return 3;
  return 0;
}
