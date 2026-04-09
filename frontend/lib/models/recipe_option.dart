import 'app_enums.dart';
import 'recipe_ingredient.dart';

class RecipeOption {
  const RecipeOption({
    required this.id,
    required this.title,
    required this.mealType,
    required this.supportedGoals,
    required this.cookMinutes,
    required this.imageUrl,
    required this.needsStove,
    required this.difficulty,
    required this.videoUrl,
    required this.ingredients,
    required this.steps,
    required this.stepDurationsSec,
  });

  final String id;
  final String title;
  final MealType mealType;
  final Set<GoalMode> supportedGoals;
  final int cookMinutes;
  final String imageUrl;
  final bool needsStove;
  final RecipeDifficulty difficulty;
  final String videoUrl;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<int> stepDurationsSec;

  int get calories => ingredients.fold(0, (sum, i) => sum + i.calories.round());
  double get proteins => ingredients.fold(0.0, (sum, i) => sum + i.proteins);
  double get fats => ingredients.fold(0.0, (sum, i) => sum + i.fats);
  double get carbs => ingredients.fold(0.0, (sum, i) => sum + i.carbs);
}
