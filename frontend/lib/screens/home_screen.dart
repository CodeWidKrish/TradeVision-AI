import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../providers/clock_provider.dart';
import '../providers/market_data_provider.dart';
import '../widgets/ist_clock_widget.dart';
import '../core/theme/dark_surfaces.dart';
import '../core/data/stock_data.dart';
import '../core/providers/market_ticker_provider.dart';
import '../widgets/portfolio_flip_card.dart';
import '../widgets/stock_row.dart';
import '../widgets/section_header.dart';
import '../widgets/ai_insight_strip.dart';
import '../widgets/animated_press_card.dart';
import '../widgets/market_news_widget.dart';
import '../widgets/ticker_logo.dart';

final List<Map<String, dynamic>> marketPulseData = [
  {
    'name': 'NIFTY 50',
    'value': '23,242.40',
    'change': '+24.80',
    'percent': '+0.11%',
    'isPositive': true,
  },
  {
    'name': 'SENSEX',
    'value': '74,336.45',
    'change': '+332.63',
    'percent': '+0.45%',
    'isPositive': true,
  },
  {
    'name': 'NIFTY BANK',
    'value': '56,262.40',
    'change': '-30.05',
    'percent': '-0.05%',
    'isPositive': false,
  },
  {
    'name': 'NIFTY IT',
    'value': '28,833.05',
    'change': '-254.60',
    'percent': '-0.88%',
    'isPositive': false,
  },
];

final gainers = [
  {'ticker': 'BAJFINANCE', 'name': 'Bajaj Finance Ltd.', 'price': '₹7,284.50', 'change': '+3.42%', 'isPositive': true},
  {'ticker': 'RELIANCE',   'name': 'Reliance Industries', 'price': '₹2,896.25', 'change': '+1.82%', 'isPositive': true},
  {'ticker': 'HDFCBANK',   'name': 'HDFC Bank Ltd.',      'price': '₹1,723.40', 'change': '+1.54%', 'isPositive': true},
];

final losers = [
  {'ticker': 'TCS',    'name': 'Tata Consultancy Services', 'price': '₹3,538.30', 'change': '-0.93%', 'isPositive': false},
  {'ticker': 'INFY',   'name': 'Infosys Ltd.',              'price': '₹1,775.60', 'change': '-0.67%', 'isPositive': false},
  {'ticker': 'WIPRO',  'name': 'Wipro Ltd.',                'price': '₹558.10',   'change': '-0.74%', 'isPositive': false},
];

class HomeScreen extends StatefulWidget {
  final Function(StockModel) onSelectStock;
  final Function(int)? onSelectTab;
  final VoidCallback? onOpenProfile;

  const HomeScreen({
    super.key,
    required this.onSelectStock,
    this.onSelectTab,
    this.onOpenProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showQuickPortfolioSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkSurface.card : Colors.white;
    final textColor = isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final safeBottom = math.max(MediaQuery.of(context).padding.bottom, 20.0);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, safeBottom + 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Portfolio Asset Allocation',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: DarkSurface.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(
                height: 20,
                color: isDark ? DarkSurface.border : const Color(0xFFE2E6EA),
              ),
              _buildAllocationRow(context, 'RELIANCE', '40% Allocation', '₹1,95,440.00', const Color(0xFF00C853)),
              const SizedBox(height: 10),
              _buildAllocationRow(context, 'TCS', '30% Allocation', '₹1,46,580.00', const Color(0xFF00C853)),
              const SizedBox(height: 10),
              _buildAllocationRow(context, 'HDFCBANK', '20% Allocation', '₹97,720.00', const Color(0xFF0066CC)),
              const SizedBox(height: 10),
              _buildAllocationRow(context, 'INFY', '10% Allocation', '₹48,860.00', const Color(0xFFFF8C00)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllocationRow(BuildContext context, String ticker, String share, String val, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? DarkSurface.textPrimary : const Color(0xFF1A1A2E);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              ticker,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($share)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: DarkSurface.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          val,
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStaticPulseList() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: marketPulseData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = marketPulseData[index];
          return MarketPulseCard(
            indexName: item['name'] as String,
            value: item['value'] as String,
            change: item['change'] as String,
            changePercent: item['percent'] as String,
            isPositive: item['isPositive'] as bool,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tickerNotifier = provider.Provider.of<MarketTickerNotifier>(context);
    final watchlistStocks = tickerNotifier.stocks.take(6).toList();

    return Scaffold(
      backgroundColor: isDark ? DarkSurface.bg : const Color(0xFFF4F6F9),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0066CC),
          backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 1. Top Greeting Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final hour = ref.watch(istClockProvider).hour;
                              final greeting = hour < 12
                                  ? 'Good morning'
                                  : hour < 17
                                      ? 'Good afternoon'
                                      : 'Good evening';
                              return Text(
                                greeting,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: DarkSurface.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          Text(
                            StorageService.getUserDisplayName() ?? 'Investor',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? DarkSurface.textPrimary
                                  : const Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Live IST clock widget
                          const ISTClockWidget(compact: false),
                        ],
                      ),
                    ),
                    AnimatedPressCard(
                      onTap: widget.onOpenProfile,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkSurface.panel
                              : const Color(0xFF0066CC),
                          shape: BoxShape.circle,
                          border: isDark
                              ? Border.all(
                                  color: const Color(0xFF0066CC).withOpacity(0.40),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            (StorageService.getUserDisplayName() ?? 'I')[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF0066CC)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contextual Market Hours Banner
              Consumer(
                builder: (context, ref, _) {
                  final status = ref.watch(marketStatusProvider);
                  final now = ref.watch(istClockProvider);

                  if (status == MarketStatus.open) return const SizedBox.shrink();

                  final isPreOpen = status == MarketStatus.preOpen;
                  final color = isPreOpen
                      ? const Color(0xFFFF8C00)
                      : const Color(0xFFFF3B3B);

                  final message = isPreOpen
                      ? 'Pre-open session active. Market opens at 9:15 AM IST.'
                      : _getNextOpenMessage(now);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 2. AI Insight Banner
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AiInsightStrip(),
              ),

              const SizedBox(height: 12),

              // 3. Portfolio Card (Interactive 3D Flip Card with Ambient Glow Halo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF0066CC).withValues(alpha: 0.32)
                                  : const Color(0xFF0066CC).withValues(alpha: 0.20),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const PortfolioFlipCard(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. SECTION 1 — MARKET PULSE STRIP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Market Pulse',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (widget.onSelectTab != null) {
                          widget.onSelectTab!(1);
                        } else {
                          context.go('/market');
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                      ),
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0066CC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Market Pulse Cards Horizontal Scroll Strip (Live Real-Time Stream)
              Consumer(
                builder: (context, ref, _) {
                  final indicesAsync = ref.watch(indicesProvider);
                  return indicesAsync.when(
                    data: (indices) {
                      final items = indices.isNotEmpty ? indices : null;
                      if (items == null) return _buildStaticPulseList();
                      return SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final sign = item.change >= 0 ? '+' : '';
                            final changeStr = '$sign${item.change.toStringAsFixed(2)}';
                            final pctStr = '$sign${item.changePercent.toStringAsFixed(2)}%';
                            final valueStr = NumberFormat('#,##0.00').format(item.price);
                            return MarketPulseCard(
                              indexName: item.name,
                              value: valueStr,
                              change: changeStr,
                              changePercent: pctStr,
                              isPositive: item.isPositive,
                            );
                          },
                        ),
                      );
                    },
                    loading: () => _buildStaticPulseList(),
                    error: (_, __) => _buildStaticPulseList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 6. SECTION 2 — TODAY'S MOVERS (TOP GAINERS / LOSERS WITH SWIPE)
              const _MoversSection(),

              const SizedBox(height: 20),

              // 7. Live Watchlist Section Header
              SectionHeader(
                title: 'Watchlist',
                actionText: 'See All',
                onActionTap: () => context.push('/watchlist'),
              ),

              // Watchlist Stock Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: watchlistStocks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final stock = watchlistStocks[index];
                  return AnimatedPressCard(
                    onTap: () => context.push('/stock-detail/${stock.ticker}'),
                    child: StockRow(
                      ticker: stock.ticker,
                      fullName: stock.fullName,
                      price: stock.priceFormatted,
                      changePercent: stock.changePercentFormatted,
                      isPositive: stock.isPositive,
                      logoColor: stock.logoColor,
                      logoUrl: stock.logoUrl,
                      onTap: () => context.push('/stock-detail/${stock.ticker}'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 8. Real-World Live News Stream
              const MarketNewsWidget(),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class MarketPulseCard extends StatelessWidget {
  final String indexName;
  final String value;
  final String change;
  final String changePercent;
  final bool isPositive;

  const MarketPulseCard({
    super.key,
    required this.indexName,
    required this.value,
    required this.change,
    required this.changePercent,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isPositive
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B3B);

    return Container(
      width: 144,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111827)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2733)
              : const Color(0xFFE2E6EA),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Index name
            Text(
              indexName,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: const Color(0xFF8892A4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.robotoMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFE8ECF0)
                      : const Color(0xFF1A1A2E),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),

            // Change row with mini trend indicator
            Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: color,
                  size: 16,
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$change ($changePercent)',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            SizedBox(
              height: 20,
              child: BarChart(
                BarChartData(
                  barGroups: _generateMiniBarGroups(isPositive),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateMiniBarGroups(bool isPositive) {
    final color = isPositive
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B3B);
    final heights = isPositive
        ? [6.0, 9.0, 7.0, 11.0, 8.0, 14.0, 12.0]
        : [14.0, 10.0, 12.0, 7.0, 11.0, 6.0, 8.0];
    return List.generate(
      heights.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: heights[i],
            color: color.withOpacity(0.70),
            width: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

class _MoversSection extends StatefulWidget {
  const _MoversSection();

  @override
  State<_MoversSection> createState() => _MoversSectionState();
}

class _MoversSectionState extends State<_MoversSection>
    with SingleTickerProviderStateMixin {
  bool _showGainers = true;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipTo(bool targetGainers) {
    if (_showGainers == targetGainers || _flipController.isAnimating) return;
    HapticFeedback.selectionClick();

    _flipController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showGainers = targetGainers;
          _flipController.reset();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with tab toggle (clean, no swipe text)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Today\'s Movers',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFE8ECF0)
                      : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              // Tab toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111827)
                      : const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E2733)
                        : const Color(0xFFE2E6EA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MoverTab(
                      label: 'Gainers',
                      isSelected: _showGainers,
                      selectedColor: const Color(0xFF00C853),
                      onTap: () => _flipTo(true),
                    ),
                    const SizedBox(width: 2),
                    _MoverTab(
                      label: 'Losers',
                      isSelected: !_showGainers,
                      selectedColor: const Color(0xFFFF3B3B),
                      onTap: () => _flipTo(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Interactive 3D Flip Card for Gainers / Losers
        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -120) {
              // Swipe left -> Losers
              _flipTo(false);
            } else if (details.primaryVelocity! > 120) {
              // Swipe right -> Gainers
              _flipTo(true);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final isUnder = angle > (math.pi / 2);

              final Widget face;
              if (!isUnder) {
                face = _showGainers
                    ? _MoversList(isGainers: true, isDark: isDark)
                    : _MoversList(isGainers: false, isDark: isDark);
              } else {
                face = _showGainers
                    ? _MoversList(isGainers: false, isDark: isDark)
                    : _MoversList(isGainers: true, isDark: isDark);
              }

              final scale = 1.0 + math.sin(angle) * 0.05;
              final shadowOpacity = (math.sin(angle) * 0.24).clamp(0.0, 0.24);

              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0014) // 3D Perspective
                ..scale(scale);

              if (!isUnder) {
                transform.rotateY(angle);
              } else {
                transform.rotateY(angle - math.pi);
              }

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    face,
                    if (shadowOpacity > 0.01)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: shadowOpacity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Page indicator dots (interactive)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _flipTo(true),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _showGainers ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _showGainers
                      ? const Color(0xFF00C853)
                      : const Color(0xFF8892A4).withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _flipTo(false),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: !_showGainers ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: !_showGainers
                      ? const Color(0xFFFF3B3B)
                      : const Color(0xFF8892A4).withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Gainers or Losers list
class _MoversList extends StatelessWidget {
  final bool isGainers;
  final bool isDark;

  const _MoversList({required this.isGainers, required this.isDark});

  static const gainers = [
    {'ticker': 'BAJFINANCE', 'name': 'Bajaj Finance Ltd.',    'price': '₹7,284.50', 'change': '+3.42%'},
    {'ticker': 'RELIANCE',   'name': 'Reliance Industries',   'price': '₹2,896.25', 'change': '+1.82%'},
    {'ticker': 'HDFCBANK',   'name': 'HDFC Bank Ltd.',        'price': '₹1,723.40', 'change': '+1.54%'},
  ];

  static const losers = [
    {'ticker': 'TCS',    'name': 'Tata Consultancy Services', 'price': '₹3,538.30', 'change': '-0.93%'},
    {'ticker': 'INFY',   'name': 'Infosys Ltd.',              'price': '₹1,775.60', 'change': '-0.67%'},
    {'ticker': 'WIPRO',  'name': 'Wipro Ltd.',                'price': '₹558.10',   'change': '-0.74%'},
  ];

  @override
  Widget build(BuildContext context) {
    final stocks = isGainers ? gainers : losers;
    final color = isGainers
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B3B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(stocks.length, (i) {
          final s = stocks[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2733)
                    : const Color(0xFFE2E6EA),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/stock-detail/${s['ticker']}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Rank
                      Text(
                        '${i + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8892A4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stock Logo / Avatar
                      TickerLogo(
                        ticker: s['ticker']!,
                        size: 36,
                        heroTag: 'mover-logo-${s['ticker']}-${isGainers ? "g" : "l"}',
                      ),
                      const SizedBox(width: 10),
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['ticker']!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFE8ECF0)
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              s['name']!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF8892A4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Price + change
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            s['price']!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFE8ECF0)
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s['change']!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MoverTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _MoverTab({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(
                  color: selectedColor.withValues(alpha: 0.40), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? selectedColor
                : const Color(0xFF8892A4),
          ),
        ),
      ),
    );
  }
}

class MoverRow extends StatelessWidget {
  final String ticker;
  final String companyName;
  final String price;
  final String changePercent;
  final bool isPositive;
  final int rank;

  const MoverRow({
    super.key,
    required this.ticker,
    required this.companyName,
    required this.price,
    required this.changePercent,
    required this.isPositive,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isPositive
        ? const Color(0xFF00C853)
        : const Color(0xFFFF3B3B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/stock-detail/$ticker'),
        child: Row(
          children: [
          // Rank number
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8892A4),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Ticker avatar
          TickerLogo(
            ticker: ticker,
            size: 36,
            heroTag: 'mover-logo-$ticker',
          ),
          const SizedBox(width: 10),

          // Name column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticker,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  companyName,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF8892A4),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Price + change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  price,
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  changePercent,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}

String _getNextOpenMessage(DateTime now) {
  final weekday = now.weekday;
  if (weekday == 5 && now.hour >= 15) {
    return 'Market closed. Opens Monday at 9:15 AM IST.';
  } else if (weekday == 6) {
    return 'Market closed on Saturday. Opens Monday at 9:15 AM IST.';
  } else if (weekday == 7) {
    return 'Market closed on Sunday. Opens tomorrow at 9:15 AM IST.';
  } else if (now.hour >= 15) {
    return 'Market closed for today. Opens tomorrow at 9:15 AM IST.';
  } else {
    return 'Market opens at 9:15 AM IST today.';
  }
}
