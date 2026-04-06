import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
      // Теперь приложение стартует сразу с главного экрана
      home: const HomeScreen(),
    );
  }
}