import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/dark_surfaces.dart';
import '../core/theme/app_dimensions.dart';
import '../core/data/stock_data.dart';
import '../core/providers/market_ticker_provider.dart';
import '../widgets/stock_row.dart';
import '../widgets/market_depth_widget.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'market_charts_screen.dart';
import 'analysis_screen.dart';
import 'ai_insights_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  StockModel _selectedStock = StockRepository.stocks.first;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSelectStock(StockModel stock) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStock = stock;
      _currentIndex = 1; // Navigate to Market tab
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openProfileScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final tickerNotifier = Provider.of<MarketTickerNotifier>(context);
    final liveStocks = tickerNotifier.stocks;

    final screens = [
      HomeScreen(
        onSelectStock: _onSelectStock,
        onSelectTab: _onTabTapped,
        onOpenProfile: _openProfileScreen,
      ),
      MarketChartsScreen(
        initialStock: _selectedStock,
        onOpenProfile: _openProfileScreen,
      ),
      AnalysisScreen(
        currentStock: _selectedStock,
        onSelectStock: (stock) => setState(() => _selectedStock = stock),
      ),
      AiInsightsScreen(
        onSelectStock: _onSelectStock,
      ),
    ];

    final navBg = isDark ? const Color(0xFF111827) : Colors.white;
    final navBorder = isDark ? const Color(0xFF2A3A50) : const Color(0xFFE2E6EA);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: isDark
          ? const Color(0xFF0A0E1A)
          : const Color(0xFFF4F6F9),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            // Real-World Responsive Desktop Multi-Pane View
            return Row(
              children: [
                // Left Navigation Sidebar & Live Watchlist (310px)
                Container(
                  width: 310,
                  decoration: BoxDecoration(
                    color: navBg,
                    border: Border(right: BorderSide(color: navBorder, width: 1)),
                  ),
                  child: Column(
                    children: [
                      // Desktop Branding Header
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.show_chart, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TRADEVISION AI',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Pro Trading Terminal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: DarkSurface.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: navBorder),

                      // Desktop Sidebar Nav Items
                      ListTile(
                        leading: Icon(Icons.home, color: _currentIndex == 0 ? theme.colorScheme.primary : DarkSurface.textMuted),
                        title: Text('Overview', style: TextStyle(fontWeight: _currentIndex == 0 ? FontWeight.w900 : FontWeight.w600, color: _currentIndex == 0 ? theme.colorScheme.primary : (isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E)))),
                        selected: _currentIndex == 0,
                        onTap: () => _onTabTapped(0),
                      ),
                      ListTile(
                        leading: Icon(Icons.candlestick_chart, color: _currentIndex == 1 ? theme.colorScheme.primary : DarkSurface.textMuted),
                        title: Text('Market & Charts', style: TextStyle(fontWeight: _currentIndex == 1 ? FontWeight.w900 : FontWeight.w600, color: _currentIndex == 1 ? theme.colorScheme.primary : (isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E)))),
                        selected: _currentIndex == 1,
                        onTap: () => _onTabTapped(1),
                      ),
                      ListTile(
                        leading: Icon(Icons.analytics, color: _currentIndex == 2 ? theme.colorScheme.primary : DarkSurface.textMuted),
                        title: Text('AI Analytics', style: TextStyle(fontWeight: _currentIndex == 2 ? FontWeight.w900 : FontWeight.w600, color: _currentIndex == 2 ? theme.colorScheme.primary : (isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E)))),
                        selected: _currentIndex == 2,
                        onTap: () => _onTabTapped(2),
                      ),
                      ListTile(
                        leading: Icon(Icons.auto_awesome, color: _currentIndex == 3 ? theme.colorScheme.primary : DarkSurface.textMuted),
                        title: Text('AI Copilot', style: TextStyle(fontWeight: _currentIndex == 3 ? FontWeight.w900 : FontWeight.w600, color: _currentIndex == 3 ? theme.colorScheme.primary : (isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E)))),
                        selected: _currentIndex == 3,
                        onTap: () => _onTabTapped(3),
                      ),

                      Divider(height: 1, color: navBorder),

                      // Watchlist Ticker Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('WATCHLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: DarkSurface.textMuted)),
                            const SizedBox.shrink(),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: liveStocks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final stock = liveStocks[index];
                            return StockRow(
                              ticker: stock.ticker,
                              fullName: stock.fullName,
                              price: stock.priceFormatted,
                              changePercent: stock.changePercentFormatted,
                              isPositive: stock.isPositive,
                              logoColor: stock.logoColor,
                              logoUrl: stock.logoUrl,
                              onTap: () => _onSelectStock(stock),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Main Active Screen View (Flex 2)
                Expanded(
                  flex: 2,
                  child: IndexedStack(
                    index: _currentIndex,
                    children: screens,
                  ),
                ),

                // Right Panel: Level 2 Market Depth & Stock Quick Info (340px)
                Container(
                  width: 340,
                  decoration: BoxDecoration(
                    color: navBg,
                    border: Border(left: BorderSide(color: navBorder, width: 1)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Terminal Depth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E))),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: _openProfileScreen,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MarketDepthWidget(currentPrice: _selectedStock.price),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: screens,
          );
        },
      ),
    ),
    bottomNavigationBar: MediaQuery.of(context).size.width > 900
        ? null
        : AppBottomNav(
            currentIndex: _currentIndex,
            onTabSelected: _onTabTapped,
          ),
    );
  }
}
