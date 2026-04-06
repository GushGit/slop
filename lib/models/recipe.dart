class Recipe {
  final String title;
  final List<String> availableIngredients;
  final List<String> missingIngredients;
  final List<String> steps;

  Recipe({
    required this.title,
    required this.availableIngredients,
    required this.missingIngredients,
    required this.steps,
  });
}