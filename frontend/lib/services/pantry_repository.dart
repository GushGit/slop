
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pantry_item.dart';
import '../models/prepared_meal.dart';
import '../models/scan_history_entry.dart';
import 'backend_api.dart';

class PantryRepository {
  PantryRepository({required BackendApi backendApi}) : _backendApi = backendApi;

  final BackendApi _backendApi;

  final List<PantryItem> _items = [];
  final Set<String> _supportedProducts = {};

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

  Future<void> loadSupportedProducts() async {
    final products = await _backendApi.fetchProducts();
    _supportedProducts
      ..clear()
      ..addAll(products.map((p) => p.trim().toLowerCase()));
  }

  Future<void> loadSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('pantryItems');
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List;
      _items.clear();
      for (final item in list) {
        _items.add(PantryItem.fromJson(item as Map<String, dynamic>));
      }
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.map((e) => e.toJson()).toList();
    await prefs.setString('pantryItems', jsonEncode(list));
  }

  Future<void> scanAndAddProducts({
    required String method,
    required String locale,
    required String methodLabel,
    required String imagePath,
  }) async {
    final response = await _backendApi.scanProducts(
      ScanRequest(method: method, locale: locale, imagePath: imagePath),
    );

    final existingNames = _items.map((e) => e.name.trim().toLowerCase()).toSet();
    final filteredUnique = response.items.where((item) {
      final normalized = item.name.trim().toLowerCase();
      final supported = _supportedProducts.isEmpty || _supportedProducts.contains(normalized);
      if (!supported || existingNames.contains(normalized)) {
        return false;
      }
      existingNames.add(normalized);
      return true;
    }).toList();

    _items.insertAll(0, filteredUnique);
    _history.insert(
      0,
      ScanHistoryEntry(
        method: methodLabel,
        addedCount: filteredUnique.length,
        scannedAt: response.scannedAt,
      ),
    );
    await _saveItems();
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
      
    _saveItems();
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
