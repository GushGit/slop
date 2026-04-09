class MealLogEntry {
  const MealLogEntry({
    required this.recipeTitle,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final String recipeTitle;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
}
