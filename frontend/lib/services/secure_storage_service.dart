import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SecureStorageService provides persistent local storage for Paper Trading
/// and user preferences across app sessions, cold starts, and reboots.
class SecureStorageService {
  static SharedPreferences? _prefs;

  // Storage Keys
  static const String keyVirtualCash = 'tv_secure_virtual_cash';
  static const String keyPositions = 'tv_secure_paper_positions';
  static const String keyTrades = 'tv_secure_paper_trades';
  static const String keyLimitOrders = 'tv_secure_paper_limit_orders';
  static const String keyRealizedPnL = 'tv_secure_paper_realized_pnl';
  static const String keyEquityHistory = 'tv_secure_paper_equity_history';

  static Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[SecureStorageService] init error: $e');
    }
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('SecureStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ── Paper Trading Persistence ─────────────────────────────────────────

  static Future<void> saveVirtualCash(double amount) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setDouble(keyVirtualCash, amount);
  }

  static Future<double?> getVirtualCash() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getDouble(keyVirtualCash);
  }

  static Future<void> saveRealizedPnL(double pnl) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setDouble(keyRealizedPnL, pnl);
  }

  static Future<double?> getRealizedPnL() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getDouble(keyRealizedPnL);
  }

  static Future<void> savePositions(String jsonString) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(keyPositions, jsonString);
  }

  static Future<String?> getPositions() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getString(keyPositions);
  }

  static Future<void> saveTrades(String jsonString) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(keyTrades, jsonString);
  }

  static Future<String?> getTrades() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getString(keyTrades);
  }

  static Future<void> saveLimitOrders(String jsonString) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(keyLimitOrders, jsonString);
  }

  static Future<String?> getLimitOrders() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getString(keyLimitOrders);
  }

  static Future<void> saveEquityHistory(List<double> history) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(keyEquityHistory, jsonEncode(history));
  }

  static Future<List<double>?> getEquityHistory() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final raw = p.getString(keyEquityHistory);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAllPaperTradingData() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.remove(keyVirtualCash);
    await p.remove(keyPositions);
    await p.remove(keyTrades);
    await p.remove(keyLimitOrders);
    await p.remove(keyRealizedPnL);
    await p.remove(keyEquityHistory);
  }
}
