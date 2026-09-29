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
  initialLocation: '/workout',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const OnboardingScreen(),
    ),
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              builder: (context, state) => const SetupScreen(),
              routes: [
                GoRoute(
                  path: 'calibrate',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>? ?? {};
                    return CalibrationScreen(
                      exercise: m['exercise'] ?? 'Жим',
                      setType: m['setType'] ?? 'Working set',
                      weight: m['weight'] ?? '60',
                    );
                  },
                ),
                GoRoute(
                  path: 'record',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>? ?? {};
                    return RecordingScreen(
                      exercise: m['exercise'] ?? 'Жим',
                      setType: m['setType'] ?? 'Working set',
                      weight: m['weight'] ?? '60',
                    );
                  },
                ),
                GoRoute(
                  path: 'summary',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>? ?? {};
                    return SummaryScreen(
                      exercise: m['exercise'] ?? 'Жим',
                      setType: m['setType'] ?? 'Working set',
                      weight: m['weight'] ?? '60',
                      repCount: m['repCount'] ?? 0,
                      bestV: m['bestV'] ?? 0.0,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/device',
              builder: (context, state) => const DeviceScreen(),
            ),
          ],
        ),
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
