import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/active_workout/active_workout_screen.dart';
import '../screens/workout/calibration_screen.dart';
import '../screens/workout/recording_screen.dart';
import '../screens/workout/summary_screen.dart';
import '../screens/device/device_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/workout_service.dart';
import '../screens/active_workout/widgets/hold_button.dart';

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
        final workoutService = WorkoutService();

        return ListenableBuilder(
          listenable: workoutService,
          builder: (context, child) {
            final isWorkoutActive = workoutService.isWorkoutActive;
            final isCurrentWorkoutRoute = state.matchedLocation.startsWith('/workout');

            return Scaffold(
              backgroundColor: kDarkBg,
              body: navigationShell,
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Повноширинна плашка з закругленням ТІЛЬКИ верхніх кутів
                  if (isWorkoutActive && !isCurrentWorkoutRoute)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: kDarkCardBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        border: Border(
                          top: BorderSide(color: Colors.white10, width: 0.8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: kPurpleAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Тренування триває",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => context.go('/workout'),
                                icon: const Icon(Icons.play_arrow_rounded, color: kPurpleAccent, size: 18),
                                label: const Text(
                                  "Продовжити",
                                  style: TextStyle(
                                    color: kPurpleAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showCancelWorkoutDialog(context, workoutService),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // BottomNavigationBar
                  Container(
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
                ],
              ),
            );
          },
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ActiveWorkoutScreen(),
                transitionDuration: const Duration(milliseconds: 350),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                    child: child,
                  );
                },
              ),
              routes: [
                GoRoute(
                  path: 'calibrate',
                  pageBuilder: (context, state) {
                    final m = state.extra as Map<String, dynamic>? ?? {};
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: CalibrationScreen(
                        exercise: m['exercise'] ?? 'Станова тяга',
                        setType: m['setType'] ?? 'Working set',
                        weight: m['weight'] ?? '170',
                      ),
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                          child: child,
                        );
                      },
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

void _showCancelWorkoutDialog(BuildContext context, WorkoutService workoutService) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: kDarkCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ти впевнений, що хочеш перервати це тренування?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              HoldButton(
                icon: Icons.stop_rounded,
                fillColor: Colors.redAccent,
                onTrigger: () {
                  workoutService.finishWorkout();
                  Navigator.of(dialogContext).pop();
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  "Продовжити тренування",
                  style: TextStyle(color: kSubTextColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
