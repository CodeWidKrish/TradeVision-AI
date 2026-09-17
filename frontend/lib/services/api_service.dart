import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/error_handler.dart';
import '../models/models.dart';
import 'live_news_service.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const Duration _timeout = Duration(milliseconds: 2500);

  // Instance methods for legacy dashboard screen
  Future<StockModel> fetchStock(String symbol) async {
    final res = await get('/stock/$symbol');
    return res != null ? StockModel.fromJson(res) : StockModel(symbol: symbol);
  }

  Future<StockDetailModel> fetchStockDetails(String symbol) async {
    final res = await get('/stock-details/$symbol');
    return res != null ? StockDetailModel.fromJson(res) : StockDetailModel(symbol: symbol);
  }

  Future<RecommendationModel> fetchRecommendation(String symbol) async {
    final res = await get('/recommendation/$symbol');
    return res != null
        ? RecommendationModel.fromJson(res)
        : RecommendationModel(symbol: symbol, decision: 'N/A', confidence: 0, reason: '', keyFactors: []);
  }

  Future<OverviewModel> fetchOverview(String symbol) async {
    final res = await get('/overview/$symbol');
    return res != null
        ? OverviewModel.fromJson(res)
        : OverviewModel(
            stock: StockInfo(symbol: symbol),
            indicators: IndicatorInfo(symbol: symbol, signal: 'N/A'),
          );
  }

  Future<NewsModel> fetchNews(String symbol) async {
    final res = await get('/news/$symbol');
    return res != null ? NewsModel.fromJson(res) : NewsModel(symbol: symbol, articles: []);
  }

  Future<IndicatorModel> fetchIndicators(String symbol) async {
    final res = await get('/indicators/$symbol');
    return res != null ? IndicatorModel.fromJson(res) : IndicatorModel(symbol: symbol, signal: 'N/A');
  }

  Future<ChartModel> fetchChart(String symbol) async {
    final res = await get('/chart/$symbol');
    return res != null ? ChartModel.fromJson(res) : ChartModel(symbol: symbol, points: []);
  }

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

  static Future<List<Map<String, dynamic>>> fetchMarketNews({int limit = 15}) async {
    try {
      final res = await get('/news/market?limit=$limit', retries: 0);
      if (res != null && res['articles'] is List && (res['articles'] as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(res['articles']);
      }
    } catch (_) {}

    // Fallback to direct client-side live news (always works on mobile with Internet)
    return await LiveNewsService.fetchLiveNews(limit: limit);
  }

  static Future<List<Map<String, dynamic>>> fetchStockNews(String symbol, {int limit = 10}) async {
    if (symbol.isEmpty) return [];
    final res = await get('/news/$symbol?limit=$limit');
    if (res != null && res['articles'] is List) {
      return List<Map<String, dynamic>>.from(res['articles']);
    }
    return [];
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
