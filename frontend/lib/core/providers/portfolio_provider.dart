import 'package:flutter/material.dart';
import '../data/stock_data.dart';

class PortfolioProvider extends ChangeNotifier {
  final List<StockModel> _watchlist = List.from(StockRepository.stocks);
  final Map<String, int> _holdings = {
    'RELIANCE': 100,
    'TCS': 25,
    'HDFCBANK': 60,
  };
  double _totalInvested = 410000.0;
  double _virtualCash = 500000.0; // ₹5,00,000 Paper Trading virtual funds

  List<StockModel> get watchlist => _watchlist;
  Map<String, int> get holdings => _holdings;
  double get totalInvested => _totalInvested;
  double get virtualCash => _virtualCash;

  double get totalCurrentValue {
    double sum = 0.0;
    _holdings.forEach((ticker, qty) {
      final stock = StockRepository.getStock(ticker);
      sum += stock.price * qty;
    });
    return sum;
  }

  double getPnL() {
    return totalCurrentValue - _totalInvested;
  }

  double getPnLPercent() {
    if (_totalInvested <= 0) return 0.0;
    return (getPnL() / _totalInvested) * 100;
  }

  int getHoldingQuantity(String ticker) {
    return _holdings[ticker.toUpperCase()] ?? 0;
  }

  void buyStock(StockModel stock, int qty) {
    if (qty <= 0) return;
    final ticker = stock.ticker.toUpperCase();
    final cost = stock.price * qty;

    _holdings[ticker] = (_holdings[ticker] ?? 0) + qty;
    _totalInvested += cost;
    _virtualCash = (_virtualCash - cost).clamp(0, double.infinity);

    notifyListeners();
  }

  void sellStock(StockModel stock, int qty) {
    final ticker = stock.ticker.toUpperCase();
    final currentQty = _holdings[ticker] ?? 0;
    if (qty <= 0 || currentQty < qty) return;

    final ratio = qty / currentQty;
    final investedPortion = (_totalInvested * ratio);
    final revenue = stock.price * qty;

    _holdings[ticker] = currentQty - qty;
    if (_holdings[ticker] == 0) {
      _holdings.remove(ticker);
    }
    _totalInvested = (_totalInvested - investedPortion).clamp(0, double.infinity);
    _virtualCash += revenue;

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
