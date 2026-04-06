import 'package:flutter/material.dart';
import 'home_screen.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = [
      "Поддержание формы",
      "Похудение",
      "Набор массы",
      "Сбалансированное питание"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ваша цель питания?')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(goals[index], style: const TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(goal: goals[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}