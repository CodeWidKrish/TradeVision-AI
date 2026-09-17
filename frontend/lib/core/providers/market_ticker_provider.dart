import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/stock_data.dart';

class MarketTickerNotifier extends ChangeNotifier {
  late List<StockModel> _stocks;
  final Map<String, int> _tickDirections = {}; // 1 for up, -1 for down, 0 for none
  Timer? _timer;
  final Random _random = Random();

  List<Map<String, dynamic>> _indices = [
    {'name': 'NIFTY 50',    'value': 23242.40, 'change': 24.80, 'changePercent': 0.11, 'up': true},
    {'name': 'SENSEX',      'value': 74336.45, 'change': 332.63, 'changePercent': 0.45, 'up': true},
    {'name': 'NIFTY BANK',  'value': 56262.40, 'change': -30.05, 'changePercent': -0.05, 'up': false},
    {'name': 'NIFTY IT',    'value': 28833.05, 'change': -254.60, 'changePercent': -0.88, 'up': false},
    {'name': 'NIFTY NEXT 50','value': 72145.10, 'change': 310.20, 'changePercent': 0.43, 'up': true},
  ];

  MarketTickerNotifier() {
    _stocks = List<StockModel>.from(StockRepository.stocks);
    _startLiveTicks();
  }

  List<StockModel> get stocks => _stocks;
  List<Map<String, dynamic>> get indices => _indices;

  int getTickDirection(String ticker) {
    return _tickDirections[ticker] ?? 0;
  }

  void _startLiveTicks() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _tickRandomStock();
    });
  }

  void _tickRandomStock() {
    if (_stocks.isEmpty) return;

    final index = _random.nextInt(_stocks.length);
    final stock = _stocks[index];

    final isUp = _random.nextBool();
    final deltaPercent = (_random.nextDouble() * 0.25 + 0.05) * (isUp ? 1 : -1);
    final oldPrice = stock.price;
    final newPrice = oldPrice * (1 + deltaPercent / 100);
    final newChangePercent = stock.changePercent + deltaPercent;

    final updatedChart1D = List<FlSpot>.from(stock.chart1D);
    if (updatedChart1D.isNotEmpty) {
      final lastSpot = updatedChart1D.last;
      updatedChart1D.add(FlSpot(lastSpot.x + 0.5, newPrice));
      if (updatedChart1D.length > 25) {
        updatedChart1D.removeAt(0);
      }
    }

    _stocks[index] = stock.copyWith(
      price: newPrice,
      changePercent: newChangePercent,
      chart1D: updatedChart1D,
    );

    _tickDirections[stock.ticker] = isUp ? 1 : -1;
    _updateIndices();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 700), () {
      _tickDirections[stock.ticker] = 0;
      notifyListeners();
    });
  }

  void _updateIndices() {
    final idxIndex = _random.nextInt(_indices.length);
    final idx = _indices[idxIndex];
    final isUp = _random.nextBool();
    final delta = (_random.nextDouble() * 14.0 + 2.0) * (isUp ? 1 : -1);

    final double oldVal = (idx['value'] as num).toDouble();
    final double newVal = oldVal + delta;
    final double oldChange = (idx['change'] as num).toDouble();
    final double newChange = oldChange + delta;
    final double newPercent = (newChange / (newVal - newChange)) * 100;

    _indices[idxIndex] = {
      'name': idx['name'],
      'value': newVal,
      'change': newChange,
      'changePercent': newPercent,
      'up': newChange >= 0,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
