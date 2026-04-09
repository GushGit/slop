import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/app_enums.dart';
import '../models/cooking_result.dart';
import '../models/prepared_meal.dart';
import '../models/recipe_option.dart';
import 'recipe_details_screen.dart';
import 'tabs/goals_tab.dart';
import 'tabs/ingredients_tab.dart';
import 'tabs/recipes_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(_titleByTab(_selectedTabIndex))),
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              RecipesTab(
                selectedMealType: widget.controller.selectedMealType,
                recipes: widget.controller.visibleRecipes,
                goalModeLabel: _goalModeLabel(widget.controller.goalMode),
                onMealTypeSelected: widget.controller.setMealType,
                onRecipeSelected: _openRecipeDetails,
              ),
              FridgeTab(
                viewType: widget.controller.fridgeViewType,
                onViewTypeChanged: widget.controller.setFridgeViewType,
                items: widget.controller.pantryItems,
                preparedMeals: widget.controller.preparedMeals,
                onConsumePreparedMeal: _consumePreparedMeal,
                history: widget.controller.scanHistory,
              ),
              GoalsTab(
                goalMode: widget.controller.goalMode,
                weight: widget.controller.weight,
                height: widget.controller.height,
                age: widget.controller.age,
                activityMultiplier: widget.controller.activityMultiplier,
                targets: widget.controller.targets,
                progress: widget.controller.progress,
                selectedProgressDate: widget.controller.selectedProgressDate,
                goalPeriodEndDate: widget.controller.goalPeriodEndDate,
                onGoalModeChanged: widget.controller.setGoalMode,
                onApplyForm: ({
                  required int weight,
                  required int height,
                  required int age,
                  required double activityMultiplier,
                }) {
                  widget.controller.setAnthropometry(
                    updatedWeight: weight,
                    updatedHeight: height,
                    updatedAge: age,
                    updatedActivityMultiplier: activityMultiplier,
                  );
                },
                onSelectProgressDate: widget.controller.selectProgressDate,
                onPickGoalEndDate: widget.controller.setGoalPeriodEndDate,
              ),
              SettingsTab(
                themeMode: widget.controller.themeMode,
                onThemeModeChanged: widget.controller.setThemeMode,
              ),
            ],
          ),
          floatingActionButton: _selectedTabIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: _isScanning ? null : _showScanOptions,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner),
                  label: const Text('Сканировать'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Рецепты',
              ),
              NavigationDestination(
                icon: Icon(Icons.kitchen_outlined),
                selectedIcon: Icon(Icons.kitchen),
                label: 'Холодильник',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                selectedIcon: Icon(Icons.flag),
                label: 'Цели',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Настройки',
              ),
            ],
          ),
        );
      },
    );
  }

  void _openRecipeDetails(RecipeOption recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailsScreen(
          recipe: recipe,
          onCookingFinished: (CookingResult result) {
            widget.controller.registerCookingResult(recipe: recipe, result: result);
          },
        ),
      ),
    );
  }

  void _consumePreparedMeal(PreparedMeal meal, int percent) {
    widget.controller.consumePreparedMeal(meal: meal, consumedPercent: percent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Съедено $percent% блюда "${meal.title}".')),
    );
  }

  Future<void> _showScanOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сфотографировать продукты'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scanProducts(method: 'photo', methodLabel: 'Фото');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Распознать чек'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scanProducts(method: 'receipt', methodLabel: 'Чек');
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Сканировать штрихкод / QR'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scanProducts(method: 'barcode', methodLabel: 'Штрихкод');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanProducts({required String method, required String methodLabel}) async {
    setState(() {
      _isScanning = true;
    });

    try {
      await widget.controller.scanProducts(method: method, methodLabel: methodLabel);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сканирование завершено, продукты добавлены.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  String _titleByTab(int index) {
    return switch (index) {
      0 => 'Рецепты',
      1 => 'Электронный холодильник',
      2 => 'Цели и КБЖУ',
      3 => 'Настройки',
      _ => 'Reciper AI',
    };
  }

  String _goalModeLabel(GoalMode mode) {
    return switch (mode) {
      GoalMode.weightLoss => 'Похудение',
      GoalMode.maintain => 'Поддержание',
      GoalMode.massGain => 'Набор массы',
    };
  }
}
