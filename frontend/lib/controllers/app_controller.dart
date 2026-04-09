import 'package:flutter/material.dart';

import '../models/app_enums.dart';
import '../models/cooking_result.dart';
import '../models/day_nutrition_progress.dart';
import '../models/meal_log_entry.dart';
import '../models/nutrition_targets.dart';
import '../models/pantry_item.dart';
import '../models/prepared_meal.dart';
import '../models/recipe_option.dart';
import '../models/scan_history_entry.dart';
import '../services/nutrition_service.dart';
import '../services/pantry_repository.dart';
import '../services/recipe_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required PantryRepository pantryRepository,
    required RecipeRepository recipeRepository,
    required NutritionService nutritionService,
  })  : _pantryRepository = pantryRepository,
        _recipeRepository = recipeRepository,
        _nutritionService = nutritionService {
    _recalculateNutrition(showNotify: false);
    _refreshRecipes(showNotify: false);
  }

  final PantryRepository _pantryRepository;
  final RecipeRepository _recipeRepository;
  final NutritionService _nutritionService;

  ThemeMode themeMode = ThemeMode.system;
  AppLanguage appLanguage = AppLanguage.russian;

  GoalMode goalMode = GoalMode.weightLoss;
  DateTime? goalPeriodEndDate;
  MealType selectedMealType = MealType.breakfast;
  FridgeViewType fridgeViewType = FridgeViewType.ingredients;

  int weight = 75;
  int height = 178;
  int age = 30;
  double activityMultiplier = 1.4;

  NutritionTargets? targets;
  List<DayNutritionProgress> progress = [];
  DateTime? selectedProgressDate;

  List<RecipeOption> visibleRecipes = [];

  List<PantryItem> get pantryItems => _pantryRepository.items;
  List<PreparedMeal> get preparedMeals => _pantryRepository.preparedMeals;
  List<ScanHistoryEntry> get scanHistory => _pantryRepository.history;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    appLanguage = AppLanguage.russian;
    notifyListeners();
  }

  void setGoalMode(GoalMode mode) {
    goalMode = mode;
    _refreshRecipes(showNotify: false);
    _recalculateNutrition(showNotify: false);
    notifyListeners();
  }

  void setGoalPeriodEndDate(DateTime date) {
    goalPeriodEndDate = date;
    notifyListeners();
  }

  void setMealType(MealType mealType) {
    selectedMealType = mealType;
    _refreshRecipes(showNotify: false);
    notifyListeners();
  }

  void setFridgeViewType(FridgeViewType type) {
    fridgeViewType = type;
    notifyListeners();
  }

  void setAnthropometry({
    required int updatedWeight,
    required int updatedHeight,
    required int updatedAge,
    required double updatedActivityMultiplier,
  }) {
    weight = updatedWeight;
    height = updatedHeight;
    age = updatedAge;
    activityMultiplier = updatedActivityMultiplier;

    _recalculateNutrition(showNotify: false);
    notifyListeners();
  }

  void selectProgressDate(DateTime date) {
    selectedProgressDate = date;
    notifyListeners();
  }

  Future<void> scanProducts({
    required String method,
    required String methodLabel,
  }) async {
    await _pantryRepository.scanAndAddProducts(
      method: method,
      locale: appLanguage == AppLanguage.russian ? 'ru' : 'en',
      methodLabel: methodLabel,
    );
    _refreshRecipes(showNotify: false);
    notifyListeners();
  }

  void applyIngredientConsumption(Map<String, int> consumptionPercentByIngredient) {
    _pantryRepository.applyIngredientConsumption(consumptionPercentByIngredient);
    _refreshRecipes(showNotify: false);
    notifyListeners();
  }

  void registerCookingResult({
    required RecipeOption recipe,
    required CookingResult result,
  }) {
    _pantryRepository.applyIngredientConsumption(result.consumptionPercentByIngredient);

    // Save everything directly to fridge
    _pantryRepository.addPreparedMeal(
      PreparedMeal(
        id: '${recipe.id}-${DateTime.now().millisecondsSinceEpoch}',
        title: recipe.title,
        imageUrl: recipe.imageUrl,
        remainingPercent: 100,
        calories: result.finalCalories,
        proteins: result.finalProteins,
        fats: result.finalFats,
        carbs: result.finalCarbs,
        cookedAt: DateTime.now(),
      ),
    );

    _refreshRecipes(showNotify: false);
    notifyListeners();
  }

  void consumePreparedMeal({
    required PreparedMeal meal,
    required int consumedPercent,
  }) {
    final maxAllowed = meal.remainingPercent.clamp(0, 100);
    final bounded = consumedPercent.clamp(0, maxAllowed);
    if (bounded <= 0) {
      return;
    }

    _pantryRepository.consumePreparedMeal(mealId: meal.id, consumedPercent: bounded);
    _addMealToProgress(
      recipeTitle: meal.title,
      calories: meal.calories * bounded / 100,
      proteins: meal.proteins * bounded / 100,
      fats: meal.fats * bounded / 100,
      carbs: meal.carbs * bounded / 100,
    );

    _refreshRecipes(showNotify: false);
    notifyListeners();
  }

  DayNutritionProgress? get selectedProgressDay {
    final date = selectedProgressDate;
    if (date == null) {
      return null;
    }

    for (final item in progress) {
      if (item.date.year == date.year && item.date.month == date.month && item.date.day == date.day) {
        return item;
      }
    }

    return null;
  }

  void _refreshRecipes({bool showNotify = true}) {
    visibleRecipes = _recipeRepository.getRecipes(
      mealType: selectedMealType,
      goalMode: goalMode,
      availableIngredientNames: pantryItems.map((item) => item.name).toList(),
    );
    if (showNotify) {
      notifyListeners();
    }
  }

  void _addMealToProgress({
    required String recipeTitle,
    required double calories,
    required double proteins,
    required double fats,
    required double carbs,
  }) {
    final now = selectedProgressDate ?? DateTime.now();
    final dayIndex = progress.indexWhere((item) {
      return item.date.year == now.year && item.date.month == now.month && item.date.day == now.day;
    });
    if (dayIndex < 0) {
      return;
    }

    final meal = MealLogEntry(
      recipeTitle: recipeTitle,
      calories: calories,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
    );
    progress[dayIndex] = progress[dayIndex].addMeal(meal);
  }

  void _recalculateNutrition({bool showNotify = true}) {
    targets = _nutritionService.calculateTargets(
      weight: weight,
      height: height,
      age: age,
      activityMultiplier: activityMultiplier,
      goalMode: goalMode,
    );

    progress = _nutritionService.generateProgress(
      targets: targets!,
      fromDate: DateTime.now(),
    );

    selectedProgressDate ??= DateTime.now();

    if (showNotify) {
      notifyListeners();
    }
  }
}
