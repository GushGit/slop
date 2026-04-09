import 'package:flutter/material.dart';
import '../models/recipe.dart';

class CookingAssistantScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingAssistantScreen({super.key, required this.recipe});

  @override
  State<CookingAssistantScreen> createState() => _CookingAssistantScreenState();
}

class _CookingAssistantScreenState extends State<CookingAssistantScreen> {
  int currentStep = 0;

  void nextStep() {
    if (currentStep < widget.recipe.steps.length - 1) {
      setState(() => currentStep++);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Приятного аппетита!'),
          content: const Text('Вы успешно приготовили блюдо.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('На главную'),
            )
          ],
        ),
      );
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.title)), // actions удалены
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Шаг ${currentStep + 1} из ${widget.recipe.steps.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 40),
            Text(
              widget.recipe.steps[currentStep],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: currentStep > 0 ? prevStep : null,
                  child: const Text('Назад'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  onPressed: nextStep,
                  child: Text(currentStep == widget.recipe.steps.length - 1 ? 'Завершить' : 'Далее'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}