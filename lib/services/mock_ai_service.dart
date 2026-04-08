import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/meal.dart';

class MockAIService {
  // Имитация сканирования холодильника (целиком)
  static Future<List<Ingredient>> scanFridge() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      Ingredient(name: "яйца", confidence: 0.97),
      Ingredient(name: "помидоры", confidence: 0.93),
      Ingredient(name: "сыр", confidence: 0.88),
      Ingredient(name: "курица", confidence: 0.91),
    ];
  }

  // НОВОЕ: Имитация добавления новых продуктов разными методами
  static Future<List<Ingredient>> scanNewProducts(String method) async {
    await Future.delayed(const Duration(seconds: 2)); // Имитация обработки
    switch (method) {
      case 'receipt':
        return [
          Ingredient(name: "Молоко 1л", confidence: 0.99),
          Ingredient(name: "Хлеб бородинский", confidence: 0.95),
          Ingredient(name: "Масло сливочное", confidence: 0.98),
        ];
      case 'barcode':
        return [
          Ingredient(name: "Йогурт питьевой", confidence: 1.0),
        ];
      case 'photo':
      default:
        return [
          Ingredient(name: "Яблоки", confidence: 0.92),
          Ingredient(name: "Бананы", confidence: 0.89),
        ];
    }
  }

  static Future<List<Recipe>> getRecipes(List<Ingredient> ingredients) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Recipe(
        title: "Яичница с помидорами",
        availableIngredients: ["яйца", "помидоры"],
        missingIngredients: [],
        steps: [
          "Нарежьте помидоры небольшими кусочками.",
          "Разогрейте сковороду на среднем огне.",
          "Обжарьте помидоры 2 минуты.",
          "Вбейте яйца и готовьте до готовности."
        ],
      ),
      Recipe(
        title: "Курица с сыром",
        availableIngredients: ["курица", "сыр"],
        missingIngredients: ["шпинат"],
        steps: [
          "Отобейте курицу.",
          "Посыпьте сыром.",
          "Запекайте 20 минут при 180 градусах."
        ],
      ),
    ];
  }

  static Future<List<Meal>> generateMealPlan(String goal) async {
    await Future.delayed(const Duration(seconds: 1));

    final normalizedGoal = goal.toLowerCase();

    if (normalizedGoal.contains('похуд')) {
      return [
        Meal(type: "Завтрак", dish: "Омлет с шпинатом"),
        Meal(type: "Обед", dish: "Курица с киноа"),
        Meal(type: "Ужин", dish: "Лосось и овощи"),
      ];
    }

    if (normalizedGoal.contains('набор')) {
      return [
        Meal(type: "Завтрак", dish: "Творог с бананом и орехами"),
        Meal(type: "Обед", dish: "Паста с говядиной"),
        Meal(type: "Ужин", dish: "Рис с индейкой"),
      ];
    }

    return [
      Meal(type: "Завтрак", dish: "Овсянка с ягодами"),
      Meal(type: "Обед", dish: "Куриный салат"),
      Meal(type: "Ужин", dish: "Рыба с овощами"),
    ];
  }
}