import 'package:flutter/material.dart';

import '../models/app_enums.dart';
import '../models/cooking_result.dart';
import '../models/recipe_option.dart';
import 'interactive_cooking_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
    required this.onCookingFinished,
  });

  final RecipeOption recipe;
  final ValueChanged<CookingResult> onCookingFinished;

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  final Map<String, double> _selectedAmounts = {};

  @override
  void initState() {
    super.initState();
    for (final i in widget.recipe.ingredients) {
      _selectedAmounts[i.name] = i.amount.toDouble();
    }
  }

  double get _currentCalories {
    double sum = 0;
    for (final i in widget.recipe.ingredients) {
      final selected = _selectedAmounts[i.name] ?? i.amount.toDouble();
      if (i.amount > 0) sum += i.calories * (selected / i.amount);
    }
    return sum;
  }

  double get _currentProteins {
    double sum = 0;
    for (final i in widget.recipe.ingredients) {
      final selected = _selectedAmounts[i.name] ?? i.amount.toDouble();
      if (i.amount > 0) sum += i.proteins * (selected / i.amount);
    }
    return sum;
  }

  double get _currentFats {
    double sum = 0;
    for (final i in widget.recipe.ingredients) {
      final selected = _selectedAmounts[i.name] ?? i.amount.toDouble();
      if (i.amount > 0) sum += i.fats * (selected / i.amount);
    }
    return sum;
  }

  double get _currentCarbs {
    double sum = 0;
    for (final i in widget.recipe.ingredients) {
      final selected = _selectedAmounts[i.name] ?? i.amount.toDouble();
      if (i.amount > 0) sum += i.carbs * (selected / i.amount);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${_currentCalories.round()} ккал')),
              Chip(label: Text('${_currentProteins.toStringAsFixed(1)} белки')),
              Chip(label: Text('${_currentFats.toStringAsFixed(1)} жиры')),
              Chip(label: Text('${_currentCarbs.toStringAsFixed(1)} углеводы')),
              Chip(label: Text('${widget.recipe.cookMinutes} мин')),
              Chip(label: Text(widget.recipe.needsStove ? 'Нужна плита' : 'Плита не нужна')),
              Chip(label: Text(_difficultyLabel(widget.recipe.difficulty))),
            ],
          ),
          const SizedBox(height: 16),
          Text('Ингредиенты (Настройте количество)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...widget.recipe.ingredients.map((i) {
            final val = _selectedAmounts[i.name] ?? i.amount.toDouble();
            final maxVal = i.amount * 1.5;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${val.round()} ${i.unit}'),
                      ],
                    ),
                    Slider(
                      value: val,
                      min: i.minAmount.toDouble(),
                      max: maxVal > i.minAmount ? maxVal : i.minAmount.toDouble() + 1,
                      divisions: maxVal > i.minAmount ? (maxVal - i.minAmount).round().clamp(1, 100) : 1,
                      label: '${val.round()} ${i.unit}',
                      onChanged: (newVal) {
                        setState(() {
                          _selectedAmounts[i.name] = newVal;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          Text('Шаги приготовления', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...widget.recipe.steps.asMap().entries.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, child: Text('${entry.key + 1}')),
                title: Text(entry.value),
              )),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Готовить интерактивно'),
            onPressed: () async {
              Map<String, int> consumptionByIngredient = {};
              for (final i in widget.recipe.ingredients) {
                final selected = _selectedAmounts[i.name] ?? i.amount.toDouble();
                final percent = i.amount > 0 ? (selected / i.amount * 100).round() : 100;
                consumptionByIngredient[i.name] = percent;
              }

              final result = await Navigator.push<CookingResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => InteractiveCookingScreen(
                    recipe: widget.recipe,
                    consumption: consumptionByIngredient,
                    finalCalories: _currentCalories,
                    finalProteins: _currentProteins,
                    finalFats: _currentFats,
                    finalCarbs: _currentCarbs,
                  ),
                ),
              );

              if (result != null && context.mounted) {
                final messenger = ScaffoldMessenger.maybeOf(context);
                Future<void>.microtask(() {
                  if (!context.mounted) {
                    return;
                  }
                  widget.onCookingFinished(result);
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Готовка завершена! Блюдо помещено в холодильник, вы можете съесть его там.'),
                    ),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(RecipeDifficulty difficulty) {
    return switch (difficulty) {
      RecipeDifficulty.easy => 'Сложность: легкая',
      RecipeDifficulty.medium => 'Сложность: средняя',
      RecipeDifficulty.hard => 'Сложность: высокая',
    };
  }
}
