import '../models/app_enums.dart';
import '../models/recipe_ingredient.dart';
import '../models/recipe_option.dart';
import 'backend_api.dart';

class RecipeRepository {
  RecipeRepository({required BackendApi backendApi}) : _backendApi = backendApi;

  final BackendApi _backendApi;

  Future<List<RecipeOption>> getRecipes({
    MealType? mealType,
    GoalMode? goalMode,
    List<String>? availableIngredientNames,
  }) async {
    final recipesRaw = await _backendApi.fetchRecipes(
      products: availableIngredientNames ?? const [],
      utilities: const ['stove', 'microwave'],
      goal: _goalToApi(goalMode ?? GoalMode.weightLoss),
    );

    return recipesRaw.map((item) => _toRecipe(item, fallbackMealType: mealType)).toList();
  }

  String _goalToApi(GoalMode mode) {
    return switch (mode) {
      GoalMode.weightLoss => 'lose_weight',
      GoalMode.maintain => 'maintain',
      GoalMode.massGain => 'gain_weight',
    };
  }

  RecipeOption _toRecipe(Map<String, dynamic> data, {MealType? fallbackMealType}) {
    final parsedSteps = _parseCookingSteps(data['cooking_steps']);
    final steps = parsedSteps.$1;
    final stepDurationsSec = parsedSteps.$2;
    final normalizedSteps = steps.isEmpty
        ? [data['description']?.toString() ?? 'Описание отсутствует']
        : steps;
    final normalizedDurations = stepDurationsSec.isEmpty
        ? List<int>.filled(normalizedSteps.length, 0)
        : stepDurationsSec;
    final utilities = (data['utilities'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().toLowerCase())
        .toSet();

    return RecipeOption(
      id: data['name']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: data['name']?.toString() ?? 'Без названия',
      mealType: fallbackMealType ?? MealType.lunch,
      supportedGoals: {GoalMode.weightLoss, GoalMode.maintain, GoalMode.massGain},
      cookMinutes: (data['cooking_time'] as num?)?.round() ?? 0,
      imageUrl: '',
      needsStove: utilities.contains('stove') || utilities.contains('плита'),
      difficulty: RecipeDifficulty.medium,
      videoUrl: '',
      ingredients: [
        RecipeIngredient(
          name: 'Блюдо целиком',
          amount: 1,
          unit: 'порция',
          minAmount: 1,
          calories: (data['calories'] as num?)?.toDouble() ?? 0,
          proteins: (data['protein'] as num?)?.toDouble() ?? 0,
          fats: (data['fat'] as num?)?.toDouble() ?? 0,
          carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
        ),
      ],
      steps: normalizedSteps,
      stepDurationsSec: normalizedDurations,
    );
  }

  (List<String>, List<int>) _parseCookingSteps(dynamic rawCookingSteps) {
    final rawList = rawCookingSteps as List<dynamic>? ?? const [];
    if (rawList.isEmpty) {
      return (const [], const []);
    }

    final first = rawList.first;
    if (first is Map) {
      final steps = <String>[];
      final durations = <int>[];
      for (final step in rawList.whereType<Map>()) {
        final description = step['description']?.toString().trim();
        if (description == null || description.isEmpty) {
          continue;
        }
        steps.add(description);
        final timeValue = step['time'];
        final time = (timeValue is num) ? timeValue.toInt() : 0;
        durations.add(time < 0 ? 0 : time);
      }
      return (steps, durations);
    }

    final steps = rawList.map((e) => e.toString()).toList();
    return (steps, List<int>.filled(steps.length, 0));
  }
}
