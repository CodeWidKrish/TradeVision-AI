import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppErrorHandler {
  // Initialize once in main() before runApp
  static void initialize() {
    // Catch all Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kReleaseMode) {
        // In production — log silently, never crash
        _logError('Flutter Error', details.exception, details.stack);
      }
    };

    // Catch all async/platform errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true; // returning true prevents crash
    };

    // Custom ErrorWidget fallback to prevent red screen of death
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFF8892A4)),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8ECF0),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app or try again.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8892A4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  static void _logError(String type, Object error, StackTrace? stack) {
    // Replace with real logging (Firebase Crashlytics, Sentry) later
    debugPrint('[$type] ${error.toString()}');
    debugPrint(stack?.toString() ?? 'No stack trace');
  }

  // Safe async wrapper — use this for every API call
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    T? fallback,
  }) async {
    try {
      return await operation();
    } on NetworkException catch (e) {
      debugPrint('Network error: ${e.message}');
      return fallback;
    } on TimeoutException catch (_) {
      debugPrint('Request timed out');
      return fallback;
    } on FormatException catch (e) {
      debugPrint('Data format error: ${e.message}');
      return fallback;
    } catch (e, stack) {
      _logError(errorMessage ?? 'Unknown Error', e, stack);
      return fallback;
    }
  }
}

// Custom exceptions
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
}
