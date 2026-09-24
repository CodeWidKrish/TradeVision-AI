import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/stock_data.dart';
import '../../services/notification_service.dart';
import '../../services/secure_storage_service.dart';

class PaperTrade {
  final String id;
  final String ticker;
  final String stockName;
  final bool isBuy;
  final int quantity;
  final double price;
  final DateTime timestamp;
  final double realizedPnL;

  PaperTrade({
    required this.id,
    required this.ticker,
    required this.stockName,
    required this.isBuy,
    required this.quantity,
    required this.price,
    DateTime? timestamp,
    this.realizedPnL = 0.0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticker': ticker,
    'stockName': stockName,
    'isBuy': isBuy,
    'quantity': quantity,
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'realizedPnL': realizedPnL,
  };

  factory PaperTrade.fromJson(Map<String, dynamic> map) => PaperTrade(
    id: map['id'] ?? '',
    ticker: map['ticker'] ?? '',
    stockName: map['stockName'] ?? '',
    isBuy: map['isBuy'] ?? true,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
    realizedPnL: (map['realizedPnL'] as num?)?.toDouble() ?? 0.0,
  );
}

class LimitOrder {
  final String id;
  final String ticker;
  final String stockName;
  final bool isBuy;
  final int quantity;
  final double limitPrice;
  final DateTime createdAt;
  bool isExecuted;

  LimitOrder({
    required this.id,
    required this.ticker,
    required this.stockName,
    required this.isBuy,
    required this.quantity,
    required this.limitPrice,
    DateTime? createdAt,
    this.isExecuted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticker': ticker,
    'stockName': stockName,
    'isBuy': isBuy,
    'quantity': quantity,
    'limitPrice': limitPrice,
    'createdAt': createdAt.toIso8601String(),
    'isExecuted': isExecuted,
  };

  factory LimitOrder.fromJson(Map<String, dynamic> map) => LimitOrder(
    id: map['id'] ?? '',
    ticker: map['ticker'] ?? '',
    stockName: map['stockName'] ?? '',
    isBuy: map['isBuy'] ?? true,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    limitPrice: (map['limitPrice'] as num?)?.toDouble() ?? 0.0,
    createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    isExecuted: map['isExecuted'] ?? false,
  );
}

class PaperPosition {
  final String ticker;
  final String stockName;
  int quantity;
  double avgPrice;
  double totalInvested;

  PaperPosition({
    required this.ticker,
    required this.stockName,
    required this.quantity,
    required this.avgPrice,
    required this.totalInvested,
  });

  Map<String, dynamic> toJson() => {
    'ticker': ticker,
    'stockName': stockName,
    'quantity': quantity,
    'avgPrice': avgPrice,
    'totalInvested': totalInvested,
  };

  factory PaperPosition.fromJson(Map<String, dynamic> map) => PaperPosition(
    ticker: map['ticker'] ?? '',
    stockName: map['stockName'] ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    avgPrice: (map['avgPrice'] as num?)?.toDouble() ?? 0.0,
    totalInvested: (map['totalInvested'] as num?)?.toDouble() ?? 0.0,
  );
}

class PortfolioProvider extends ChangeNotifier {
  static const double initialCapital = 100000.0; // ₹1,00,000 starting paper capital
  static const String _storageKeyCash = 'tradevision_paper_cash_v2';
  static const String _storageKeyPositions = 'tradevision_paper_positions_v2';
  static const String _storageKeyTrades = 'tradevision_paper_trades_v2';
  static const String _storageKeyRealized = 'tradevision_paper_realized_v2';
  static const String _storageKeyLimitOrders = 'tradevision_paper_limits_v2';
  static const String _storageKeyEquity = 'tradevision_paper_equity_v2';

  double _virtualCash = initialCapital;
  final Map<String, PaperPosition> _positions = {};
  final List<PaperTrade> _tradeHistory = [];
  final List<LimitOrder> _limitOrders = [];
  final List<double> _equityHistory = [initialCapital];
  double _realizedPnL = 0.0;
  final List<StockModel> _watchlist = List.from(StockRepository.stocks);
  static PortfolioProvider? instance;

  PortfolioProvider() {
    instance = this;
    _loadFromPrefs();
  }

  double get virtualCash => _virtualCash;
  double get realizedPnL => _realizedPnL;
  List<PaperTrade> get tradeHistory => List.unmodifiable(_tradeHistory);
  List<LimitOrder> get limitOrders => List.unmodifiable(_limitOrders);
  List<LimitOrder> get activeLimitOrders =>
      _limitOrders.where((o) => !o.isExecuted).toList();
  Map<String, PaperPosition> get positions => _positions;
  List<StockModel> get watchlist => _watchlist;
  List<double> get equityHistory => List.unmodifiable(_equityHistory);

  // Legacy compatibility getters for existing screens
  Map<String, int> get holdings => _positions.map((k, v) => MapEntry(k, v.quantity));
  
  double get totalInvested {
    double sum = 0.0;
    _positions.forEach((_, pos) => sum += pos.totalInvested);
    return sum;
  }

  double get totalCurrentValue {
    double sum = 0.0;
    _positions.forEach((ticker, pos) {
      final stock = StockRepository.getStock(ticker);
      sum += stock.price * pos.quantity;
    });
    return sum;
  }

  double get totalPortfolioValue => _virtualCash + totalCurrentValue;

  double getPnL() {
    return totalCurrentValue - totalInvested;
  }

  double getPnLPercent() {
    if (totalInvested <= 0) return 0.0;
    return (getPnL() / totalInvested) * 100;
  }

  int getHoldingQuantity(String ticker) {
    return _positions[ticker.toUpperCase()]?.quantity ?? 0;
  }

  double getHoldingAvgPrice(String ticker) {
    return _positions[ticker.toUpperCase()]?.avgPrice ?? 0.0;
  }

  int get winningTradesCount =>
      _tradeHistory.where((t) => !t.isBuy && t.realizedPnL > 0).length;

  int get losingTradesCount =>
      _tradeHistory.where((t) => !t.isBuy && t.realizedPnL < 0).length;

  double get winRate {
    final closedTrades = winningTradesCount + losingTradesCount;
    if (closedTrades == 0) return 0.0;
    return (winningTradesCount / closedTrades) * 100;
  }

  List<FlSpot> getEquitySpots() {
    if (_equityHistory.isEmpty) return [const FlSpot(0, initialCapital)];
    return List.generate(_equityHistory.length, (i) {
      return FlSpot(i.toDouble(), _equityHistory[i]);
    });
  }

  void _recordEquityPoint() {
    final curVal = totalPortfolioValue;
    _equityHistory.add(curVal);
    if (_equityHistory.length > 40) {
      _equityHistory.removeAt(0);
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final secureCash = await SecureStorageService.getVirtualCash();
      if (secureCash != null) {
        _virtualCash = secureCash;
      }
      final secureRealized = await SecureStorageService.getRealizedPnL();
      if (secureRealized != null) {
        _realizedPnL = secureRealized;
      }
      final posRaw = await SecureStorageService.getPositions();
      if (posRaw != null && posRaw.isNotEmpty) {
        final decoded = jsonDecode(posRaw) as Map<String, dynamic>;
        _positions.clear();
        decoded.forEach((k, v) {
          _positions[k] = PaperPosition.fromJson(Map<String, dynamic>.from(v));
        });
      }
      final tradesRaw = await SecureStorageService.getTrades();
      if (tradesRaw != null && tradesRaw.isNotEmpty) {
        final list = jsonDecode(tradesRaw) as List;
        _tradeHistory.clear();
        for (final item in list) {
          _tradeHistory.add(PaperTrade.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      final limitsRaw = await SecureStorageService.getLimitOrders();
      if (limitsRaw != null && limitsRaw.isNotEmpty) {
        final list = jsonDecode(limitsRaw) as List;
        _limitOrders.clear();
        for (final item in list) {
          _limitOrders.add(LimitOrder.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      final equity = await SecureStorageService.getEquityHistory();
      if (equity != null && equity.isNotEmpty) {
        _equityHistory.clear();
        _equityHistory.addAll(equity);
      }
      if (_equityHistory.isEmpty) {
        _equityHistory.add(initialCapital);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[PortfolioProvider] Load error: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      await SecureStorageService.saveVirtualCash(_virtualCash);
      await SecureStorageService.saveRealizedPnL(_realizedPnL);
      await SecureStorageService.savePositions(
        jsonEncode(_positions.map((k, v) => MapEntry(k, v.toJson()))),
      );
      await SecureStorageService.saveTrades(
        jsonEncode(_tradeHistory.map((t) => t.toJson()).toList()),
      );
      await SecureStorageService.saveLimitOrders(
        jsonEncode(_limitOrders.map((o) => o.toJson()).toList()),
      );
      await SecureStorageService.saveEquityHistory(_equityHistory);
    } catch (e) {
      debugPrint('[PortfolioProvider] Save error: $e');
    }
  }

  bool buyStock(StockModel stock, int qty) {
    if (qty <= 0) return false;
    final ticker = stock.ticker.toUpperCase();
    final cost = stock.price * qty;

    if (cost > _virtualCash) {
      return false; // Insufficient virtual balance
    }

    _virtualCash -= cost;

    if (_positions.containsKey(ticker)) {
      final existing = _positions[ticker]!;
      final newQty = existing.quantity + qty;
      final newInvested = existing.totalInvested + cost;
      existing.quantity = newQty;
      existing.totalInvested = newInvested;
      existing.avgPrice = newInvested / newQty;
    } else {
      _positions[ticker] = PaperPosition(
        ticker: ticker,
        stockName: stock.fullName,
        quantity: qty,
        avgPrice: stock.price,
        totalInvested: cost,
      );
    }

    _tradeHistory.insert(
      0,
      PaperTrade(
        id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
        ticker: ticker,
        stockName: stock.fullName,
        isBuy: true,
        quantity: qty,
        price: stock.price,
      ),
    );

    _recordEquityPoint();
    _saveToPrefs();
    notifyListeners();
    return true;
  }

  bool sellStock(StockModel stock, int qty) {
    final ticker = stock.ticker.toUpperCase();
    if (!_positions.containsKey(ticker) || qty <= 0) return false;

    final pos = _positions[ticker]!;
    if (qty > pos.quantity) return false;

    final revenue = stock.price * qty;
    final costBasis = pos.avgPrice * qty;
    final tradePnL = revenue - costBasis;

    _virtualCash += revenue;
    _realizedPnL += tradePnL;

    pos.quantity -= qty;
    pos.totalInvested -= costBasis;

    if (pos.quantity <= 0) {
      _positions.remove(ticker);
    }

    _tradeHistory.insert(
      0,
      PaperTrade(
        id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
        ticker: ticker,
        stockName: stock.fullName,
        isBuy: false,
        quantity: qty,
        price: stock.price,
        realizedPnL: tradePnL,
      ),
    );

    _recordEquityPoint();
    _saveToPrefs();
    notifyListeners();
    return true;
  }

  bool closePosition(String ticker) {
    final t = ticker.toUpperCase();
    if (!_positions.containsKey(t)) return false;
    final pos = _positions[t]!;
    final stock = StockRepository.getStock(t);
    return sellStock(stock, pos.quantity);
  }

  void placeLimitOrder({
    required StockModel stock,
    required bool isBuy,
    required int quantity,
    required double limitPrice,
  }) {
    final order = LimitOrder(
      id: 'limit_${DateTime.now().millisecondsSinceEpoch}',
      ticker: stock.ticker.toUpperCase(),
      stockName: stock.fullName,
      isBuy: isBuy,
      quantity: quantity,
      limitPrice: limitPrice,
    );
    _limitOrders.insert(0, order);
    _saveToPrefs();
    notifyListeners();
  }

  void cancelLimitOrder(String id) {
    _limitOrders.removeWhere((o) => o.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  /// Evaluates pending limit orders against current tick price
  void evaluateLimitOrders(StockModel stock) {
    final ticker = stock.ticker.toUpperCase();
    final price = stock.price;

    for (final order in _limitOrders) {
      if (order.isExecuted) continue;
      if (order.ticker.toUpperCase() != ticker) continue;

      bool shouldExecute = false;
      if (order.isBuy && price <= order.limitPrice) {
        shouldExecute = true;
      } else if (!order.isBuy && price >= order.limitPrice) {
        shouldExecute = true;
      }

      if (shouldExecute) {
        order.isExecuted = true;
        if (order.isBuy) {
          buyStock(stock, order.quantity);
        } else {
          sellStock(stock, order.quantity);
        }
        NotificationService.instance.showNotification(
          id: order.id.hashCode,
          title: 'Limit Order Executed!',
          body: '${order.isBuy ? "Bought" : "Sold"} ${order.quantity} shares of ${order.ticker} at ₹${price.toStringAsFixed(2)}',
          payload: order.ticker,
        );
      }
    }
  }

  void resetPortfolio() {
    _virtualCash = initialCapital;
    _positions.clear();
    _tradeHistory.clear();
    _limitOrders.clear();
    _realizedPnL = 0.0;
    _equityHistory.clear();
    _equityHistory.add(initialCapital);
    _saveToPrefs();
    notifyListeners();
  }

  bool isWatchlisted(String ticker) {
    return _watchlist.any((s) => s.ticker.toUpperCase() == ticker.toUpperCase());
  }

  void toggleWatchlist(StockModel stock) {
    if (isWatchlisted(stock.ticker)) {
      _watchlist.removeWhere((s) => s.ticker.toUpperCase() == stock.ticker.toUpperCase());
    } else {
      _watchlist.add(stock);
    }
    notifyListeners();
  }
}
