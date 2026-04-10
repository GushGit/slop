class PantryItem {
  const PantryItem({
    required this.name,
    required this.remainingPercent,
    required this.expiresInDays,
    required this.priceRub,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final String name;
  final int remainingPercent;
  final int expiresInDays;
  final double priceRub;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;

  PantryItem consumePercent(int consumedPercent) {
    final bounded = consumedPercent.clamp(0, 150);
    final updated = remainingPercent - bounded;
    return PantryItem(
      name: name,
      remainingPercent: updated.clamp(0, 100),
      expiresInDays: expiresInDays,
      priceRub: priceRub,
      calories: calories,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
    );
  }


  Map<String, dynamic> toJson() => {
    'name': name,
    'remainingPercent': remainingPercent,
    'expiresInDays': expiresInDays,
    'priceRub': priceRub,
    'calories': calories,
    'proteins': proteins,
    'fats': fats,
    'carbs': carbs,
  };


  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    name: json['name'] as String? ?? '',
    remainingPercent: (json['remainingPercent'] as num?)?.toInt() ?? 100,
    expiresInDays: (json['expiresInDays'] as num?)?.toInt() ?? 7,
    priceRub: (json['priceRub'] as num?)?.toDouble() ?? 0.0,
    calories: (json['calories'] as num?)?.toInt() ?? 0,
    proteins: (json['proteins'] as num?)?.toDouble() ?? 0.0,
    fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
    carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
  );

}
