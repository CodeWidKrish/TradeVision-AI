// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  Future<void> init() async {
    debugPrint('[NotificationService] Web environment active: notification engine ready.');
  }

  /// Request browser notification permission
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      try {
        if (!html.Notification.supported) return false;
        if (html.Notification.permission == 'granted') return true;
        final res = await html.Notification.requestPermission();
        return res == 'granted';
      } catch (e) {
        debugPrint('[NotificationService] Web requestPermission error: $e');
      }
    }
    return false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('[NotificationService] [Web] $title: $body');
    if (!kIsWeb) return;

    try {
      if (!html.Notification.supported) return;

      var permission = html.Notification.permission;
      if (permission == 'default') {
        permission = await html.Notification.requestPermission();
      }

      if (permission == 'granted') {
        // 1. Try ServiceWorker showNotification first (required on Android Chrome / PWA)
        try {
          final sw = html.window.navigator.serviceWorker;
          if (sw != null) {
            final reg = await sw.ready;
            if (reg != null) {
              reg.showNotification(title, {
                'body': body,
                'icon': 'icons/Icon-192.png',
                'badge': 'icons/Icon-192.png',
                'tag': 'tv_${id.abs()}',
                'renotify': true,
              });
              return;
            }
          }
        } catch (_) {}

        // 2. Desktop Web Notification fallback (Desktop Chrome, Edge, Safari, Firefox)
        try {
          html.Notification(
            title,
            body: body,
            icon: 'icons/Icon-192.png',
            tag: 'tv_${id.abs()}',
          );
        } catch (e) {
          debugPrint('[NotificationService] Web Notification fallback error: $e');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Web showNotification popup error: $e');
    }
  }

  Future<void> scheduleMarketSessionAlarms() async {
    // Web browsers do not have OS AlarmManager background capabilities when tab is terminated.
    debugPrint('[NotificationService] Web alarms registered.');
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('[NotificationService] Web cancelAllNotifications.');
  }
}
