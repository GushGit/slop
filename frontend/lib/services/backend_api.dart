import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/pantry_item.dart';

class ScanRequest {
  const ScanRequest({
    required this.method,
    required this.locale,
    required this.imagePath,
  });

  final String method;
  final String locale;
  final String imagePath;
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
  Future<List<String>> fetchProducts();
  Future<ScanResponse> scanProducts(ScanRequest request);
  Future<List<Map<String, dynamic>>> fetchRecipes({
    required List<String> products,
    required List<String> utilities,
    required String goal,
  });
}

class HttpBackendApi implements BackendApi {
  HttpBackendApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  @override
  Future<List<String>> fetchProducts() async {
    final response = await _client.get(_uri('/products'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    final raw = switch (decoded) {
      List<dynamic> list => list,
      Map<String, dynamic> map => map['products'] as List<dynamic>? ?? const [],
      _ => const [],
    };
    return raw.map((e) => e.toString()).toList();
  }

  @override
  Future<ScanResponse> scanProducts(ScanRequest request) async {
    final multipart = http.MultipartRequest('POST', _uri('/process-image'))
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          request.imagePath,
          filename: File(request.imagePath).uri.pathSegments.last,
        ),
      );

    final streamed = await _client.send(multipart);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to process image: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final rawProducts = switch (decoded) {
      List<dynamic> list => list,
      Map<String, dynamic> map => map['products'] as List<dynamic>? ?? const [],
      _ => const [],
    };
    final items = rawProducts
        .map(
          (e) => PantryItem(
            name: e.toString(),
            remainingPercent: 100,
            expiresInDays: 7,
            priceRub: 0,
            calories: 0,
            proteins: 0,
            fats: 0,
            carbs: 0,
          ),
        )
        .toList();

    return ScanResponse(
      items: items,
      scannedAt: DateTime.now(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecipes({
    required List<String> products,
    required List<String> utilities,
    required String goal,
  }) async {
    final response = await _client.post(
      _uri('/recipes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'products': products,
        'utilities': utilities,
        'goal': goal,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = decoded['recipes'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }
}
