import 'package:flutter/material.dart';

import '../../models/app_enums.dart';
import '../../models/recipe_option.dart';

class RecipesTab extends StatelessWidget {
  const RecipesTab({
    super.key,
    required this.selectedMealType,
    required this.recipes,
    required this.goalModeLabel,
    required this.onMealTypeSelected,
    required this.onRecipeSelected,
  });

  final MealType selectedMealType;
  final List<RecipeOption> recipes;
  final String goalModeLabel;
  final ValueChanged<MealType> onMealTypeSelected;
  final ValueChanged<RecipeOption> onRecipeSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Подбор под цель: $goalModeLabel',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MealType.values.map((mealType) {
            final isSelected = mealType == selectedMealType;
            return ChoiceChip(
              selected: isSelected,
              label: Text(_mealTypeLabel(mealType)),
              onSelected: (_) => onMealTypeSelected(mealType),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (recipes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Для выбранного типа приема пищи рецептов пока нет.')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _RecipeTile(
                recipe: recipe,
                onTap: () => onRecipeSelected(recipe),
              );
            },
          ),
      ],
    );
  }

  String _mealTypeLabel(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => 'Завтрак',
      MealType.lunch => 'Обед',
      MealType.snack => 'Перекус',
      MealType.dinner => 'Ужин',
    };
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.onTap});

  final RecipeOption recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black12,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: recipe.imageUrl.trim().isEmpty
                    ? Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.restaurant_menu, size: 40),
                      )
                    : Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported, size: 40),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: _OverlayLabel(text: '${recipe.cookMinutes} мин'),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: _OverlayLabel(text: '${recipe.calories} ккал'),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  color: Colors.black87,
                ),
                child: Text(
                  recipe.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
