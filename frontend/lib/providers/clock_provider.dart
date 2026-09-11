import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MarketStatus { open, preOpen, closed }

class ISTClockNotifier extends StateNotifier<DateTime> {
  Timer? _timer;

  ISTClockNotifier() : super(_nowIST()) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = _nowIST();
    });
  }

  static DateTime _nowIST() {
    // IST = UTC + 5 hours 30 minutes — no API needed
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final istClockProvider = StateNotifierProvider<ISTClockNotifier, DateTime>((ref) {
  return ISTClockNotifier();
});

// Convenience provider for formatted time string
final istTimeStringProvider = Provider<String>((ref) {
  final now = ref.watch(istClockProvider);
  final hour = now.hour;
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12
      ? hour - 12
      : hour == 0
          ? 12
          : hour;
  return '$displayHour:$minute:$second $period IST';
});

// Market status provider — NSE is open 9:15 AM to 3:30 PM IST on weekdays
final marketStatusProvider = Provider<MarketStatus>((ref) {
  final now = ref.watch(istClockProvider);
  final weekday = now.weekday; // 1=Mon, 7=Sun
  final totalMinutes = now.hour * 60 + now.minute;
  const marketOpen = 9 * 60 + 15;   // 9:15 AM = 555 minutes
  const marketClose = 15 * 60 + 30;  // 3:30 PM = 930 minutes
  const preOpen = 9 * 60;            // 9:00 AM pre-open session

  if (weekday == 6 || weekday == 7) {
    return MarketStatus.closed; // Saturday/Sunday
  } else if (totalMinutes >= marketOpen && totalMinutes < marketClose) {
    return MarketStatus.open;
  } else if (totalMinutes >= preOpen && totalMinutes < marketOpen) {
    return MarketStatus.preOpen;
  } else {
    return MarketStatus.closed;
  }
});
