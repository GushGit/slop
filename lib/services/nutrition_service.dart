import '../models/app_enums.dart';
import '../models/day_nutrition_progress.dart';
import '../models/meal_log_entry.dart';
import '../models/nutrition_targets.dart';

class NutritionService {
  NutritionTargets calculateTargets({
    required int weight,
    required int height,
    required int age,
    required double activityMultiplier,
    required GoalMode goalMode,
  }) {
    final bmr = 10 * weight + 6.25 * height - 5 * age;
    final tdee = bmr * activityMultiplier;

    final calories = switch (goalMode) {
      GoalMode.weightLoss => (tdee - 450).clamp(1200, 4500),
      GoalMode.maintain => tdee.clamp(1200, 4500),
      GoalMode.massGain => (tdee + 300).clamp(1200, 4500),
    }.toDouble();

    final proteinsPerKg = switch (goalMode) {
      GoalMode.weightLoss => 2.0,
      GoalMode.maintain => 1.7,
      GoalMode.massGain => 1.8,
    };

    final proteins = proteinsPerKg * weight;
    final fats = 0.8 * weight;
    var carbs = (calories - proteins * 4 - fats * 9) / 4;
    if (carbs < 80) {
      carbs = 80;
    }

    return NutritionTargets(
      calories: calories,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
    );
  }

  List<DayNutritionProgress> generateProgress({
    required NutritionTargets targets,
    required DateTime fromDate,
    int days = 35,
  }) {
    const factors = [0.84, 0.92, 1.03, 0.96, 1.08, 0.9, 0.95];

    return List.generate(days, (index) {
      final date = fromDate.subtract(Duration(days: days - index - 1));
      final factor = factors[index % factors.length];

      final meals = [
        MealLogEntry(
          recipeTitle: 'Завтрак',
          calories: targets.calories * 0.25 * factor,
          proteins: targets.proteins * 0.25 * factor,
          fats: targets.fats * 0.25 * factor,
          carbs: targets.carbs * 0.25 * factor,
        ),
        MealLogEntry(
          recipeTitle: 'Обед',
          calories: targets.calories * 0.4 * factor,
          proteins: targets.proteins * 0.4 * factor,
          fats: targets.fats * 0.4 * factor,
          carbs: targets.carbs * 0.4 * factor,
        ),
        MealLogEntry(
          recipeTitle: 'Ужин',
          calories: targets.calories * 0.35 * factor,
          proteins: targets.proteins * 0.35 * factor,
          fats: targets.fats * 0.35 * factor,
          carbs: targets.carbs * 0.35 * factor,
        ),
      ];

      return DayNutritionProgress(
        date: date,
        calories: meals.fold(0, (sum, m) => sum + m.calories),
        proteins: meals.fold(0, (sum, m) => sum + m.proteins),
        fats: meals.fold(0, (sum, m) => sum + m.fats),
        carbs: meals.fold(0, (sum, m) => sum + m.carbs),
        meals: meals,
      );
    });
  }
}
