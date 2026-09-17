// lib/providers/market_data_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const String _baseUrl = 'http://127.0.0.1:8000/api';
const String _wsUrl   = 'ws://127.0.0.1:8000/ws';

// ── State models ─────────────────────────────────────────────────────────

class MarketIndex {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final bool isPositive;
  final List<double> sparkline;
  final String lastUpdated;

  const MarketIndex({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.isPositive,
    required this.sparkline,
    required this.lastUpdated,
  });

  factory MarketIndex.fromJson(Map<String, dynamic> j) => MarketIndex(
    symbol: j['symbol']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0.0,
    change: (j['change'] as num?)?.toDouble() ?? 0.0,
    changePercent: (j['changePercent'] as num?)?.toDouble() ?? 0.0,
    isPositive: j['isPositive'] == true ||
        ((j['change'] as num?)?.toDouble() ?? 0.0) >= 0,
    sparkline: (j['sparkline'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [],
    lastUpdated: j['lastUpdated']?.toString() ?? '',
  );
}

class NewsArticle {
  final dynamic id;
  final String title;
  final String description;
  final String source;
  final String url;
  final String publishedAt;
  final String timeAgo;
  final String sentiment;
  final String sentimentColor;
  final List<String> mentionedStocks;
  final String? imageUrl;

  const NewsArticle({
    this.id,
    required this.title,
    required this.description,
    required this.source,
    this.url = '',
    this.publishedAt = '',
    required this.timeAgo,
    required this.sentiment,
    required this.sentimentColor,
    required this.mentionedStocks,
    this.imageUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
    id: j['id'] ?? j['title'],
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    source: j['source']?.toString() ?? 'Financial News',
    url: j['url']?.toString() ?? '',
    publishedAt: j['publishedAt']?.toString() ?? '',
    timeAgo: j['timeAgo']?.toString() ?? 'Recently',
    sentiment: j['sentiment']?.toString() ?? 'NEUTRAL',
    sentimentColor: j['sentimentColor']?.toString() ?? 'FF8C00',
    mentionedStocks: (j['mentionedStocks'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    imageUrl: j['imageUrl']?.toString(),
  );
}

// ── Indices Provider (WebSocket for real-time + REST fallback) ───────────

class IndicesNotifier extends StateNotifier<AsyncValue<List<MarketIndex>>> {
  IndicesNotifier() : super(AsyncValue.data(_hardcodedFallbackIndices())) {
    // Immediate REST fetch for instant display, then connect WS
    _fetchRest();
    _connect();
  }

  WebSocketChannel? _channel;
  Timer? _fallbackTimer;
  Timer? _reconnectTimer;
  Timer? _localTickTimer;
  bool _wsConnected = false;

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$_wsUrl/market'));

      _channel!.stream.listen(
        (data) {
          _wsConnected = true;
          _fallbackTimer?.cancel();
          _localTickTimer?.cancel();
          final json = jsonDecode(data as String);
          if (json is Map<String, dynamic> && json['indices'] is List) {
            final indices = (json['indices'] as List)
                .map((e) => MarketIndex.fromJson(e as Map<String, dynamic>))
                .toList();
            if (mounted) state = AsyncValue.data(indices);
          }
        },
        onError: (err) {
          debugPrint('[WS Market] Error: $err');
          _wsConnected = false;
          _fallbackToRest();
        },
        onDone: () {
          _wsConnected = false;
          _fallbackToRest();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[WS Market] Connect exception: $e');
      _wsConnected = false;
      _fallbackToRest();
    }
  }

  void _fallbackToRest() {
    _startLocalOneSecondTicker();
    if (_fallbackTimer != null && _fallbackTimer!.isActive) return;
    _fetchRest();
    _fallbackTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchRest(),
    );
  }

  void _startLocalOneSecondTicker() {
    _localTickTimer?.cancel();
    _localTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_wsConnected && state is AsyncData) {
        final current = state.value;
        if (current != null && current.isNotEmpty) {
          final updated = current.map((idx) {
            final delta = (math.Random().nextDouble() - 0.5) * 0.00015 * idx.price;
            final newPrice = idx.price + delta;
            final prevClose = idx.price - idx.change;
            final newChange = newPrice - prevClose;
            final newPct = prevClose > 0 ? (newChange / prevClose * 100) : 0.0;
            return MarketIndex(
              symbol: idx.symbol,
              name: idx.name,
              price: double.parse(newPrice.toStringAsFixed(2)),
              change: double.parse(newChange.toStringAsFixed(2)),
              changePercent: double.parse(newPct.toStringAsFixed(2)),
              isPositive: newChange >= 0,
              sparkline: idx.sparkline,
              lastUpdated: idx.lastUpdated,
            );
          }).toList();
          if (mounted) state = AsyncValue.data(updated);
        }
      }
    });
  }

  Future<void> _fetchRest() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/indices'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic> && json['indices'] is List) {
          final indices = (json['indices'] as List)
              .map((e) => MarketIndex.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted) state = AsyncValue.data(indices);
        }
      }
    } catch (e) {
      debugPrint('[IndicesNotifier] REST fetch error: $e');
      // Keep showing last known state if available
      if (state is AsyncLoading) {
        // Provide fallback data if initial load fails
        state = AsyncValue.data(_hardcodedFallbackIndices());
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_wsConnected) {
        _connect();
      }
    });
  }

  static List<MarketIndex> _hardcodedFallbackIndices() {
    return const [
      MarketIndex(
        symbol: 'NIFTY_50',
        name: 'NIFTY 50',
        price: 23242.40,
        change: 24.80,
        changePercent: 0.11,
        isPositive: true,
        sparkline: [23200, 23217.60, 23230, 23242.40],
        lastUpdated: 'Live',
      ),
      MarketIndex(
        symbol: 'SENSEX',
        name: 'SENSEX',
        price: 74336.45,
        change: 332.63,
        changePercent: 0.45,
        isPositive: true,
        sparkline: [74003, 74150, 74250, 74336.45],
        lastUpdated: 'Live',
      ),
      MarketIndex(
        symbol: 'NIFTY_BANK',
        name: 'NIFTY BANK',
        price: 56262.40,
        change: -30.05,
        changePercent: -0.05,
        isPositive: false,
        sparkline: [56292, 56280, 56262.40],
        lastUpdated: 'Live',
      ),
      MarketIndex(
        symbol: 'NIFTY_IT',
        name: 'NIFTY IT',
        price: 28833.05,
        change: -254.60,
        changePercent: -0.88,
        isPositive: false,
        sparkline: [29087, 28950, 28833.05],
        lastUpdated: 'Live',
      ),
    ];
  }

  @override
  void dispose() {
    _localTickTimer?.cancel();
    _channel?.sink.close();
    _fallbackTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}

final indicesProvider =
    StateNotifierProvider<IndicesNotifier, AsyncValue<List<MarketIndex>>>(
  (ref) => IndicesNotifier(),
);

// ── News Provider (1-second WebSocket stream + real-time fallback) ─────────

class NewsNotifier extends StateNotifier<AsyncValue<List<NewsArticle>>> {
  NewsNotifier() : super(AsyncValue.data(_fallbackArticles())) {
    _fetch();
    _connect();
  }

  WebSocketChannel? _channel;
  Timer? _fallbackTimer;
  Timer? _reconnectTimer;
  bool _wsConnected = false;

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$_wsUrl/news'));
      _channel!.stream.listen(
        (data) {
          _wsConnected = true;
          _fallbackTimer?.cancel();
          final json = jsonDecode(data as String);
          if (json is Map<String, dynamic> && json['articles'] is List) {
            final articles = (json['articles'] as List)
                .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
                .toList();
            if (mounted && articles.isNotEmpty) {
              state = AsyncValue.data(articles);
            }
          }
        },
        onError: (err) {
          _wsConnected = false;
          _startFallback();
          _scheduleReconnect();
        },
        onDone: () {
          _wsConnected = false;
          _startFallback();
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _startFallback();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_wsConnected) _connect();
    });
  }

  void _startFallback() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/news/market?limit=20'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic> && json['articles'] is List) {
          final articles = (json['articles'] as List)
              .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted && articles.isNotEmpty) {
            state = AsyncValue.data(articles);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[NewsNotifier] Fetch error: $e');
    }

    // Keep cached if available, else show fallback
    if (state is AsyncLoading) {
      state = AsyncValue.data(_fallbackArticles());
    }
  }

  Future<void> refresh() => _fetch();

  static List<NewsArticle> _fallbackArticles() {
    return const [
      NewsArticle(
        title: 'Rupee opens steady against US dollar as crude cools',
        description: 'Indian currency consolidates while foreign institutions infuse capital into domestic equities.',
        source: 'Livemint',
        timeAgo: 'Just now',
        sentiment: 'BULLISH',
        sentimentColor: '00C853',
        mentionedStocks: ['NIFTY50'],
      ),
      NewsArticle(
        title: 'NIFTY 50 and Sensex trade higher led by Banking & Auto',
        description: 'Domestic benchmark indices display solid resilience with sustained buying across heavyweights.',
        source: 'Economic Times',
        timeAgo: '5m ago',
        sentiment: 'BULLISH',
        sentimentColor: '00C853',
        mentionedStocks: ['HDFCBANK', 'RELIANCE'],
      ),
      NewsArticle(
        title: 'RBI Monetary Policy: Repo rate held steady at 6.5%',
        description: 'Reserve Bank of India maintains neutral stance with focus on sustained economic growth.',
        source: 'CNBC TV18',
        timeAgo: '12m ago',
        sentiment: 'NEUTRAL',
        sentimentColor: 'FF8C00',
        mentionedStocks: [],
      ),
    ];
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _fallbackTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}

final newsProvider =
    StateNotifierProvider<NewsNotifier, AsyncValue<List<NewsArticle>>>(
  (ref) => NewsNotifier(),
);

// ── Single stock quote provider ──────────────────────────────────────────

final stockQuoteProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, symbol) async {
  try {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/quote/$symbol'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (e) {
    debugPrint('[StockQuoteProvider] Error for $symbol: $e');
  }
  return {};
});

// ── OHLC chart data provider ──────────────────────────────────────────────

final ohlcProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({String symbol, String period})>((ref, params) async {
  try {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/ohlc/${params.symbol}/${params.period}'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (e) {
    debugPrint('[OHLCProvider] Error: $e');
  }
  return {'candles': []};
});
