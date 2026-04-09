import '../models/meal.dart';
import '../models/recipe_ingredient.dart';
import '../models/recipe_option.dart';
import '../models/app_enums.dart'; // To get GoalMode if defined there, or update if elsewhere

class RecipeRepository {
  List<RecipeOption> getRecipes({
    MealType? mealType,
    GoalMode? goalMode,
    List<String>? availableIngredientNames,
  }) {
    List<RecipeOption> filtered = availableRecipes.toList();
    if (mealType != null) {
      filtered = filtered.where((r) => r.mealType == mealType).toList();
    }
    if (goalMode != null) {
      filtered = filtered.where((r) => r.supportedGoals.contains(goalMode)).toList();
    }
    if (availableIngredientNames != null && availableIngredientNames.isNotEmpty) {
      // In a real app we might score them based on how many ingredients we have.
      // For now, simple return.
    }
    return filtered;
  }

  static final List<RecipeOption> availableRecipes = [
    RecipeOption(
      id: 'r1',
      title: 'Овсянка с бананом',
      mealType: MealType.breakfast,
      supportedGoals: {GoalMode.weightLoss, GoalMode.maintain, GoalMode.massGain},
      cookMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&q=80&w=600',
      needsStove: true,
      difficulty: RecipeDifficulty.easy,
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Dummy
      ingredients: [
        RecipeIngredient(
          name: 'Овсяные хлопья',
          
          unit: 'г',
          amount: 50.0,
          minAmount: 20.0,
          calories: 180,
          proteins: 6.0,
          fats: 3.5,
          carbs: 30.0,
        ),
        RecipeIngredient(
          name: 'Молоко',
          
          unit: 'мл',
          amount: 200.0,
          minAmount: 50.0,
          calories: 120,
          proteins: 6.0,
          fats: 6.0,
          carbs: 9.0,
        ),
        RecipeIngredient(
          name: 'Банан',
          
          unit: 'г',
          amount: 100.0,
          minAmount: 20.0,
          calories: 90,
          proteins: 1.0,
          fats: 0.5,
          carbs: 23.0,
        ),
      ],
      steps: [
        'Налейте молоко в кастрюлю.',
        'Доведите до кипения.',
        'Добавьте овсяные хлопья.',
        'Варите 5 минут.',
        'Нарежьте банан.',
      ],
      stepDurationsSec: [30, 120, 10, 300, 60],
    ),
    RecipeOption(
      id: 'r2',
      title: 'Куриная грудка с рисом',
      mealType: MealType.lunch,
      supportedGoals: {GoalMode.massGain, GoalMode.maintain},
      cookMinutes: 30,
      imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&q=80&w=600',
      needsStove: true,
      difficulty: RecipeDifficulty.medium,
      videoUrl: '',
      ingredients: [
        RecipeIngredient(
          name: 'Куриное филе',
          
          unit: 'г',
          amount: 200.0,
          minAmount: 50.0,
          calories: 220,
          proteins: 46.0,
          fats: 3.0,
          carbs: 0.0,
        ),
        RecipeIngredient(
          name: 'Рис',
          
          unit: 'г',
          amount: 50.0,
          minAmount: 20.0,
          calories: 180,
          proteins: 4.0,
          fats: 1.0,
          carbs: 39.0,
        ),
        RecipeIngredient(
          name: 'Специи',
          
          unit: 'г',
          amount: 5.0,
          minAmount: 1.0,
          calories: 10,
          proteins: 0.0,
          fats: 0.0,
          carbs: 2.0,
        ),
      ],
      steps: [
        'Промойте рис.',
        'Варите рис 20 минут.',
        'Нарежьте курицу.',
        'Обжарьте курицу со специями.',
      ],
      stepDurationsSec: [60, 1200, 120, 600],
    ),
    RecipeOption(
      id: 'r3',
      title: 'Легкий салат',
      mealType: MealType.dinner,
      supportedGoals: {GoalMode.weightLoss},
      cookMinutes: 10,
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=600',
      needsStove: false,
      difficulty: RecipeDifficulty.easy,
      videoUrl: '',
      ingredients: [
        RecipeIngredient(
          name: 'Огурцы',
          
          unit: 'г',
          amount: 100.0,
          minAmount: 20.0,
          calories: 15,
          proteins: 1.0,
          fats: 0.0,
          carbs: 3.0,
        ),
        RecipeIngredient(
          name: 'Помидоры',
          
          unit: 'г',
          amount: 150.0,
          minAmount: 30.0,
          calories: 25,
          proteins: 1.5,
          fats: 0.0,
          carbs: 5.0,
        ),
        RecipeIngredient(
          name: 'Оливковое масло',
          
          unit: 'г',
          amount: 10.0,
          minAmount: 1.0,
          calories: 90,
          proteins: 0.0,
          fats: 10.0,
          carbs: 0.0,
        ),
      ],
      steps: [
        'Нарежьте огурцы.',
        'Нарежьте помидоры.',
        'Смешайте овощи.',
        'Заправьте маслом.',
      ],
      stepDurationsSec: [60, 60, 30, 20],
    ),
  ];
}
