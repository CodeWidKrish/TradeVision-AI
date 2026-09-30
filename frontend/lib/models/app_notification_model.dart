import 'package:flutter/material.dart';

enum NotificationType {
  marketTiming,
  highPriorityNews,
  priceAlert,
  securityAlert,
  system,
}

enum NotificationPriority {
  normal,
  high,
  critical,
}

class AppNotificationItem {
  final String id;
  final NotificationType type;
  final String categoryTag;
  final String title;
  final String body;
  final DateTime timestamp;
  final Color accentColor;
  final String iconAsset;
  final String? route;
  final Object? routeExtra;
  final NotificationPriority priority;
  final String? actionLabel;

  AppNotificationItem({
    required this.id,
    required this.type,
    required this.categoryTag,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.accentColor = const Color(0xFF0066CC),
    this.iconAsset = 'assets/images/logo_icon.png',
    this.route,
    this.routeExtra,
    this.priority = NotificationPriority.normal,
    this.actionLabel = 'VIEW',
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isHighPriority => priority == NotificationPriority.high || priority == NotificationPriority.critical;

  factory AppNotificationItem.marketTiming({
    required String id,
    required String title,
    required String body,
    Color accentColor = const Color(0xFF00C853),
    String? route,
  }) {
    return AppNotificationItem(
      id: id,
      type: NotificationType.marketTiming,
      categoryTag: 'MARKET STATUS',
      title: title,
      body: body,
      accentColor: accentColor,
      iconAsset: 'assets/images/logo_icon.png',
      route: route ?? '/home',
      priority: NotificationPriority.high,
      actionLabel: 'OPEN MARKET',
    );
  }

  factory AppNotificationItem.breakingNews({
    required String id,
    required String title,
    required String body,
    String? relatedTicker,
    String? url,
  }) {
    return AppNotificationItem(
      id: id,
      type: NotificationType.highPriorityNews,
      categoryTag: 'BREAKING NEWS',
      title: title,
      body: body,
      accentColor: const Color(0xFFFF8C00),
      iconAsset: 'assets/images/logo_icon.png',
      route: relatedTicker != null ? '/stock-detail' : null,
      routeExtra: relatedTicker,
      priority: NotificationPriority.critical,
      actionLabel: relatedTicker != null ? 'VIEW $relatedTicker' : 'READ',
    );
  }

  factory AppNotificationItem.security({
    required String id,
    required String title,
    required String body,
  }) {
    return AppNotificationItem(
      id: id,
      type: NotificationType.securityAlert,
      categoryTag: 'SECURITY & PRIVACY',
      title: title,
      body: body,
      accentColor: const Color(0xFF6366F1),
      iconAsset: 'assets/images/logo_icon.png',
      priority: NotificationPriority.high,
      actionLabel: 'SETTINGS',
    );
  }
}
