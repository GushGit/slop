import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../models/meal.dart';
import '../models/recipe.dart';
import '../services/mock_ai_service.dart';
import 'cooking_assistant_screen.dart';

enum GoalMode { weightLoss, massGain }

enum AppLanguage { russian, english }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.appLanguage,
    required this.onThemeModeChanged,
    required this.onLanguageChanged,
  });

  final ThemeMode themeMode;
  final AppLanguage appLanguage;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  GoalMode _goalMode = GoalMode.weightLoss;

  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  double _activityMultiplier = 1.4;
  NutritionTargets? _targets;
  List<_DailyProgress> _dailyProgress = [];

  List<Meal> _mealPlan = [];
  bool _isLoadingPlan = true;

  final List<PantryItem> _pantryItems = [
    PantryItem(
      name: 'Куриная грудка',
      remainingPercent: 70,
      expiresInDays: 2,
      priceRub: 289,
      calories: 165,
      proteins: 31,
      fats: 3.6,
      carbs: 0,
    ),
    PantryItem(
      name: 'Греческий йогурт',
      remainingPercent: 45,
      expiresInDays: 4,
      priceRub: 119,
      calories: 97,
      proteins: 9,
      fats: 5,
      carbs: 3.5,
    ),
    PantryItem(
      name: 'Овсяные хлопья',
      remainingPercent: 85,
      expiresInDays: 20,
      priceRub: 89,
      calories: 352,
      proteins: 12,
      fats: 6,
      carbs: 62,
    ),
  ];

  final List<_ScanHistoryEntry> _scanHistory = [
    _ScanHistoryEntry(
      method: 'Сканер холодильника',
      addedCount: 4,
      scannedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _ScanHistoryEntry(
      method: 'Штрихкод',
      addedCount: 1,
      scannedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];

  static const List<_ActivityPreset> _activityPresets = [
    _ActivityPreset(multiplier: 1.2, ru: 'Низкая активность', en: 'Low activity'),
    _ActivityPreset(multiplier: 1.4, ru: 'Умеренная активность', en: 'Moderate activity'),
    _ActivityPreset(multiplier: 1.6, ru: 'Высокая активность', en: 'High activity'),
    _ActivityPreset(multiplier: 1.8, ru: 'Очень высокая активность', en: 'Very high activity'),
  ];

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: '75');
    _heightController = TextEditingController(text: '178');
    _ageController = TextEditingController(text: '30');
    _loadMealPlan();
    _calculateNutrition(showSnackBar: false);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadMealPlan() async {
    setState(() => _isLoadingPlan = true);
    final plan = await MockAIService.generateMealPlan(_goalModeRuLabel(_goalMode));
    if (!mounted) {
      return;
    }

    setState(() {
      _mealPlan = plan;
      _isLoadingPlan = false;
    });
  }

  String _tr(String ru, String en) {
    return widget.appLanguage == AppLanguage.russian ? ru : en;
  }

  String _goalModeRuLabel(GoalMode mode) {
    return mode == GoalMode.weightLoss ? 'Похудение' : 'Набор массы';
  }

  String _goalModeLabel(GoalMode mode) {
    if (mode == GoalMode.weightLoss) {
      return _tr('Похудение', 'Weight loss');
    }
    return _tr('Набор массы', 'Mass gain');
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return _tr('Системная', 'System');
      case ThemeMode.light:
        return _tr('Светлая', 'Light');
      case ThemeMode.dark:
        return _tr('Темная', 'Dark');
    }
  }

  String _languageLabel(AppLanguage language) {
    return language == AppLanguage.russian ? 'Русский' : 'English';
  }

  void _setGoalMode(GoalMode mode) {
    if (_goalMode == mode) {
      return;
    }

    setState(() {
      _goalMode = mode;
    });

    _loadMealPlan();
    _calculateNutrition(showSnackBar: false);
  }

  void _calculateNutrition({bool showSnackBar = true}) {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    final age = double.tryParse(_ageController.text.replaceAll(',', '.'));

    if (weight == null || height == null || age == null) {
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr('Введите корректные параметры для расчета.', 'Please enter valid numbers to calculate.'),
            ),
          ),
        );
      }
      return;
    }

    final bmr = 10 * weight + 6.25 * height - 5 * age;
    final tdee = bmr * _activityMultiplier;
    final adjustedCalories = _goalMode == GoalMode.weightLoss ? tdee - 450 : tdee + 300;
    final targetCalories = adjustedCalories.clamp(1200, 4500).toDouble();

    final proteins = (_goalMode == GoalMode.weightLoss ? 2.0 : 1.8) * weight;
    final fats = 0.8 * weight;
    var carbs = (targetCalories - proteins * 4 - fats * 9) / 4;
    if (carbs < 80) {
      carbs = 80;
    }

    final newTargets = NutritionTargets(
      calories: targetCalories,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
    );

    setState(() {
      _targets = newTargets;
      _dailyProgress = _generateDailyProgress(newTargets);
    });

    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('КБЖУ пересчитаны.', 'Calories and macros updated.'),
          ),
        ),
      );
    }
  }

  List<_DailyProgress> _generateDailyProgress(NutritionTargets targets) {
    const factors = [0.85, 0.92, 1.02, 0.97, 1.08, 0.9, 0.95];
    final now = DateTime.now();

    return List.generate(factors.length, (index) {
      final day = now.subtract(Duration(days: factors.length - index - 1));
      final factor = factors[index];

      return _DailyProgress(
        day: day,
        calories: targets.calories * factor,
        proteins: targets.proteins * (factor - 0.04),
        fats: targets.fats * factor,
        carbs: targets.carbs * (factor + 0.03),
      );
    });
  }

  Recipe _recipeFromMeal(Meal meal) {
    switch (meal.dish) {
      case 'Омлет с шпинатом':
        return Recipe(
          title: meal.dish,
          availableIngredients: ['яйца', 'шпинат', 'сыр'],
          missingIngredients: const [],
          steps: const [
            'Взбейте 2 яйца с щепоткой соли.',
            'Обжарьте шпинат 1 минуту на среднем огне.',
            'Влейте яйца, посыпьте сыром и готовьте под крышкой 4 минуты.',
          ],
        );
      case 'Курица с киноа':
        return Recipe(
          title: meal.dish,
          availableIngredients: ['курица', 'киноа', 'огурец'],
          missingIngredients: const [],
          steps: const [
            'Отварите киноа до готовности.',
            'Запеките куриную грудку 18 минут при 190C.',
            'Соберите боул: киноа, курица, свежие овощи и зелень.',
          ],
        );
      case 'Лосось и овощи':
        return Recipe(
          title: meal.dish,
          availableIngredients: ['лосось', 'брокколи', 'перец'],
          missingIngredients: const [],
          steps: const [
            'Разогрейте духовку до 200C.',
            'Добавьте к рыбе специи и сок лимона.',
            'Запекайте рыбу и овощи 15 минут.',
          ],
        );
      case 'Творог с бананом и орехами':
        return Recipe(
          title: meal.dish,
          availableIngredients: ['творог', 'банан', 'орехи'],
          missingIngredients: const [],
          steps: const [
            'Нарежьте банан кружками.',
            'Смешайте творог с бананом в глубокой миске.',
            'Добавьте орехи и подавайте.',
          ],
        );
      case 'Паста с говядиной':
        return Recipe(
          title: meal.dish,
          availableIngredients: ['паста', 'говядина', 'томатный соус'],
          missingIngredients: const [],
          steps: const [
            'Отварите пасту до состояния al dente.',
            'Обжарьте говядину до румяной корочки.',
            'Добавьте соус и соедините с пастой.',
          ],
        );
      case 'Рис с индейкой':
        return Recipe(
          title: meal.dish,
          availableIngredients: ['рис', 'индейка', 'овощи'],
          missingIngredients: const [],
          steps: const [
            'Отварите рис до мягкости.',
            'Обжарьте индейку с овощами 8-10 минут.',
            'Смешайте рис с индейкой и подавайте горячим.',
          ],
        );
      default:
        return Recipe(
          title: meal.dish,
          availableIngredients: const [],
          missingIngredients: const [],
          steps: const [
            'Подготовьте продукты и рабочее место.',
            'Готовьте блюдо на среднем огне, периодически помешивая.',
            'Проверьте готовность и подавайте.',
          ],
        );
    }
  }

  int _mealCalories(Meal meal) {
    if (_goalMode == GoalMode.weightLoss) {
      switch (meal.type) {
        case 'Завтрак':
          return 420;
        case 'Обед':
          return 610;
        case 'Ужин':
          return 560;
        default:
          return 500;
      }
    }

    switch (meal.type) {
      case 'Завтрак':
        return 620;
      case 'Обед':
        return 880;
      case 'Ужин':
        return 760;
      default:
        return 700;
    }
  }

  void _openCookingAssistant(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookingAssistantScreen(recipe: recipe),
      ),
    );
  }

  void _showScanOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(_tr('Сфотографировать продукты', 'Scan by photo')),
                subtitle: Text(_tr('Быстрое распознавание по фото', 'Quick camera recognition')),
                onTap: () {
                  _scanProducts(method: 'photo', methodLabel: _tr('Фото', 'Photo'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(_tr('Распознать чек', 'Scan receipt')),
                subtitle: Text(_tr('Добавить покупки из чека', 'Add products from receipt')),
                onTap: () {
                  _scanProducts(method: 'receipt', methodLabel: _tr('Чек', 'Receipt'));
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(_tr('Штрихкод / QR', 'Barcode / QR')),
                subtitle: Text(_tr('Точное добавление одной позиции', 'Precise single item import')),
                onTap: () {
                  _scanProducts(method: 'barcode', methodLabel: _tr('Штрихкод', 'Barcode'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanProducts({
    required String method,
    required String methodLabel,
  }) async {
    Navigator.pop(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(_tr('Сканирование и анализ...', 'Scanning and analyzing...')),
              ),
            ],
          ),
        );
      },
    );

    final scannedIngredients = await MockAIService.scanNewProducts(method);

    if (!mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    final newItems = scannedIngredients
        .map((ingredient) => _ingredientToPantryItem(ingredient))
        .toList();

    setState(() {
      _pantryItems.insertAll(0, newItems);
      _scanHistory.insert(
        0,
        _ScanHistoryEntry(
          method: methodLabel,
          addedCount: newItems.length,
          scannedAt: DateTime.now(),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            'Добавлено продуктов: ${newItems.length}',
            'Products added: ${newItems.length}',
          ),
        ),
      ),
    );
  }

  PantryItem _ingredientToPantryItem(Ingredient ingredient) {
    final name = ingredient.name.toLowerCase();

    if (name.contains('молоко')) {
      return PantryItem(
        name: ingredient.name,
        remainingPercent: 100,
        expiresInDays: 6,
        priceRub: 109,
        calories: 60,
        proteins: 3,
        fats: 3.2,
        carbs: 4.7,
      );
    }
    if (name.contains('хлеб')) {
      return PantryItem(
        name: ingredient.name,
        remainingPercent: 90,
        expiresInDays: 4,
        priceRub: 74,
        calories: 242,
        proteins: 8,
        fats: 1.5,
        carbs: 49,
      );
    }
    if (name.contains('масло')) {
      return PantryItem(
        name: ingredient.name,
        remainingPercent: 100,
        expiresInDays: 20,
        priceRub: 199,
        calories: 748,
        proteins: 0.5,
        fats: 82,
        carbs: 0.8,
      );
    }
    if (name.contains('йогурт')) {
      return PantryItem(
        name: ingredient.name,
        remainingPercent: 100,
        expiresInDays: 7,
        priceRub: 95,
        calories: 88,
        proteins: 3.5,
        fats: 2.5,
        carbs: 13,
      );
    }
    if (name.contains('яблок')) {
      return PantryItem(
        name: ingredient.name,
        remainingPercent: 100,
        expiresInDays: 10,
        priceRub: 149,
        calories: 47,
        proteins: 0.4,
        fats: 0.4,
        carbs: 9.8,
      );
    }
    if (name.contains('банан')) {
      return PantryItem(
        name: ingredient.name,
        remainingPercent: 100,
        expiresInDays: 5,
        priceRub: 139,
        calories: 89,
        proteins: 1.1,
        fats: 0.3,
        carbs: 22.8,
      );
    }

    final confidenceScore = (ingredient.confidence * 100).round();
    var remaining = 55 + confidenceScore ~/ 2;
    if (remaining > 100) {
      remaining = 100;
    }

    return PantryItem(
      name: ingredient.name,
      remainingPercent: remaining,
      expiresInDays: 2 + confidenceScore % 6,
      priceRub: (95 + confidenceScore).toDouble(),
      calories: 90 + confidenceScore ~/ 3,
      proteins: 3 + (confidenceScore % 10) / 2,
      fats: 2 + (confidenceScore % 6) / 2,
      carbs: 8 + (confidenceScore % 14).toDouble(),
    );
  }

  String _tabTitle() {
    switch (_selectedIndex) {
      case 0:
        return _tr('Рецепты', 'Recipes');
      case 1:
        return _tr('Ингредиенты', 'Ingredients');
      case 2:
        return _tr('Цели и КБЖУ', 'Goals and macros');
      case 3:
        return _tr('Настройки', 'Settings');
      default:
        return 'Reciper AI';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month $hour:$minute';
  }

  String _formatDay(DateTime dateTime) {
    const ruDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = dateTime.weekday - 1;
    return widget.appLanguage == AppLanguage.russian ? ruDays[index] : enDays[index];
  }

  Widget _buildRecipesTab() {
    if (_isLoadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mealPlan.isEmpty) {
      return Center(
        child: Text(_tr('Пока нет рекомендаций', 'No recommendations yet')),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMealPlan,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            _tr('Предложения по вашему плану', 'Suggestions for your plan'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              'Текущий режим: ${_goalModeLabel(_goalMode)}',
              'Current mode: ${_goalModeLabel(_goalMode)}',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ..._mealPlan.map((meal) {
            final recipe = _recipeFromMeal(meal);
            final calories = _mealCalories(meal);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.restaurant_menu),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.dish,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meal.type,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text('$calories ${_tr('ккал', 'kcal')}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe.steps.first,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_tr('Режим готовки', 'Cooking mode')),
                        onPressed: () => _openCookingAssistant(recipe),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text(
          _tr('Текущие продукты', 'Current products'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ..._pantryItems.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _tr(
                  'Остаток ${item.remainingPercent}% • срок ${item.expiresInDays} дн.',
                  'Left ${item.remainingPercent}% • expiry ${item.expiresInDays} days',
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        _tr('Оставшееся количество', 'Remaining amount'),
                        '${item.remainingPercent}%',
                      ),
                      _buildInfoRow(
                        _tr('Срок годности', 'Expiry period'),
                        _tr('${item.expiresInDays} дн.', '${item.expiresInDays} days'),
                      ),
                      _buildInfoRow(
                        _tr('Стоимость', 'Cost'),
                        '${item.priceRub.toStringAsFixed(0)} ${_tr('руб.', 'RUB')}',
                      ),
                      _buildInfoRow(
                        _tr('КБЖУ', 'Calories and macros'),
                        '${item.calories} / ${item.proteins.toStringAsFixed(1)} / ${item.fats.toStringAsFixed(1)} / ${item.carbs.toStringAsFixed(1)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 18),
        Text(
          _tr('История сканирования', 'Scan history'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ..._scanHistory.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(entry.method),
              subtitle: Text(
                _tr(
                  'Добавлено: ${entry.addedCount} • ${_formatDateTime(entry.scannedAt)}',
                  'Added: ${entry.addedCount} • ${_formatDateTime(entry.scannedAt)}',
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  Widget _buildGoalsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          _tr('Выберите режим', 'Choose your mode'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SegmentedButton<GoalMode>(
          segments: [
            ButtonSegment<GoalMode>(
              value: GoalMode.weightLoss,
              label: Text(_tr('Похудение', 'Weight loss')),
              icon: const Icon(Icons.trending_down),
            ),
            ButtonSegment<GoalMode>(
              value: GoalMode.massGain,
              label: Text(_tr('Набор', 'Mass gain')),
              icon: const Icon(Icons.fitness_center),
            ),
          ],
          selected: {_goalMode},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            _setGoalMode(selection.first);
          },
        ),
        const SizedBox(height: 20),
        Text(
          _tr('Расчет КБЖУ', 'Calories and macros calculation'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        _buildNumberField(
          controller: _weightController,
          label: _tr('Вес (кг)', 'Weight (kg)'),
          hint: _tr('Например, 75', 'For example, 75'),
        ),
        const SizedBox(height: 10),
        _buildNumberField(
          controller: _heightController,
          label: _tr('Рост (см)', 'Height (cm)'),
          hint: _tr('Например, 178', 'For example, 178'),
        ),
        const SizedBox(height: 10),
        _buildNumberField(
          controller: _ageController,
          label: _tr('Возраст', 'Age'),
          hint: _tr('Например, 30', 'For example, 30'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<double>(
          initialValue: _activityMultiplier,
          decoration: InputDecoration(
            labelText: _tr('Активность', 'Activity'),
          ),
          items: _activityPresets.map((preset) {
            return DropdownMenuItem<double>(
              value: preset.multiplier,
              child: Text(widget.appLanguage == AppLanguage.russian ? preset.ru : preset.en),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _activityMultiplier = value;
            });
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _calculateNutrition,
          icon: const Icon(Icons.calculate),
          label: Text(_tr('Рассчитать КБЖУ', 'Calculate macros')),
        ),
        const SizedBox(height: 14),
        if (_targets != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Ваши целевые значения', 'Your target values'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(_tr('Калории', 'Calories'), '${_targets!.calories.toStringAsFixed(0)} ${_tr('ккал', 'kcal')}'),
                  _buildInfoRow(_tr('Белки', 'Proteins'), '${_targets!.proteins.toStringAsFixed(0)} г'),
                  _buildInfoRow(_tr('Жиры', 'Fats'), '${_targets!.fats.toStringAsFixed(0)} г'),
                  _buildInfoRow(_tr('Углеводы', 'Carbs'), '${_targets!.carbs.toStringAsFixed(0)} г'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          _tr('Прогресс по дням', 'Daily progress'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ..._dailyProgress.map((day) {
          final progress = _targets == null ? 0.0 : (day.calories / _targets!.calories).clamp(0.0, 1.0);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDay(day.day),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${day.calories.toStringAsFixed(0)} ${_tr('ккал', 'kcal')}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('${_tr('Б', 'P')}: ${day.proteins.toStringAsFixed(0)}')),
                      Chip(label: Text('${_tr('Ж', 'F')}: ${day.fats.toStringAsFixed(0)}')),
                      Chip(label: Text('${_tr('У', 'C')}: ${day.carbs.toStringAsFixed(0)}')),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          _tr('Тема приложения', 'App theme'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text(_tr('Система', 'System')),
              icon: const Icon(Icons.settings_suggest),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text(_tr('Светлая', 'Light')),
              icon: const Icon(Icons.light_mode),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text(_tr('Темная', 'Dark')),
              icon: const Icon(Icons.dark_mode),
            ),
          ],
          selected: {widget.themeMode},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            widget.onThemeModeChanged(selection.first);
          },
        ),
        const SizedBox(height: 20),
        Text(
          _tr('Язык', 'Language'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SegmentedButton<AppLanguage>(
          segments: const [
            ButtonSegment<AppLanguage>(
              value: AppLanguage.russian,
              label: Text('RU'),
            ),
            ButtonSegment<AppLanguage>(
              value: AppLanguage.english,
              label: Text('EN'),
            ),
          ],
          selected: {widget.appLanguage},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) {
              return;
            }
            widget.onLanguageChanged(selection.first);
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_tr('Текущая конфигурация', 'Current configuration')),
            subtitle: Text(
              _tr(
                'Тема: ${_themeLabel(widget.themeMode)} • Язык: ${_languageLabel(widget.appLanguage)}',
                'Theme: ${_themeLabel(widget.themeMode)} • Language: ${_languageLabel(widget.appLanguage)}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitle()),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMealPlan,
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildRecipesTab(),
          _buildIngredientsTab(),
          _buildGoalsTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showScanOptions,
              icon: const Icon(Icons.document_scanner),
              label: Text(_tr('Сканировать', 'Scan')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: _tr('Рецепты', 'Recipes'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: _tr('Ингредиенты', 'Ingredients'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: _tr('Цели', 'Goals'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: _tr('Настройки', 'Settings'),
          ),
        ],
      ),
    );
  }
}

class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
}

class PantryItem {
  const PantryItem({
    required this.name,
    required this.remainingPercent,
    required this.expiresInDays,
    required this.priceRub,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final String name;
  final int remainingPercent;
  final int expiresInDays;
  final double priceRub;
  final int calories;
  final double proteins;
  final double fats;
  final double carbs;
}

class _ScanHistoryEntry {
  const _ScanHistoryEntry({
    required this.method,
    required this.addedCount,
    required this.scannedAt,
  });

  final String method;
  final int addedCount;
  final DateTime scannedAt;
}

class _DailyProgress {
  const _DailyProgress({
    required this.day,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final DateTime day;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;
}

class _ActivityPreset {
  const _ActivityPreset({
    required this.multiplier,
    required this.ru,
    required this.en,
  });

  final double multiplier;
  final String ru;
  final String en;
}