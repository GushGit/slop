import 'package:flutter/material.dart';
import 'screens/goal_screen.dart';

void main() {
  runApp(const ReciperApp());
}

class ReciperApp extends StatelessWidget {
  const ReciperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reciper AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GoalScreen(),
    );
  }
}