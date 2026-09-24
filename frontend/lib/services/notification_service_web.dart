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
    if (kIsWeb) {
      try {
        if (html.Notification.supported) {
          if (html.Notification.permission == 'granted') {
            html.Notification(
              title,
              body: body,
              icon: 'favicon.png',
            );
          } else if (html.Notification.permission == 'default') {
            final res = await html.Notification.requestPermission();
            if (res == 'granted') {
              html.Notification(
                title,
                body: body,
                icon: 'favicon.png',
              );
            }
          }
        }
      } catch (e) {
        debugPrint('[NotificationService] Web showNotification popup error: $e');
      }
    }
  }
}
