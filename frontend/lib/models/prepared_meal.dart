class PreparedMeal {
  const PreparedMeal({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.remainingPercent,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.cookedAt,
  });

  final String id;
  final String title;
  final String imageUrl;
  final int remainingPercent;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
  final DateTime cookedAt;

  PreparedMeal consumePercent(int percent) {
    final bounded = percent.clamp(0, remainingPercent);
    final nextRemaining = (remainingPercent - bounded).clamp(0, 100);
    return PreparedMeal(
      id: id,
      title: title,
      imageUrl: imageUrl,
      remainingPercent: nextRemaining,
      calories: calories,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
      cookedAt: cookedAt,
    );
  }
}
