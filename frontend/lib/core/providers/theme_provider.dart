import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier([ThemeMode initialMode = ThemeMode.dark]) : super(initialMode);

  void setInitial(ThemeMode mode) {
    state = mode;
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await StorageService.setThemeMode('dark');
    } else {
      state = ThemeMode.light;
      await StorageService.setThemeMode('light');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    if (mode == ThemeMode.dark) {
      await StorageService.setThemeMode('dark');
    } else if (mode == ThemeMode.light) {
      await StorageService.setThemeMode('light');
    }
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
