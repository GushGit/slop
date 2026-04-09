import '../models/pantry_item.dart';

class ScanRequest {
  const ScanRequest({
    required this.method,
    required this.locale,
  });

  final String method;
  final String locale;
}

class ScanResponse {
  const ScanResponse({
    required this.items,
    required this.scannedAt,
  });

  final List<PantryItem> items;
  final DateTime scannedAt;
}

abstract class BackendApi {
  Future<ScanResponse> scanProducts(ScanRequest request);
}

class MockBackendApi implements BackendApi {
  @override
  Future<ScanResponse> scanProducts(ScanRequest request) async {
    await Future.delayed(const Duration(seconds: 2));

    final dataByMethod = <String, List<PantryItem>>{
      'photo': [
        PantryItem(
          name: 'Яблоки',
          remainingPercent: 100,
          expiresInDays: 8,
          priceRub: 139,
          calories: 47,
          proteins: 0.4,
          fats: 0.4,
          carbs: 9.8,
        ),
        PantryItem(
          name: 'Бананы',
          remainingPercent: 100,
          expiresInDays: 5,
          priceRub: 129,
          calories: 89,
          proteins: 1.1,
          fats: 0.3,
          carbs: 22.8,
        ),
      ],
      'receipt': [
        PantryItem(
          name: 'Молоко 1л',
          remainingPercent: 100,
          expiresInDays: 6,
          priceRub: 109,
          calories: 60,
          proteins: 3.2,
          fats: 3.4,
          carbs: 4.7,
        ),
        PantryItem(
          name: 'Хлеб цельнозерновой',
          remainingPercent: 100,
          expiresInDays: 4,
          priceRub: 76,
          calories: 242,
          proteins: 8,
          fats: 2,
          carbs: 46,
        ),
      ],
      'barcode': [
        PantryItem(
          name: 'Йогурт питьевой',
          remainingPercent: 100,
          expiresInDays: 7,
          priceRub: 95,
          calories: 88,
          proteins: 3.5,
          fats: 2.5,
          carbs: 13,
        ),
      ],
    };

    return ScanResponse(
      items: dataByMethod[request.method] ?? const [],
      scannedAt: DateTime.now(),
    );
  }
}
