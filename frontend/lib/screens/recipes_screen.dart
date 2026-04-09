import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'cooking_assistant_screen.dart';

class RecipesScreen extends StatelessWidget {
  final List<Ingredient> ingredients;
  final List<Recipe> recipes;

  const RecipesScreen({super.key, required this.ingredients, required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Что приготовить')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Найденные продукты:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ing = ingredients[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text('${ing.name} ${(ing.confidence * 100).toInt()}%'),
                    backgroundColor: Colors.green.shade100,
                  ),
                );
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Доступные рецепты:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      recipe.missingIngredients.isEmpty 
                        ? 'Все ингредиенты в наличии!' 
                        : 'Не хватает: ${recipe.missingIngredients.join(", ")}',
                      style: TextStyle(
                        color: recipe.missingIngredients.isEmpty ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    trailing: const Icon(Icons.play_circle_fill, color: Colors.green, size: 36),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CookingAssistantScreen(recipe: recipe),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}