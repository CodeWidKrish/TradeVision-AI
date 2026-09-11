import 'dart:math';
import 'package:flutter/foundation.dart';

class SecurityService {

  // 1. SESSION TIMEOUT — auto logout after 15 min of inactivity
  static DateTime _lastActivity = DateTime.now();
  static const Duration _sessionTimeout = Duration(minutes: 15);

  static void recordActivity() {
    _lastActivity = DateTime.now();
  }

  static bool get isSessionExpired {
    return DateTime.now().difference(_lastActivity) > _sessionTimeout;
  }

  // 2. SCREENSHOT PREVENTION flag (Flutter Web — informational only)
  static bool get screenshotProtectionEnabled => !kDebugMode;

  // 3. INPUT VALIDATION — centralized
  static String sanitize(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '')   // strip HTML tags
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(';', '')
        .replaceAll(RegExp(r'\s+'), ' ');      // normalize whitespace
  }

  // 4. SAFE NUMBER PARSING — never crash on bad data
  static double safeParseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try { return double.parse(value.toString()); }
    catch (_) { return fallback; }
  }

  static int safeParseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    try { return int.parse(value.toString()); }
    catch (_) { return fallback; }
  }

  // 5. SECURE TOKEN GENERATOR — for request signing
  static String generateRequestId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // 6. DATA MASKING — for displaying sensitive info
  static String maskEmail(String email) {
    if (!email.contains('@')) return '***';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '**@$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  // 7. RATE LIMITER — reusable across the app
  static final Map<String, _RateLimitState> _rateLimits = {};

  static bool isRateLimited(String key, {int maxCalls = 5, Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final state = _rateLimits[key] ?? _RateLimitState(window: window);

    // Reset window if expired
    if (now.difference(state.windowStart) > window) {
      _rateLimits[key] = _RateLimitState(window: window);
      return false;
    }

    state.callCount++;
    _rateLimits[key] = state;
    return state.callCount > maxCalls;
  }
}

class _RateLimitState {
  int callCount = 1;
  final DateTime windowStart = DateTime.now();
  final Duration window;
  _RateLimitState({required this.window});
}
