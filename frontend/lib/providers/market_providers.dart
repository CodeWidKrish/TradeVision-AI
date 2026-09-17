import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../services/live_news_service.dart';

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

/// Provider for Live Real-Time Indian Market News streaming every 1 second
final marketNewsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  // 1. Instantly yield live articles in 0ms so mobile never gets stuck in loading skeleton
  yield LiveNewsService.getInitialArticles();

  // 2. Fetch fresh live news in background from direct official RSS or backend
  try {
    final fresh = await LiveNewsService.fetchLiveNews(limit: 20);
    if (fresh.isNotEmpty) {
      yield fresh;
    }
  } catch (_) {}

  // 3. Stream continuous 1-second live updates
  final controller = StreamController<List<Map<String, dynamic>>>();
  WebSocketChannel? channel;
  Timer? pollTimer;

  void startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final fresh = await LiveNewsService.fetchLiveNews(limit: 20);
        if (fresh.isNotEmpty && !controller.isClosed) {
          controller.add(fresh);
        }
      } catch (_) {}
    });
  }

  void connectWs() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:8000/ws/news'));
      channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            if (json is Map<String, dynamic> && json['articles'] is List) {
              final list = List<Map<String, dynamic>>.from(json['articles']);
              if (!controller.isClosed && list.isNotEmpty) {
                controller.add(list);
              }
            }
          } catch (_) {}
        },
        onError: (_) => startPolling(),
        onDone: () => startPolling(),
        cancelOnError: true,
      );
    } catch (_) {
      startPolling();
    }
  }

  connectWs();

  ref.onDispose(() {
    channel?.sink.close();
    pollTimer?.cancel();
    controller.close();
  });

  yield* controller.stream;
});

/// Provider for Stock-Specific News
final stockNewsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, symbol) async {
  return await ApiService.fetchStockNews(symbol, limit: 10);
});
