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


  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
    'minAmount': minAmount,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
  };


  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
    name: json['name'] as String? ?? '',
    amount: json['amount'] as num? ?? 0,
    unit: json['unit'] as String? ?? '',
    minAmount: json['minAmount'] as num? ?? 0,
    calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
    proteins: (json['proteins'] as num?)?.toDouble() ?? 0.0,
    fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
    carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
  );

}
