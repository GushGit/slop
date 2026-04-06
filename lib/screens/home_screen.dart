import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/mock_ai_service.dart';
import 'scanner_screen.dart';
import 'new_product_scanner_screen.dart'; // Новый импорт

class HomeScreen extends StatefulWidget {
  final String goal;
  const HomeScreen({super.key, required this.goal});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Meal> mealPlan = [];
  bool isLoadingPlan = true;

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    final plan = await MockAIService.generateMealPlan(widget.goal);
    setState(() {
      mealPlan = plan;
      isLoadingPlan = false;
    });
  }

  // Вызов нижнего меню с выбором варианта сканирования
  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.kitchen, color: Colors.blue),
              title: const Text('Сканировать холодильник', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Найти рецепты из того, что есть'),
              onTap: () {
                Navigator.pop(ctx); // Закрываем меню
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
              child: Text('Добавить новые продукты', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сфотографировать продукты'),
              onTap: () => _openNewScan(ctx, 'photo', 'Анализ фото...'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Распознать текст чека'),
              onTap: () => _openNewScan(ctx, 'receipt', 'Чтение чека OCR...'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Отсканировать штрихкод / QR'),
              onTap: () => _openNewScan(ctx, 'barcode', 'Поиск по базе штрихкодов...'),
            ),
          ],
        ),
      ),
    );
  }

  void _openNewScan(BuildContext context, String method, String loadingText) {
    Navigator.pop(context); // Закрываем меню
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewProductScannerScreen(method: method, loadingText: loadingText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reciper AI'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Цель: ${widget.goal}',
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            const Text('Ваш план питания на сегодня',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            isLoadingPlan
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: mealPlan.length,
                      itemBuilder: (context, index) {
                        final meal = mealPlan[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.restaurant_menu),
                            title: Text(meal.dish),
                            subtitle: Text(meal.type),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScanOptions(context),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}