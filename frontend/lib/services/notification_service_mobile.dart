import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  tz.Location? _istLocation;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Initialize timezone database for OS AlarmManager exact schedules
      try {
        tz.initializeTimeZones();
        _istLocation = tz.getLocation('Asia/Kolkata');
        tz.setLocalLocation(_istLocation!);
      } catch (tzError) {
        debugPrint('[NotificationService] Timezone init fallback: $tzError');
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[NotificationService] Notification clicked: ${response.payload}');
        },
      );

      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // High importance channel for Real-time Price and Institutional Alerts
        const AndroidNotificationChannel priceChannel = AndroidNotificationChannel(
          'tradevision_price_alerts',
          'TradeVision Price Alerts',
          description: 'Real-time stock price and institutional signal alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // Persistent High Importance Channel for Market Opening, Pre-Open, Closing Alarms
        const AndroidNotificationChannel marketChannel = AndroidNotificationChannel(
          'tradevision_market_milestones',
          'TradeVision Market Sessions & Milestones',
          description: 'Scheduled opening, closing, pre-open session & market alerts (fires even when app is closed)',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        // High Importance Channel for Breaking News & Market Pulse
        const AndroidNotificationChannel newsChannel = AndroidNotificationChannel(
          'tradevision_breaking_news',
          'TradeVision Breaking News & Intelligence',
          description: 'Urgent market catalysts and breaking stock news alerts',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidImplementation.createNotificationChannel(priceChannel);
        await androidImplementation.createNotificationChannel(marketChannel);
        await androidImplementation.createNotificationChannel(newsChannel);

        await androidImplementation.requestNotificationsPermission();
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (_) {}
      }

      // Schedule persistent OS-level alarms for market milestones
      await scheduleMarketSessionAlarms();
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  /// Request runtime system notification permission (Android 13+ & iOS)
  Future<bool> requestPermission() async {
    try {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        try {
          await androidImplementation.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? false;
      }
      final iosImplementation =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
    }
    return false;
  }

  /// Schedules daily recurring OS-level alarms with Android AlarmManager.
  /// These fire at exact IST market times even when TradeVision is closed or terminated.
  Future<void> scheduleMarketSessionAlarms() async {
    try {
      final loc = _istLocation ?? tz.local;

      // 1. Morning AI Market Briefing at 08:30 AM IST
      await _scheduleDailyAlarm(
        id: 9000,
        title: 'TradeVision Morning AI Briefing',
        body: 'Pre-market sentiment, GIFT Nifty indications, and top institutional setups ready for today.',
        hour: 8,
        minute: 30,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/market-charts',
      );

      // 2. NSE / BSE Pre-Open Session at 09:00 AM IST
      await _scheduleDailyAlarm(
        id: 9001,
        title: 'NSE/BSE Pre-Open Session Started (9:00 AM)',
        body: 'Order matching & equilibrium price discovery is now live. Indicative opening calls ready.',
        hour: 9,
        minute: 0,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/market-charts',
      );

      // 3. Indian Stock Market Regular Open at 09:15 AM IST
      await _scheduleDailyAlarm(
        id: 9002,
        title: 'Indian Stock Market is LIVE! (9:15 AM)',
        body: 'NSE & BSE regular trading is officially OPEN. Real-time AI signals and momentum flow active.',
        hour: 9,
        minute: 15,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/home',
      );

      // 4. Intraday Power Hour / Square-Off Warning at 15:00 PM IST (3:00 PM)
      await _scheduleDailyAlarm(
        id: 9003,
        title: 'Market Power Hour Active (3:00 PM)',
        body: 'Intraday square-off window and closing volume surge underway. Normal session ends at 3:30 PM.',
        hour: 15,
        minute: 0,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/market-charts',
      );

      // 5. Market Close at 15:30 PM IST (3:30 PM)
      await _scheduleDailyAlarm(
        id: 9004,
        title: 'Market Trading Session Closed (3:30 PM)',
        body: 'Normal trading has concluded for the day. Review your daily P&L and AI closing market wrap.',
        hour: 15,
        minute: 30,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/market-charts',
      );

      // 6. Post-Market Settlement Close at 16:00 PM IST (4:00 PM)
      await _scheduleDailyAlarm(
        id: 9005,
        title: 'Post-Market Settlement Closed (4:00 PM)',
        body: 'Official closing prices finalized. Markets reopen tomorrow at 9:00 AM IST.',
        hour: 16,
        minute: 0,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/home',
      );

      // 7. Evening AI Wrap & Forecasts at 18:30 PM IST (6:30 PM)
      await _scheduleDailyAlarm(
        id: 9006,
        title: 'Daily Market Wrap & AI Forecasts (6:30 PM)',
        body: 'Institutional FII/DII flow breakdown and updated ML price targets are ready for review.',
        hour: 18,
        minute: 30,
        location: loc,
        channelId: 'tradevision_market_milestones',
        channelName: 'TradeVision Market Sessions & Milestones',
        payload: '/home',
      );

      // 8. Register periodic pulse for background alerts when app remains closed
      await _schedulePeriodicBackgroundPulse();
      debugPrint('[NotificationService] Market session alarms successfully registered with OS AlarmManager.');
    } catch (e) {
      debugPrint('[NotificationService] scheduleMarketSessionAlarms error: $e');
    }
  }

  Future<void> _scheduleDailyAlarm({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required tz.Location location,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'TradeVision Market Session',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> _schedulePeriodicBackgroundPulse() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'tradevision_breaking_news',
        'TradeVision Breaking News & Intelligence',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

      // Periodically trigger intelligence pulse (runs daily in background)
      await _plugin.periodicallyShow(
        id: 9100,
        title: 'TradeVision Market Pulse',
        body: 'Real-time AI scanners are tracking institutional order blocks and breaking news catalysts.',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/home',
      );
    } catch (e) {
      debugPrint('[NotificationService] _schedulePeriodicBackgroundPulse error: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final safeId = (id.abs()) % 2147483647;
      final androidDetails = AndroidNotificationDetails(
        'tradevision_price_alerts',
        'TradeVision Price Alerts',
        channelDescription: 'Real-time stock price and institutional signal alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'TradeVision Alert',
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id: safeId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showNotification error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] cancelAll error: $e');
    }
  }
}
