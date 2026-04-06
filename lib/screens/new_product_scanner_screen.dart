import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/mock_ai_service.dart';

class NewProductScannerScreen extends StatefulWidget {
  final String method;
  final String loadingText;

  const NewProductScannerScreen({
    super.key,
    required this.method,
    required this.loadingText,
  });

  @override
  State<NewProductScannerScreen> createState() => _NewProductScannerScreenState();
}

class _NewProductScannerScreenState extends State<NewProductScannerScreen> {
  List<Ingredient>? recognizedIngredients;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _processScan();
  }

  Future<void> _processScan() async {
    final results = await MockAIService.scanNewProducts(widget.method);
    if (mounted) {
      setState(() {
        recognizedIngredients = results;
        isScanning = false;
      });
    }
  }

  void _saveToFridge() {
    // Здесь в будущем будет вызов API или State Management для сохранения продуктов
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Продукты успешно добавлены в холодильник!')),
    );
    // Возвращаемся на Главный экран
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление продуктов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'На главную',
          )
        ],
      ),
      body: isScanning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(widget.loadingText, style: const TextStyle(fontSize: 16)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Распознанные продукты:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: recognizedIngredients!.length,
                      itemBuilder: (context, index) {
                        final ing = recognizedIngredients![index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(ing.name),
                            trailing: Text('${(ing.confidence * 100).toInt()}% точн.'),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Сохранить в холодильник', style: TextStyle(fontSize: 18)),
                      onPressed: _saveToFridge,
                    ),
                  )
                ],
              ),
            ),
    );
  }
}