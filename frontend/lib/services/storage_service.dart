import 'dart:convert';
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
  static const _keyRememberCredentials = 'tv_remember_credentials';
  static const _keySavedPassword = 'tv_saved_password';

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

  // App Lock & Security
  static const _keyAppLockEnabled = 'tv_app_lock_enabled';
  static const _keyAppLockPin = 'tv_app_lock_pin';
  static const _keyBiometricEnabled = 'tv_biometric_enabled';

  static bool isAppLockEnabled() {
    try { return _prefs?.getBool(_keyAppLockEnabled) ?? false; }
    catch (_) { return false; }
  }

  static Future<void> setAppLockEnabled(bool val) async {
    try { await _prefs?.setBool(_keyAppLockEnabled, val); }
    catch (e) { debugPrint('setAppLockEnabled failed: $e'); }
  }

  static String? getAppLockPin() {
    try { return _prefs?.getString(_keyAppLockPin); }
    catch (_) { return null; }
  }

  static Future<void> setAppLockPin(String pin) async {
    try { await _prefs?.setString(_keyAppLockPin, pin); }
    catch (e) { debugPrint('setAppLockPin failed: $e'); }
  }

  static bool isBiometricEnabled() {
    try { return _prefs?.getBool(_keyBiometricEnabled) ?? true; }
    catch (_) { return true; }
  }

  static Future<void> setBiometricEnabled(bool val) async {
    try { await _prefs?.setBool(_keyBiometricEnabled, val); }
    catch (e) { debugPrint('setBiometricEnabled failed: $e'); }
  }

  static bool verifyPin(String enteredPin) {
    final saved = getAppLockPin() ?? '1234';
    return saved == enteredPin;
  }

  static Future<void> resetAppLockPin({String newPin = '1234'}) async {
    try {
      await _prefs?.setString(_keyAppLockPin, newPin);
    } catch (e) {
      debugPrint('resetAppLockPin failed: $e');
    }
  }

  // Remember Credentials & Saved Password Management
  static bool isRememberCredentialsEnabled() {
    try { return _prefs?.getBool(_keyRememberCredentials) ?? true; }
    catch (_) { return true; }
  }

  static Future<void> setRememberCredentialsEnabled(bool val) async {
    try {
      await _prefs?.setBool(_keyRememberCredentials, val);
      if (!val) {
        await _prefs?.remove(_keySavedPassword);
      }
    } catch (e) {
      debugPrint('setRememberCredentialsEnabled failed: $e');
    }
  }

  static String? getSavedPassword() {
    try { return _prefs?.getString(_keySavedPassword); }
    catch (_) { return null; }
  }

  static Future<void> setSavedPassword(String password) async {
    try {
      await _prefs?.setString(_keySavedPassword, password);
    } catch (e) {
      debugPrint('setSavedPassword failed: $e');
    }
  }

  static Future<void> clearSavedCredentials() async {
    try {
      await _prefs?.remove(_keySavedPassword);
      await _prefs?.setBool(_keyRememberCredentials, false);
    } catch (e) {
      debugPrint('clearSavedCredentials failed: $e');
    }
  }

  static Future<void> saveUserCredentials({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    try {
      await setUserEmail(email);
      await setRememberCredentialsEnabled(remember);
      if (remember) {
        await setSavedPassword(password);
      } else {
        await _prefs?.remove(_keySavedPassword);
      }
    } catch (e) {
      debugPrint('saveUserCredentials failed: $e');
    }
  }

  static Future<void> resetPassword(String newPassword) async {
    try {
      await setSavedPassword(newPassword);
    } catch (e) {
      debugPrint('resetPassword failed: $e');
    }
  }

  // 1. Dynamic User Identity & KYC
  static const _keyUserPan = 'tv_user_pan';
  static const _keyDematClientId = 'tv_demat_client_id';
  static const _keyUserPhone = 'tv_user_phone';
  static const _keyKycStatus = 'tv_kyc_status';
  static const _keyAccountTier = 'tv_account_tier';

  static String? getUserPan() {
    try { return _prefs?.getString(_keyUserPan); }
    catch (_) { return null; }
  }

  static Future<void> setUserPan(String pan) async {
    try { await _prefs?.setString(_keyUserPan, pan.toUpperCase().trim()); }
    catch (e) { debugPrint('setUserPan failed: $e'); }
  }

  static String? getDematClientId() {
    try { return _prefs?.getString(_keyDematClientId); }
    catch (_) { return null; }
  }

  static Future<void> setDematClientId(String id) async {
    try { await _prefs?.setString(_keyDematClientId, id.trim()); }
    catch (e) { debugPrint('setDematClientId failed: $e'); }
  }

  static String? getUserPhone() {
    try { return _prefs?.getString(_keyUserPhone); }
    catch (_) { return null; }
  }

  static Future<void> setUserPhone(String phone) async {
    try { await _prefs?.setString(_keyUserPhone, phone.trim()); }
    catch (e) { debugPrint('setUserPhone failed: $e'); }
  }

  static String getKycStatus() {
    try {
      final pan = getUserPan();
      if (pan != null && pan.isNotEmpty) {
        return _prefs?.getString(_keyKycStatus) ?? 'VERIFIED (SEBI Compliant)';
      }
      return _prefs?.getString(_keyKycStatus) ?? 'PENDING SUBMISSION';
    } catch (_) {
      return 'PENDING SUBMISSION';
    }
  }

  static Future<void> setKycStatus(String status) async {
    try { await _prefs?.setString(_keyKycStatus, status); }
    catch (e) { debugPrint('setKycStatus failed: $e'); }
  }

  static String getAccountTier() {
    try { return _prefs?.getString(_keyAccountTier) ?? 'Pro AI Trader'; }
    catch (_) { return 'Pro AI Trader'; }
  }

  static Future<void> setAccountTier(String tier) async {
    try { await _prefs?.setString(_keyAccountTier, tier); }
    catch (e) { debugPrint('setAccountTier failed: $e'); }
  }

  // 2. Dynamic Linked Brokers
  static const _keyLinkedBrokers = 'tv_linked_brokers';

  static List<Map<String, dynamic>> getLinkedBrokers() {
    try {
      final raw = _prefs?.getString(_keyLinkedBrokers);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('getLinkedBrokers failed: $e');
    }
    return [
      {
        'id': 'zerodha',
        'name': 'Zerodha Kite',
        'connected': false,
        'clientId': '',
        'apiKey': '',
        'connectedAt': null,
      },
      {
        'id': 'groww',
        'name': 'Groww',
        'connected': false,
        'clientId': '',
        'apiKey': '',
        'connectedAt': null,
      },
      {
        'id': 'angel',
        'name': 'Angel One',
        'connected': false,
        'clientId': '',
        'apiKey': '',
        'connectedAt': null,
      },
      {
        'id': 'upstox',
        'name': 'Upstox Pro',
        'connected': false,
        'clientId': '',
        'apiKey': '',
        'connectedAt': null,
      },
      {
        'id': 'dhan',
        'name': 'Dhan HQ',
        'connected': false,
        'clientId': '',
        'apiKey': '',
        'connectedAt': null,
      },
    ];
  }

  static Future<void> setBrokerConnection({
    required String brokerId,
    required bool connected,
    String? clientId,
    String? apiKey,
  }) async {
    try {
      final brokers = getLinkedBrokers();
      final idx = brokers.indexWhere((b) => b['id'] == brokerId);
      if (idx != -1) {
        brokers[idx]['connected'] = connected;
        if (connected) {
          if (clientId != null) brokers[idx]['clientId'] = clientId;
          if (apiKey != null) brokers[idx]['apiKey'] = apiKey;
          brokers[idx]['connectedAt'] = DateTime.now().toIso8601String();
        } else {
          brokers[idx]['clientId'] = '';
          brokers[idx]['apiKey'] = '';
          brokers[idx]['connectedAt'] = null;
        }
        await _prefs?.setString(_keyLinkedBrokers, jsonEncode(brokers));
      }
    } catch (e) {
      debugPrint('setBrokerConnection failed: $e');
    }
  }

  // 3. Dynamic Notification Preferences
  static const _keyNotifPriceAlerts = 'tv_notif_price_alerts';
  static const _keyNotifMarketTiming = 'tv_notif_market_timing';
  static const _keyNotifHighPriorityNews = 'tv_notif_high_priority_news';
  static const _keyNotifAiInsights = 'tv_notif_ai_insights';

  static bool isPriceAlertsEnabled() {
    try { return _prefs?.getBool(_keyNotifPriceAlerts) ?? true; }
    catch (_) { return true; }
  }

  static Future<void> setPriceAlertsEnabled(bool val) async {
    try { await _prefs?.setBool(_keyNotifPriceAlerts, val); }
    catch (e) { debugPrint('setPriceAlertsEnabled failed: $e'); }
  }

  static bool isMarketTimingNotificationsEnabled() {
    try { return _prefs?.getBool(_keyNotifMarketTiming) ?? true; }
    catch (_) { return true; }
  }

  static Future<void> setMarketTimingNotificationsEnabled(bool val) async {
    try { await _prefs?.setBool(_keyNotifMarketTiming, val); }
    catch (e) { debugPrint('setMarketTimingNotificationsEnabled failed: $e'); }
  }

  static bool isHighPriorityNewsEnabled() {
    try { return _prefs?.getBool(_keyNotifHighPriorityNews) ?? true; }
    catch (_) { return true; }
  }

  static Future<void> setHighPriorityNewsEnabled(bool val) async {
    try { await _prefs?.setBool(_keyNotifHighPriorityNews, val); }
    catch (e) { debugPrint('setHighPriorityNewsEnabled failed: $e'); }
  }

  static bool isAiInsightsNotifEnabled() {
    try { return _prefs?.getBool(_keyNotifAiInsights) ?? true; }
    catch (_) { return true; }
  }

  static Future<void> setAiInsightsNotifEnabled(bool val) async {
    try { await _prefs?.setBool(_keyNotifAiInsights, val); }
    catch (e) { debugPrint('setAiInsightsNotifEnabled failed: $e'); }
  }

  // 4. Dynamic Trading & Risk Preferences
  static const _keyRiskProfile = 'tv_risk_profile';
  static const _keyDefaultOrderType = 'tv_default_order_type';
  static const _keyStopLossPct = 'tv_stop_loss_pct';
  static const _keyTargetProfitPct = 'tv_target_profit_pct';

  static String getRiskProfile() {
    try { return _prefs?.getString(_keyRiskProfile) ?? 'Moderate'; }
    catch (_) { return 'Moderate'; }
  }

  static Future<void> setRiskProfile(String profile) async {
    try { await _prefs?.setString(_keyRiskProfile, profile); }
    catch (e) { debugPrint('setRiskProfile failed: $e'); }
  }

  static String getDefaultOrderType() {
    try { return _prefs?.getString(_keyDefaultOrderType) ?? 'MARKET'; }
    catch (_) { return 'MARKET'; }
  }

  static Future<void> setDefaultOrderType(String type) async {
    try { await _prefs?.setString(_keyDefaultOrderType, type); }
    catch (e) { debugPrint('setDefaultOrderType failed: $e'); }
  }

  static double getStopLossPct() {
    try { return _prefs?.getDouble(_keyStopLossPct) ?? 2.5; }
    catch (_) { return 2.5; }
  }

  static Future<void> setStopLossPct(double pct) async {
    try { await _prefs?.setDouble(_keyStopLossPct, pct); }
    catch (e) { debugPrint('setStopLossPct failed: $e'); }
  }

  static double getTargetProfitPct() {
    try { return _prefs?.getDouble(_keyTargetProfitPct) ?? 5.0; }
    catch (_) { return 5.0; }
  }

  static Future<void> setTargetProfitPct(double pct) async {
    try { await _prefs?.setDouble(_keyTargetProfitPct, pct); }
    catch (e) { debugPrint('setTargetProfitPct failed: $e'); }
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
