import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../core/security_service.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Keys — centralized, never hardcode strings elsewhere
  static const _keyLoggedIn  = 'tv_is_logged_in';
  static const _keyThemeMode = 'tv_theme_mode';
  static const _keyUserEmail = 'tv_user_email';
  static const _keyUserName  = 'tv_user_name';
  static const _keyOnboarded = 'tv_has_onboarded';
  static const _keyLastLogin = 'tv_last_login_ts';
  static const _keyChartType = 'tv_chart_type';

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _validateSession(); // check session on every cold start
    } catch (e) {
      debugPrint('StorageService.init failed: $e');
      _prefs = null; // safe fallback — all getters return defaults
    }
  }

  // Session validation — auto logout if session is older than 30 days
  static void _validateSession() {
    try {
      final lastLogin = _prefs?.getInt(_keyLastLogin) ?? 0;
      if (lastLogin == 0) return;
      final lastLoginDate =
          DateTime.fromMillisecondsSinceEpoch(lastLogin);
      final daysSinceLogin =
          DateTime.now().difference(lastLoginDate).inDays;
      if (daysSinceLogin > 30) {
        // Session expired — force logout
        clearSession();
        debugPrint('Session expired — auto logout');
      }
    } catch (e) {
      debugPrint('Session validation error: $e');
    }
  }

  // Auth
  static bool getIsLoggedIn() {
    try { return _prefs?.getBool(_keyLoggedIn) ?? false; }
    catch (_) { return false; }
  }

  static Future<void> setLoggedIn(bool value) async {
    try {
      await _prefs?.setBool(_keyLoggedIn, value);
      if (value) {
        // Record login timestamp for session expiry
        await _prefs?.setInt(
          _keyLastLogin,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('setLoggedIn failed: $e');
    }
  }

  // Theme
  static String getThemeMode() {
    try { return _prefs?.getString(_keyThemeMode) ?? 'dark'; }
    catch (_) { return 'dark'; }
  }

  static Future<void> setThemeMode(String mode) async {
    try { await _prefs?.setString(_keyThemeMode, mode); }
    catch (e) { debugPrint('setThemeMode failed: $e'); }
  }

  // Onboarding
  static bool hasOnboarded() {
    try { return _prefs?.getBool(_keyOnboarded) ?? false; }
    catch (_) { return false; }
  }

  static Future<void> setOnboarded() async {
    try { await _prefs?.setBool(_keyOnboarded, true); }
    catch (e) { debugPrint('setOnboarded failed: $e'); }
  }

  // User email — stored for display only, never for auth
  static String? getUserEmail() {
    try { return _prefs?.getString(_keyUserEmail); }
    catch (_) { return null; }
  }

  static Future<void> setUserEmail(String email) async {
    // Validate before storing — never store raw unvalidated input
    if (!_isValidEmail(email)) return;
    try {
      // Store only domain-masked version for display
      // e.g. "krish@gmail.com" → store as-is but never log it
      await _prefs?.setString(_keyUserEmail, email);
    } catch (e) {
      debugPrint('setUserEmail failed');
      // Never log the actual email
    }
  }

  // User display name
  static String? getUserDisplayName() {
    try { return _prefs?.getString(_keyUserName); }
    catch (_) { return null; }
  }

  static Future<void> setUserDisplayName(String name) async {
    final sanitized = SecurityService.sanitize(name);
    if (sanitized.length < 2) return;
    try {
      await _prefs?.setString(_keyUserName, sanitized);
    } catch (e) {
      debugPrint('setUserDisplayName failed: $e');
    }
  }

  static const String _keyWatchlistSymbols = 'tv_watchlist_symbols';

  // Watchlist persistence
  static List<String> getWatchlistSymbols() {
    try {
      final list = _prefs?.getStringList(_keyWatchlistSymbols);
      if (list != null && list.isNotEmpty) return list;
    } catch (_) {}
    return ['RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'ICICIBANK'];
  }

  static Future<void> setWatchlistSymbols(List<String> symbols) async {
    try {
      await _prefs?.setStringList(_keyWatchlistSymbols, symbols);
    } catch (e) {
      debugPrint('setWatchlistSymbols failed: $e');
    }
  }

  // Clear everything on logout
  static Future<void> clearSession() async {
    try {
      await _prefs?.remove(_keyLoggedIn);
      await _prefs?.remove(_keyUserEmail);
      await _prefs?.remove(_keyUserName);
      await _prefs?.remove(_keyLastLogin);
      // Keep theme preference — user still wants their theme after logout
    } catch (e) {
      debugPrint('clearSession failed: $e');
    }
  }

  // Chart Type
  static String getChartType() {
    try {
      final saved = _prefs?.getString(_keyChartType);
      if (saved == null || saved == 'bar') return 'candlestick';
      return saved;
    } catch (_) {
      return 'candlestick';
    }
  }

  static Future<void> setChartType(String type) async {
    try {
      await _prefs?.setString(_keyChartType, type);
    } catch (e) {
      debugPrint('setChartType failed: $e');
    }
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
