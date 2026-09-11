import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Provider for Market Overview & Trend Indices
final marketTrendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ApiService.fetchMarketTrend();
});

/// Provider for Stock Search Queries
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

final stockSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(stockSearchQueryProvider);
  return await ApiService.searchStocks(query);
});

/// Provider for Selected Stock Detail
final selectedStockSymbolProvider = StateProvider<String>((ref) => 'RELIANCE.NS');

final stockDetailProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final symbol = ref.watch(selectedStockSymbolProvider);
  return await ApiService.fetchStockDetail(symbol);
});
