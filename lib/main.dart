import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const LearnLoopApp());
}

class LearnLoopApp extends StatelessWidget {
  const LearnLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnLoop AI',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
