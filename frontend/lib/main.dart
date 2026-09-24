import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import 'core/theme/app_theme.dart';
import 'core/providers/portfolio_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/market_ticker_provider.dart';
import 'core/providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'services/alert_service.dart';
import 'services/notification_service.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/in_app_notification_banner.dart';

import 'core/error_handler.dart';
import 'core/data/stock_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handler FIRST — before everything
  AppErrorHandler.initialize();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    // Status bar
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // white icons

    // System nav bar — make it transparent so app bg shows through
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Also set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Wrap entire startup in try-catch
  try {
    await StorageService.init();
    await AlertService.instance.init();
    await NotificationService.instance.init();
    await StockRepository.loadStockUniverse();
  } catch (e) {
    debugPrint('StorageService / StockRepository init failed: $e');
    // Continue anyway — app can run without persisted prefs
  }

  final isLoggedIn = StorageService.getIsLoggedIn();
  final savedTheme = StorageService.getThemeMode();
  final initialTheme = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

  runApp(
    ProviderScope(
      overrides: [
        isLoggedInProvider.overrideWith((ref) => isLoggedIn),
        themeProvider.overrideWith((ref) => ThemeNotifier(initialTheme)),
      ],
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => PortfolioProvider()),
          provider.ChangeNotifierProvider(create: (_) => MarketTickerNotifier()),
        ],
        child: const TradeVisionApp(),
      ),
    ),
  );
}

class TradeVisionApp extends ConsumerWidget {
  const TradeVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TradeVision',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      scrollBehavior: const _SmoothScrollBehavior(),
      builder: (context, child) {
        return ConnectivityWrapper(
          child: InAppNotificationBanner(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Removes the blue overscroll glow on Android and provides
/// buttery-smooth scrolling physics across all platforms.
class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No glow / no overscroll indicator — clean feel
    return child;
  }
}
