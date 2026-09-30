import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/app_notification_model.dart';
import '../models/alert_model.dart';
import 'alert_service.dart';
import 'notification_service.dart';
import 'live_news_service.dart';
import 'storage_service.dart';

enum MarketTimingMilestone {
  preOpen,
  marketOpen,
  marketClose,
  postMarketClose,
}

class AppNotificationHub {
  static final AppNotificationHub instance = AppNotificationHub._internal();
  AppNotificationHub._internal();

  final StreamController<AppNotificationItem> _controller =
      StreamController<AppNotificationItem>.broadcast();
  Stream<AppNotificationItem> get onNotification => _controller.stream;

  final List<AppNotificationItem> _history = [];
  List<AppNotificationItem> get history => List.unmodifiable(_history);

  Timer? _clockMonitorTimer;
  Timer? _newsMonitorTimer;
  final Set<String> _triggeredMilestonesToday = {};
  final Set<String> _seenNewsTitles = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Ensure system notification channel and permissions are ready
    try {
      await NotificationService.instance.init();
      unawaited(NotificationService.instance.requestPermission());
    } catch (e) {
      debugPrint('[AppNotificationHub] NotificationService init error: $e');
    }

    // 1. Listen to Price Alerts from AlertService
    AlertService.instance.onAlertTriggered.listen((PriceAlert alert) {
      if (!StorageService.isPriceAlertsEnabled()) return;
      final notif = AppNotificationItem(
        id: 'alert_${alert.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.priceAlert,
        categoryTag: 'PRICE ALERT TRIGGERED',
        title: '${alert.ticker} TARGET REACHED',
        body: alert.triggerMessage ?? alert.title,
        accentColor: const Color(0xFF0066CC),
        iconAsset: 'assets/images/logo_icon.png',
        route: '/stock-detail',
        routeExtra: alert.ticker,
        priority: NotificationPriority.high,
        actionLabel: 'VIEW ${alert.ticker}',
      );
      notify(notif);
    });

    // 2. Start Real-time IST Market Timing Monitor
    _startMarketTimingMonitor();

    // 3. Start High Priority Stock News Watcher
    _startHighPriorityNewsMonitor();
  }

  void notify(AppNotificationItem item) {
    _history.insert(0, item);
    if (_history.length > 50) {
      _history.removeLast();
    }

    // Trigger haptic vibration
    try {
      if (item.priority == NotificationPriority.critical) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}

    // Emit to in-app banner stream
    _controller.add(item);

    // Also trigger system/browser heads-up notification with official logo
    try {
      final safeId = (item.id.hashCode.abs()) % 2147483647;
      NotificationService.instance.showNotification(
        id: safeId,
        title: '${item.categoryTag}: ${item.title}',
        body: item.body,
        payload: item.route,
      );
    } catch (e) {
      debugPrint('[AppNotificationHub] System notification error: $e');
    }
  }

  void _startMarketTimingMonitor() {
    _clockMonitorTimer?.cancel();
    // Check every 10 seconds for real-time precision
    _clockMonitorTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkMarketSchedule();
    });

    // Initial check immediately
    _checkMarketSchedule();
  }

  void _checkMarketSchedule() {
    if (!StorageService.isMarketTimingNotificationsEnabled()) return;
    final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final weekday = ist.weekday; // 1=Mon, 7=Sun
    final isWeekend = weekday == 6 || weekday == 7;
    final dateStr = '${ist.year}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';

    final totalMinutes = ist.hour * 60 + ist.minute;

    // NSE Trading Timings (IST):
    // 09:00 AM (540m) - Pre-open session
    // 09:15 AM (555m) - Normal market open
    // 15:30 PM (930m) - Normal market close
    // 16:00 PM (960m) - Post-market close

    if (!isWeekend) {
      // 1. Pre-Open (09:00 AM - 09:02 AM is the active notification window)
      final preOpenKey = '${dateStr}_preOpen';
      if (totalMinutes >= 540 && totalMinutes < 542) {
        if (!_triggeredMilestonesToday.contains(preOpenKey)) {
          _triggeredMilestonesToday.add(preOpenKey);
          notify(AppNotificationItem.marketTiming(
            id: preOpenKey,
            title: 'NSE/BSE Pre-Open Session Started',
            body: 'Pre-market order accumulation and equilibrium price discovery is now active (9:00 AM IST).',
            accentColor: const Color(0xFFFF8C00),
          ));
        }
      } else if (totalMinutes >= 542) {
        // Mark as already past for today so opening later doesn't trigger a stale alert
        _triggeredMilestonesToday.add(preOpenKey);
      }

      // 2. Market Open (09:15 AM - 09:17 AM is the active notification window)
      final openKey = '${dateStr}_marketOpen';
      if (totalMinutes >= 555 && totalMinutes < 557) {
        if (!_triggeredMilestonesToday.contains(openKey)) {
          _triggeredMilestonesToday.add(openKey);
          notify(AppNotificationItem.marketTiming(
            id: openKey,
            title: 'Indian Stock Market is LIVE!',
            body: 'NSE & BSE regular trading session is officially OPEN. Real-time AI signals and institutional momentum tracking active.',
            accentColor: const Color(0xFF00C853),
          ));
        }
      } else if (totalMinutes >= 557) {
        // Mark as already past for today
        _triggeredMilestonesToday.add(openKey);
      }

      // 3. Market Close (15:30 PM - 15:32 PM is the active notification window)
      final closeKey = '${dateStr}_marketClose';
      if (totalMinutes >= 930 && totalMinutes < 932) {
        if (!_triggeredMilestonesToday.contains(closeKey)) {
          _triggeredMilestonesToday.add(closeKey);
          notify(AppNotificationItem.marketTiming(
            id: closeKey,
            title: 'Market Trading Session Closed',
            body: 'Normal trading has concluded at 3:30 PM IST. Review your daily P&L and AI closing market wrap.',
            accentColor: const Color(0xFFFF3B3B),
          ));
        }
      } else if (totalMinutes >= 932) {
        _triggeredMilestonesToday.add(closeKey);
      }

      // 4. Post-Market Close (16:00 PM - 16:02 PM is the active notification window)
      final postCloseKey = '${dateStr}_postClose';
      if (totalMinutes >= 960 && totalMinutes < 962) {
        if (!_triggeredMilestonesToday.contains(postCloseKey)) {
          _triggeredMilestonesToday.add(postCloseKey);
          notify(AppNotificationItem.marketTiming(
            id: postCloseKey,
            title: 'Post-Market Settlement Closed',
            body: 'Closing price determination and post-market window has closed. Markets reopen tomorrow at 9:00 AM IST.',
            accentColor: const Color(0xFF64748B),
          ));
        }
      } else if (totalMinutes >= 962) {
        _triggeredMilestonesToday.add(postCloseKey);
      }
    }
  }

  bool _hasInitialNewsSeeded = false;

  void _startHighPriorityNewsMonitor() {
    _newsMonitorTimer?.cancel();
    // Poll for breaking news every 30 seconds
    _newsMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _scanHighPriorityNews();
    });

    // Initial scan
    Future.delayed(const Duration(milliseconds: 1500), () {
      _scanHighPriorityNews(initialSeed: true);
    });
  }

  Future<void> _scanHighPriorityNews({bool initialSeed = false}) async {
    if (!StorageService.isHighPriorityNewsEnabled()) return;
    try {
      final articles = await LiveNewsService.fetchLiveNews(limit: 10);
      if (!_hasInitialNewsSeeded || initialSeed) {
        _hasInitialNewsSeeded = true;
        // On initial startup, check if the latest top article is a major breaking headline
        if (articles.isNotEmpty) {
          final first = articles.first;
          final title = (first['title'] as String?) ?? '';
          final sentiment = (first['sentiment'] as String?)?.toUpperCase() ?? 'NEUTRAL';
          if (title.isNotEmpty && _isBreakingHeadline(title, sentiment)) {
            final key = 'seed_news_${title.hashCode}';
            if (!_seenNewsTitles.contains(title)) {
              _seenNewsTitles.add(title);
              final related = first['related_ticker'] as String?;
              final source = first['source'] as String? ?? 'Financial Desk';
              notify(AppNotificationItem.breakingNews(
                id: key,
                title: title,
                body: '$source reports high market impact. Review AI volatility assessment.',
                relatedTicker: related,
                url: first['url'] as String?,
              ));
            }
          }
        }
        for (final article in articles) {
          final title = (article['title'] as String?) ?? '';
          if (title.isNotEmpty) _seenNewsTitles.add(title);
        }
        return;
      }

      for (final article in articles) {
        final title = (article['title'] as String?) ?? '';
        if (title.isEmpty || _seenNewsTitles.contains(title)) continue;

        _seenNewsTitles.add(title);
        final sentiment = (article['sentiment'] as String?)?.toUpperCase() ?? 'NEUTRAL';
        final isUrgent = _isBreakingHeadline(title, sentiment);

        if (isUrgent) {
          final related = article['related_ticker'] as String?;
          final source = article['source'] as String? ?? 'Financial Desk';
          notify(AppNotificationItem.breakingNews(
            id: 'news_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}',
            title: title,
            body: '$source reports high market impact. Review AI volatility assessment.',
            relatedTicker: related,
            url: article['url'] as String?,
          ));
          // Break so we don't spam multiple simultaneously
          break;
        }
      }
    } catch (e) {
      debugPrint('[AppNotificationHub] News scan error: $e');
    }
  }

  bool _isBreakingHeadline(String title, String sentiment) {
    final lower = title.toLowerCase();
    final urgentKeywords = [
      'breaking',
      'rbi',
      'interest rate',
      'inflation',
      'budget',
      'gdp',
      'q3 result',
      'q4 result',
      'profit surges',
      'profit jumps',
      'shares crash',
      'shares surge',
      'order win',
      'sebi notice',
      'acquisition',
      'us fed',
    ];

    for (final kw in urgentKeywords) {
      if (lower.contains(kw)) return true;
    }

    if (sentiment == 'VERY POSITIVE' || sentiment == 'VERY NEGATIVE') {
      return true;
    }

    return false;
  }

  /// Manually trigger a market timing alert (useful for demonstration or testing)
  void triggerMarketTimingNotification(MarketTimingMilestone milestone) {
    switch (milestone) {
      case MarketTimingMilestone.preOpen:
        notify(AppNotificationItem.marketTiming(
          id: 'test_pre_open_${DateTime.now().millisecondsSinceEpoch}',
          title: 'NSE/BSE Pre-Open Session Started',
          body: 'Pre-market order matching active (9:00 AM - 9:08 AM IST). Indicative opening calls ready.',
          accentColor: const Color(0xFFFF8C00),
        ));
        break;
      case MarketTimingMilestone.marketOpen:
        notify(AppNotificationItem.marketTiming(
          id: 'test_market_open_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Indian Stock Market is LIVE!',
          body: 'NSE & BSE regular trading session is officially OPEN. Real-time AI signals and algorithmic flow active.',
          accentColor: const Color(0xFF00C853),
        ));
        break;
      case MarketTimingMilestone.marketClose:
        notify(AppNotificationItem.marketTiming(
          id: 'test_market_close_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Market Trading Session Closed',
          body: 'NSE/BSE regular session closed at 3:30 PM IST. Review your daily P&L and AI closing summary.',
          accentColor: const Color(0xFFFF3B3B),
        ));
        break;
      case MarketTimingMilestone.postMarketClose:
        notify(AppNotificationItem.marketTiming(
          id: 'test_post_close_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Post-Market Settlement Closed',
          body: 'Closing price determination and post-market window has closed for the day.',
          accentColor: const Color(0xFF64748B),
        ));
        break;
    }
  }

  void dispose() {
    _clockMonitorTimer?.cancel();
    _newsMonitorTimer?.cancel();
    _controller.close();
  }
}
