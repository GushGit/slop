class CookingResult {
  const CookingResult({
    required this.consumptionPercentByIngredient,
    required this.finalCalories,
    required this.finalProteins,
    required this.finalFats,
    required this.finalCarbs,
  });

  final Map<String, int> consumptionPercentByIngredient;
  final double finalCalories;
  final double finalProteins;
  final double finalFats;
  final double finalCarbs;
}
