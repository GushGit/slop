import 'package:flutter/material.dart';

import '../../models/app_enums.dart';
import '../../models/pantry_item.dart';
import '../../models/prepared_meal.dart';
import '../../models/scan_history_entry.dart';

class FridgeTab extends StatelessWidget {
  const FridgeTab({
    super.key,
    required this.viewType,
    required this.onViewTypeChanged,
    required this.items,
    required this.preparedMeals,
    required this.onConsumePreparedMeal,
    required this.history,
    required this.onSuggestRecipes,
    required this.isSuggestingRecipes,
  });

  final FridgeViewType viewType;
  final ValueChanged<FridgeViewType> onViewTypeChanged;
  final List<PantryItem> items;
  final List<PreparedMeal> preparedMeals;
  final void Function(PreparedMeal meal, int consumedPercent) onConsumePreparedMeal;
  final List<ScanHistoryEntry> history;
  final Future<void> Function() onSuggestRecipes;
  final bool isSuggestingRecipes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
          Text('Электронный холодильник', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<FridgeViewType>(
          segments: [
              ButtonSegment(value: FridgeViewType.ingredients, label: Text('Ингредиенты')),
              ButtonSegment(value: FridgeViewType.readyMeals, label: Text('Готовые блюда')),
          ],
          selected: {viewType},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onViewTypeChanged(selection.first);
            }
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: isSuggestingRecipes ? null : onSuggestRecipes,
          icon: isSuggestingRecipes
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(isSuggestingRecipes ? 'Подбираем рецепты...' : 'Предложить рецепты'),
        ),
        const SizedBox(height: 12),
        if (viewType == FridgeViewType.ingredients)
          ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Остаток ${item.remainingPercent}% • срок ${item.expiresInDays} дн.'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          _infoRow('Оставшееся количество', '${item.remainingPercent}%'),
                          _infoRow('Срок годности', '${item.expiresInDays} дн.'),
                          _infoRow('Стоимость', '${item.priceRub.toStringAsFixed(0)} руб.'),
                          _infoRow(
                            'КБЖУ',
                            '${item.calories} / ${item.proteins.toStringAsFixed(1)} / ${item.fats.toStringAsFixed(1)} / ${item.carbs.toStringAsFixed(1)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
        else if (preparedMeals.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
                child: Text('Пока нет готовых блюд. Оставьте блюдо после готовки, и оно появится здесь.'),
            ),
          )
        else
          ...preparedMeals.map(
            (meal) => _ReadyMealCard(
              meal: meal,
              onConsume: (percent) => onConsumePreparedMeal(meal, percent),
            ),
          ),
        const SizedBox(height: 18),
          Text('История сканирования', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...history.map((entry) {
          final d = entry.scannedAt;
          final dt = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
              '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(entry.method),
                subtitle: Text('Добавлено: ${entry.addedCount} • $dt'),
            ),
          );
        }),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

}

class _ReadyMealCard extends StatefulWidget {
  const _ReadyMealCard({required this.meal, required this.onConsume});

  final PreparedMeal meal;
  final ValueChanged<int> onConsume;

  @override
  State<_ReadyMealCard> createState() => _ReadyMealCardState();
}

class _ReadyMealCardState extends State<_ReadyMealCard> {
  double _selectedPercent = 1;

  @override
  void initState() {
    super.initState();
    _selectedPercent = _initialSelected(widget.meal.remainingPercent);
  }

  @override
  void didUpdateWidget(covariant _ReadyMealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxSelectable = _maxSelectable(widget.meal.remainingPercent);
    if (_selectedPercent > maxSelectable) {
      _selectedPercent = maxSelectable;
    }
    if (_selectedPercent < 1) {
      _selectedPercent = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxSelectable = _maxSelectable(widget.meal.remainingPercent);
    final maxSelectableInt = maxSelectable.toInt();
    final calories = widget.meal.calories * _selectedPercent / 100;
    final proteins = widget.meal.proteins * _selectedPercent / 100;
    final fats = widget.meal.fats * _selectedPercent / 100;
    final carbs = widget.meal.carbs * _selectedPercent / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.meal.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Остаток блюда: ${widget.meal.remainingPercent}%'),
            const SizedBox(height: 8),
            Text('Съесть: ${_selectedPercent.round()}% (макс. $maxSelectableInt%)'),
            Slider(
              value: _selectedPercent,
              min: 1,
              max: maxSelectable,
              divisions: maxSelectableInt > 1 ? maxSelectableInt - 1 : null,
              label: '${_selectedPercent.round()}%',
              onChanged: (value) {
                setState(() {
                  _selectedPercent = value;
                });
              },
            ),
            Text(
              'КБЖУ порции: ${calories.toStringAsFixed(0)} / ${proteins.toStringAsFixed(1)} / ${fats.toStringAsFixed(1)} / ${carbs.toStringAsFixed(1)}',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => widget.onConsume(
                  _selectedPercent.round().clamp(1, maxSelectableInt),
                ),
                icon: const Icon(Icons.restaurant),
                label: const Text('Съесть'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxSelectable(int remainingPercent) {
    final bounded = remainingPercent.clamp(1, 100);
    return bounded.toDouble();
  }

  double _initialSelected(int remainingPercent) {
    final maxSelectable = _maxSelectable(remainingPercent);
    return maxSelectable < 50 ? maxSelectable : 50;
  }
}
