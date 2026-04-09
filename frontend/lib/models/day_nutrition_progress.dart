import 'meal_log_entry.dart';

class DayNutritionProgress {
  const DayNutritionProgress({
    required this.date,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.meals,
  });

  final DateTime date;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final List<MealLogEntry> meals;

  DayNutritionProgress copyWith({
    DateTime? date,
    double? calories,
    double? proteins,
    double? fats,
    double? carbs,
    List<MealLogEntry>? meals,
  }) {
    return DayNutritionProgress(
      date: date ?? this.date,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
      meals: meals ?? this.meals,
    );
  }

  DayNutritionProgress addMeal(MealLogEntry meal) {
    return copyWith(
      calories: calories + meal.calories,
      proteins: proteins + meal.proteins,
      fats: fats + meal.fats,
      carbs: carbs + meal.carbs,
      meals: [...meals, meal],
    );
  }
}
