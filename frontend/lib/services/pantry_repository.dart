import '../models/pantry_item.dart';
import '../models/prepared_meal.dart';
import '../models/scan_history_entry.dart';
import 'backend_api.dart';

class PantryRepository {
  PantryRepository({required BackendApi backendApi}) : _backendApi = backendApi;

  final BackendApi _backendApi;

  final List<PantryItem> _items = [
    const PantryItem(
      name: 'Куриная грудка',
      remainingPercent: 70,
      expiresInDays: 2,
      priceRub: 289,
      calories: 165,
      proteins: 31,
      fats: 3.6,
      carbs: 0,
    ),
    const PantryItem(
      name: 'Овсяные хлопья',
      remainingPercent: 85,
      expiresInDays: 20,
      priceRub: 89,
      calories: 352,
      proteins: 12,
      fats: 6,
      carbs: 62,
    ),
    const PantryItem(
      name: 'Ягоды',
      remainingPercent: 70,
      expiresInDays: 3,
      priceRub: 179,
      calories: 57,
      proteins: 1,
      fats: 0.3,
      carbs: 12,
    ),
  ];

  final List<ScanHistoryEntry> _history = [
    ScanHistoryEntry(
      method: 'Инициализация',
      addedCount: 2,
      scannedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<PreparedMeal> _preparedMeals = [];

  List<PantryItem> get items => List.unmodifiable(_items);
  List<ScanHistoryEntry> get history => List.unmodifiable(_history);
  List<PreparedMeal> get preparedMeals => List.unmodifiable(_preparedMeals);

  Future<void> scanAndAddProducts({
    required String method,
    required String locale,
    required String methodLabel,
  }) async {
    final response = await _backendApi.scanProducts(
      ScanRequest(method: method, locale: locale),
    );

    _items.insertAll(0, response.items);
    _history.insert(
      0,
      ScanHistoryEntry(
        method: methodLabel,
        addedCount: response.items.length,
        scannedAt: response.scannedAt,
      ),
    );
  }

  void applyIngredientConsumption(Map<String, int> consumptionPercentByIngredient) {
    final updatedItems = _items.map((item) {
      final percent = consumptionPercentByIngredient[item.name];
      if (percent == null) {
        return item;
      }
      return item.consumePercent(percent);
    }).toList();

    _items
      ..clear()
      ..addAll(updatedItems);
  }

  void addPreparedMeal(PreparedMeal meal) {
    _preparedMeals.insert(0, meal);
  }

  void consumePreparedMeal({
    required String mealId,
    required int consumedPercent,
  }) {
    final index = _preparedMeals.indexWhere((item) => item.id == mealId);
    if (index < 0) {
      return;
    }

    final updated = _preparedMeals[index].consumePercent(consumedPercent);
    if (updated.remainingPercent <= 0) {
      _preparedMeals.removeAt(index);
    } else {
      _preparedMeals[index] = updated;
    }
  }

}
