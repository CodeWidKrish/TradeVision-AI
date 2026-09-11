import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/error_handler.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<Map<String, dynamic>> fetchMarketTrend() async {
    final res = await get('/market/trend');
    return res ?? {};
  }

  static Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    if (query.isEmpty) return [];
    final res = await get('/search?q=$query');
    if (res != null && res['results'] is List) {
      return List<Map<String, dynamic>>.from(res['results']);
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchStockDetail(String symbol) async {
    final res = await get('/stock-details/$symbol');
    return res ?? {};
  }

  // Safe GET with timeout + retry
  static Future<Map<String, dynamic>?> get(
    String endpoint, {
    int retries = 2,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl$endpoint'),
              headers: _headers(),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else if (response.statusCode == 429) {
          // Rate limited — wait and retry
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        } else if (response.statusCode >= 500) {
          throw NetworkException('Server error: ${response.statusCode}');
        }
      } on TimeoutException {
        if (attempt == retries) {
          throw TimeoutException('Request timed out after $_timeout');
        }
        await Future.delayed(const Duration(seconds: 1));
      } on http.ClientException catch (e) {
        throw NetworkException('Network unavailable: ${e.message}');
      } catch (e) {
        if (attempt == retries) rethrow;
      }
    }
    return null;
  }

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': '2.4.0',
        'X-Platform': 'flutter-web',
      };
}
