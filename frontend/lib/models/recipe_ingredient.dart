class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.minAmount,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final String name;
  final num amount;
  final String unit;
  final num minAmount;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
}
