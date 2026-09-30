import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/workout/setup_screen.dart';
import '../screens/workout/calibration_screen.dart';
import '../screens/workout/recording_screen.dart';
import '../screens/workout/summary_screen.dart';
import '../screens/device/device_screen.dart';
import '../screens/profile/profile_screen.dart';

// Акцентні фірмові кольори
const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);
const kSubTextColor = Color(0xFF8E8E93);

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          backgroundColor: kDarkBg,
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: kDarkCardBg,
              border: Border(
                top: BorderSide(
                  color: Colors.white10,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: kDarkCardBg,
              selectedItemColor: kPurpleAccent,
              unselectedItemColor: kSubTextColor,
              currentIndex: navigationShell.currentIndex,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home_rounded, color: kPurpleAccent),
                  label: 'Головна',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_rounded),
                  activeIcon: Icon(Icons.fitness_center_rounded, color: kPurpleAccent),
                  label: 'Тренування',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bluetooth_rounded),
                  activeIcon: Icon(Icons.bluetooth_rounded, color: kPurpleAccent),
                  label: 'Прилад',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  activeIcon: Icon(Icons.person_rounded, color: kPurpleAccent),
                  label: 'Профіль',
                ),
              ],
            ),
          ),
        );
      },
      branches: [
        // 1. Головна (крайня зліва)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // 2. Тренування
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
                      exercise: m['exercise'] ?? 'Станова тяга',
                      setType: m['setType'] ?? 'Working set',
                      weight: m['weight'] ?? '170',
                    );
                  },
                ),
                GoRoute(
                  path: 'record',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>? ?? {};
                    return RecordingScreen(
                      exercise: m['exercise'] ?? 'Станова тяга',
                      setType: m['setType'] ?? 'Working set',
                      weight: m['weight'] ?? '170',
                    );
                  },
                ),
                GoRoute(
                  path: 'summary',
                  builder: (context, state) {
                    final m = state.extra as Map<String, dynamic>? ?? {};
                    return SummaryScreen(
                      exercise: m['exercise'] ?? 'Станова тяга',
                      setType: m['setType'] ?? 'Working set',
                      weight: m['weight'] ?? '170',
                      repCount: m['repCount'] ?? 0,
                      bestV: m['bestV'] ?? 0.0,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // 3. Прилад
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/device',
              builder: (context, state) => const DeviceScreen(),
            ),
          ],
        ),
        // 4. Профіль
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
