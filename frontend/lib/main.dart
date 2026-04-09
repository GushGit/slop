import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'services/backend_api.dart';
import 'services/nutrition_service.dart';
import 'services/pantry_repository.dart';
import 'services/recipe_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ReciperApp());
}

class ReciperApp extends StatefulWidget {
  const ReciperApp({super.key});

  @override
  State<ReciperApp> createState() => _ReciperAppState();
}

class _ReciperAppState extends State<ReciperApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      pantryRepository: PantryRepository(backendApi: MockBackendApi()),
      recipeRepository: RecipeRepository(),
      nutritionService: NutritionService(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E8C6E),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.primaryContainer,
        contentTextStyle: TextStyle(color: scheme.onPrimaryContainer),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Reciper AI',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: _controller.themeMode,
          home: HomeScreen(controller: _controller),
        );
      },
    );
  }
}