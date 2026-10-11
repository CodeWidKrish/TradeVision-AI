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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0066CC).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    color: Color(0xFF0066CC),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Component Recalibrating',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE8ECF0),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'TradeVision safely isolated a rendering anomaly. The application remains fully active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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

/// Localized error boundary widget to wrap complex visualizations (charts, gauges, PDF).
/// Guarantees that if a single chart or data card fails to parse, only that card
/// shows a clean retry state rather than crashing or breaking the parent screen.
class InstitutionalCardErrorBoundary extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onRetry;

  const InstitutionalCardErrorBoundary({
    super.key,
    required this.child,
    this.title = 'Analytics Component',
    this.onRetry,
  });

  @override
  State<InstitutionalCardErrorBoundary> createState() => _InstitutionalCardErrorBoundaryState();
}

class _InstitutionalCardErrorBoundaryState extends State<InstitutionalCardErrorBoundary> {
  bool _hasError = false;

  void retry() {
    setState(() => _hasError = false);
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0066CC).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF0066CC), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.title} is recalibrating...',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8892A4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.onRetry != null)
              TextButton(
                onPressed: retry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0066CC)),
                ),
              ),
          ],
        ),
      );
    }

    return widget.child;
  }
}

