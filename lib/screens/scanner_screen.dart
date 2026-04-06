import 'package:flutter/material.dart';
import '../services/mock_ai_service.dart';
import 'recipes_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  @override
  void initState() {
    super.initState();
    _analyzeFridge();
  }

  Future<void> _analyzeFridge() async {
    final ingredients = await MockAIService.scanFridge();
    final recipes = await MockAIService.getRecipes(ingredients);
    
    if (mounted) {
      // pushReplacement заменяет экран загрузки на экран рецептов. 
      // Стрелка "назад" на экране рецептов вернет пользователя на HomeScreen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecipesScreen(
            ingredients: ingredients,
            recipes: recipes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // Белая автоматическая стрелка назад
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.document_scanner, color: Colors.greenAccent, size: 80),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(height: 20),
            Text(
              'AI анализирует холодильник...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            )
          ],
        ),
      ),
    );
  }
}