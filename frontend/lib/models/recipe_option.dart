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


  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mealType': mealType.index,
    'supportedGoals': supportedGoals.map((e) => e.index).toList(),
    'cookMinutes': cookMinutes,
    'imageUrl': imageUrl,
    'needsStove': needsStove,
    'difficulty': difficulty.index,
    'videoUrl': videoUrl,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'steps': steps,
    'stepDurationsSec': stepDurationsSec,
  };


  factory RecipeOption.fromJson(Map<String, dynamic> json) => RecipeOption(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    mealType: MealType.values[(json['mealType'] as num?)?.toInt() ?? 0],
    supportedGoals: (json['supportedGoals'] as List<dynamic>?)?.map((e) => GoalMode.values[(e as num).toInt()]).toSet() ?? {},
    cookMinutes: (json['cookMinutes'] as num?)?.toInt() ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    needsStove: json['needsStove'] as bool? ?? false,
    difficulty: RecipeDifficulty.values[(json['difficulty'] as num?)?.toInt() ?? 0],
    videoUrl: json['videoUrl'] as String? ?? '',
    ingredients: (json['ingredients'] as List<dynamic>?)?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    steps: (json['steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    stepDurationsSec: (json['stepDurationsSec'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
  );

}
