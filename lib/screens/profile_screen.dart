import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String currentGoal;

  const ProfileScreen({super.key, required this.currentGoal});

  @override
  Widget build(BuildContext context) {
    final goals = [
      "Поддержание формы",
      "Похудение",
      "Набор массы",
      "Сбалансированное питание"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль и настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ваша цель питания:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...goals.map(
            (goal) => Card(
              child: ListTile(
                title: Text(goal),
                trailing: currentGoal == goal
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.circle_outlined),
                onTap: () => Navigator.pop(context, goal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}