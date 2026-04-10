import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isSuggestingRecipes = false;
  final ImagePicker _picker = ImagePicker();

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
                onSuggestRecipes: _suggestRecipesFromFridge,
                isSuggestingRecipes: _isSuggestingRecipes,
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
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scanFromSource(ImageSource.camera, method: 'camera', methodLabel: 'Фото');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scanFromSource(ImageSource.gallery, method: 'gallery', methodLabel: 'Галерея');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanFromSource(
    ImageSource source, {
    required String method,
    required String methodLabel,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (!mounted || picked == null) {
      return;
    }
    await _scanProducts(
      method: method,
      methodLabel: methodLabel,
      imagePath: picked.path,
    );
  }

  Future<void> _scanProducts({
    required String method,
    required String methodLabel,
    required String imagePath,
  }) async {
    setState(() {
      _isScanning = true;
    });

    try {
      await widget.controller.scanProducts(
        method: method,
        methodLabel: methodLabel,
        imagePath: imagePath,
      );
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

  Future<void> _suggestRecipesFromFridge() async {
    setState(() {
      _isSuggestingRecipes = true;
    });
    try {
      await widget.controller.suggestRecipesFromFridge();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTabIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепты обновлены по продуктам из холодильника.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSuggestingRecipes = false;
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
