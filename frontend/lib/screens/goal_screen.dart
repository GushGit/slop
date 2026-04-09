import 'package:flutter/material.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Цели питания')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Выбор режима и расчет КБЖУ доступны на вкладке "Цели" в нижней панели приложения.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}