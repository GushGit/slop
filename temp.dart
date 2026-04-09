
import 'dart:io';
void main() {
  var file = File('lib/services/recipe_repository.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(RegExp(r'\s*calories:\s*\d+,\n\s*proteins:\s*[\d.]+,\n\s*fats:\s*[\d.]+,\n\s*carbs:\s*[\d.]+,\n'), '\n');

  List<List<String>> replacements = [
    [
      "RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: 'г', minAmount: 30, calories: 230, proteins: 8.0, fats: 4.0, carbs: 40.0),"
    ],
    [
      "RecipeIngredient(name: 'Ягоды', amount: 80, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Ягоды', amount: 80, unit: 'г', minAmount: 0, calories: 150, proteins: 5.0, fats: 4.0, carbs: 18.0),"
    ],
    [
      "RecipeIngredient(name: 'Творог', amount: 200, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Творог', amount: 200, unit: 'г', minAmount: 100, calories: 320, proteins: 30.0, fats: 10.0, carbs: 6.0),"
    ],
    [
      "RecipeIngredient(name: 'Банан', amount: 1, unit: 'шт', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Банан', amount: 1, unit: 'шт', minAmount: 0, calories: 100, proteins: 2.0, fats: 1.0, carbs: 20.0),"
    ],
    [
      "RecipeIngredient(name: 'Куриная грудка', amount: 180, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Куриная грудка', amount: 180, unit: 'г', minAmount: 100, calories: 300, proteins: 40.0, fats: 4.0, carbs: 0.0),"
    ],
    [
      "RecipeIngredient(name: 'Киноа', amount: 70, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Киноа', amount: 70, unit: 'г', minAmount: 30, calories: 310, proteins: 9.0, fats: 10.0, carbs: 58.0),"
    ],
    [
      "RecipeIngredient(name: 'Паста', amount: 100, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Паста', amount: 100, unit: 'г', minAmount: 50, calories: 360, proteins: 12.0, fats: 2.0, carbs: 72.0),"
    ],
    [
      "RecipeIngredient(name: 'Говядина', amount: 180, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Говядина', amount: 180, unit: 'г', minAmount: 100, calories: 500, proteins: 35.0, fats: 30.0, carbs: 20.0),"
    ],
    [
      "RecipeIngredient(name: 'Йогурт питьевой', amount: 250, unit: 'мл', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Йогурт питьевой', amount: 250, unit: 'мл', minAmount: 100, calories: 180, proteins: 10.0, fats: 4.0, carbs: 21.0),"
    ],
    [
      "RecipeIngredient(name: 'Лосось', amount: 180, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Лосось', amount: 180, unit: 'г', minAmount: 100, calories: 400, proteins: 35.0, fats: 25.0, carbs: 0.0),"
    ],
    [
      "RecipeIngredient(name: 'Брокколи', amount: 150, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Брокколи', amount: 150, unit: 'г', minAmount: 50, calories: 140, proteins: 8.0, fats: 3.0, carbs: 22.0),"
    ],
    [
      "RecipeIngredient(name: 'Рис', amount: 100, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Рис', amount: 100, unit: 'г', minAmount: 50, calories: 360, proteins: 8.0, fats: 1.0, carbs: 76.0),"
    ],
    [
      "RecipeIngredient(name: 'Индейка', amount: 200, unit: 'г', defaultConsumptionPercent: 100),",
      "RecipeIngredient(name: 'Индейка', amount: 200, unit: 'г', minAmount: 100, calories: 400, proteins: 43.0, fats: 16.0, carbs: 20.0),"
    ]
  ];

  for (var r in replacements) {
    if (!content.contains(r[0])) {
      print('Missing: ${r[0]}');
    }
    content = content.replaceAll(r[0], r[1]);
  }
  file.writeAsStringSync(content);
}

