import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import '../core/data/stock_data.dart';
import '../core/providers/market_ticker_provider.dart';
import 'notification_service.dart';

class AlertService {
  static final AlertService instance = AlertService._internal();
  AlertService._internal();

  final List<PriceAlert> _alerts = [];
  final StreamController<PriceAlert> _alertTriggeredController =
      StreamController<PriceAlert>.broadcast();

  Stream<PriceAlert> get onAlertTriggered => _alertTriggeredController.stream;
  List<PriceAlert> get alerts => List.unmodifiable(_alerts);

  static const String _storageKey = 'tradevision_price_alerts';
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _alerts.clear();
        for (final item in list) {
          _alerts.add(PriceAlert.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (e) {
      debugPrint('[AlertService] Error loading alerts: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[AlertService] Error saving alerts: $e');
    }
  }

  Future<void> addAlert(PriceAlert alert) async {
    _alerts.removeWhere((a) => a.id == alert.id);
    _alerts.insert(0, alert);
    await _save();

    final stock = StockRepository.getStock(alert.ticker);
    MarketTickerNotifier.instance?.registerStockForTracking(stock);
  }

  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _save();
  }

  Future<void> toggleAlert(String id, bool active) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx].isActive = active;
      await _save();
    }
  }

  /// Evaluates alerts whenever a stock price changes (from live tick engine or REST hydration)
  void evaluateStock(StockModel stock) {
    final ticker = stock.ticker.toUpperCase();
    final price = stock.price;
    final pct = stock.changePercent;

    for (final alert in _alerts) {
      if (!alert.isActive || alert.isTriggered) continue;
      if (alert.ticker.toUpperCase() != ticker) continue;

      bool triggered = false;
      String message = '';

      switch (alert.type) {
        case AlertType.priceAbove:
          if (alert.targetPrice != null && price >= alert.targetPrice!) {
            triggered = true;
            message = '${alert.ticker} hit ₹${price.toStringAsFixed(2)} (Target: ₹${alert.targetPrice!.toStringAsFixed(2)})';
          }
          break;
        case AlertType.priceBelow:
          if (alert.targetPrice != null && price <= alert.targetPrice!) {
            triggered = true;
            message = '${alert.ticker} dropped to ₹${price.toStringAsFixed(2)} (Floor: ₹${alert.targetPrice!.toStringAsFixed(2)})';
          }
          break;
        case AlertType.percentGain:
          if (alert.targetPercent != null && pct >= alert.targetPercent!) {
            triggered = true;
            message = '${alert.ticker} surged +${pct.toStringAsFixed(2)}% (Target: +${alert.targetPercent!.toStringAsFixed(1)}%)';
          }
          break;
        case AlertType.percentLoss:
          if (alert.targetPercent != null && pct <= -alert.targetPercent!.abs()) {
            triggered = true;
            message = '${alert.ticker} declined ${pct.toStringAsFixed(2)}% (Target: -${alert.targetPercent!.toStringAsFixed(1)}%)';
          }
          break;
        default:
          break;
      }

      if (triggered) {
        alert.isTriggered = true;
        alert.triggeredPrice = price;
        alert.triggeredAt = DateTime.now();
        alert.triggerMessage = message;
        _save();
        _alertTriggeredController.add(alert);
        HapticFeedback.heavyImpact();
        NotificationService.instance.showNotification(
          id: alert.id.hashCode,
          title: '🚨 TradeVision Alert: ${alert.ticker}',
          body: message,
          payload: alert.ticker,
        );
      }
    }
  }

  /// Evaluates AI recommendation or indicator triggers
  void evaluateSignal({
    required String ticker,
    required String signal,
    double? rsi,
  }) {
    final sym = ticker.toUpperCase();

    for (final alert in _alerts) {
      if (!alert.isActive || alert.isTriggered) continue;
      if (alert.ticker.toUpperCase() != sym) continue;

      bool triggered = false;
      String message = '';

      if (alert.type == AlertType.aiSignalShift) {
        if (alert.targetSignal != null &&
            signal.toUpperCase().contains(alert.targetSignal!.toUpperCase())) {
          triggered = true;
          message = 'AI Signal for $sym shifted to ${alert.targetSignal}!';
        }
      } else if (alert.type == AlertType.rsiOversold && rsi != null && rsi < 30) {
        triggered = true;
        message = '$sym RSI entered Oversold zone (${rsi.toStringAsFixed(1)}) - Potential Reversal!';
      } else if (alert.type == AlertType.rsiOverbought && rsi != null && rsi > 70) {
        triggered = true;
        message = '$sym RSI entered Overbought territory (${rsi.toStringAsFixed(1)})!';
      }

      if (triggered) {
        alert.isTriggered = true;
        alert.triggeredAt = DateTime.now();
        alert.triggerMessage = message;
        _save();
        _alertTriggeredController.add(alert);
        HapticFeedback.heavyImpact();
        NotificationService.instance.showNotification(
          id: alert.id.hashCode,
          title: 'TradeVision AI Signal Alert',
          body: message,
          payload: alert.ticker,
        );
      }
    }
  }
}
