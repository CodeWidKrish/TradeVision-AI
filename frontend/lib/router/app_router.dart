import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/main_screen.dart';
import '../widgets/session_guard.dart';
import '../widgets/connectivity_banner.dart';

import '../screens/holdings_screen.dart';
import '../screens/stock_detail_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/market_charts_screen.dart';
import '../screens/ai_insights_screen.dart';
import '../screens/analysis_screen.dart';
import '../core/data/stock_data.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.read(isLoggedInProvider);

  return GoRouter(
    initialLocation: isLoggedIn ? '/home' : '/splash',
    errorBuilder: (context, state) {
      // Log the bad route
      debugPrint('GoRouter error: ${state.error}');
      debugPrint('Bad location: ${state.uri}');

      return Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1E2733)),
                    ),
                    child: const Icon(Icons.map_outlined,
                        color: Color(0xFF8892A4), size: 32),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Page Not Found',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8ECF0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The page you are looking for does not exist. '
                    'Let\'s take you back to the home screen.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF8892A4),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text('Go to Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SplashScreen(),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingScreen(),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.fastOutSlowIn,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                  CurvedAnimation(
                    parent: anim,
                    curve: Curves.fastOutSlowIn,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AuthScreen(),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim,
                curve: Curves.fastOutSlowIn,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 380),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SessionGuard(
            child: MainScreen(),
          ),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.fastOutSlowIn,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                  CurvedAnimation(
                    parent: anim,
                    curve: Curves.fastOutSlowIn,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      ),
      GoRoute(
        path: '/holdings',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HoldingsScreen(),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      GoRoute(
        path: '/watchlist',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const WatchlistScreen(),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      GoRoute(
        path: '/market',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: MarketChartsScreen(
            initialStock: StockRepository.stocks.first,
          ),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      GoRoute(
        path: '/ai-copilot',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AiInsightsScreen(),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: AnalysisScreen(
            currentStock: StockRepository.stocks.first,
          ),
          transitionsBuilder: (_, anim, secondaryAnim, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
        ),
      ),
      GoRoute(
        path: '/stock-detail',
        pageBuilder: (context, state) {
          final symbol = state.extra as String? ?? 'RELIANCE';
          return CustomTransitionPage(
            child: StockDetailScreen(symbol: symbol),
            transitionsBuilder: (_, anim, secondaryAnim, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/stock-detail/:symbol',
        pageBuilder: (context, state) {
          final symbol = state.pathParameters['symbol'] ?? 'RELIANCE';
          return CustomTransitionPage(
            child: StockDetailScreen(symbol: symbol),
            transitionsBuilder: (_, anim, secondaryAnim, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
    ],
  );
});
