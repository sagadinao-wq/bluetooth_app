import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'routes/app_router.dart';

void main() => runApp(const VectorVbtApp());

class VectorVbtApp extends StatelessWidget {
  const VectorVbtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Vector VBT',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgColor,
      ),
      routerConfig: appRouter,
    );
  }
}
