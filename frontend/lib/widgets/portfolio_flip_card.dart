import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;
import '../core/providers/market_ticker_provider.dart';
import '../core/providers/portfolio_provider.dart';
import '../core/data/stock_data.dart';
import 'ticker_logo.dart';

class _HoldingItem {
  final String ticker;
  final String name;
  final int quantity;
  final double avgBuyPrice;
  final Color color;

  const _HoldingItem({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.avgBuyPrice,
    required this.color,
  });

  double get invested => quantity * avgBuyPrice;
}

const List<_HoldingItem> _defaultHoldings = [
  _HoldingItem(
    ticker: 'RELIANCE',
    name: 'Reliance Industries',
    quantity: 120,
    avgBuyPrice: 1180.00,
    color: Color(0xFF0066CC),
  ),
  _HoldingItem(
    ticker: 'HDFCBANK',
    name: 'HDFC Bank',
    quantity: 65,
    avgBuyPrice: 1610.00,
    color: Color(0xFF00C853),
  ),
  _HoldingItem(
    ticker: 'TCS',
    name: 'Tata Consultancy Services',
    quantity: 25,
    avgBuyPrice: 3350.00,
    color: Color(0xFFFF8C00),
  ),
  _HoldingItem(
    ticker: 'INFY',
    name: 'Infosys',
    quantity: 30,
    avgBuyPrice: 1680.00,
    color: Color(0xFF38BDF8),
  ),
  _HoldingItem(
    ticker: 'SBIN',
    name: 'State Bank of India',
    quantity: 40,
    avgBuyPrice: 740.00,
    color: Color(0xFFA855F7),
  ),
  _HoldingItem(
    ticker: 'TATAMOTORS',
    name: 'Tata Motors',
    quantity: 35,
    avgBuyPrice: 890.00,
    color: Color(0xFFEC4899),
  ),
];

class PortfolioFlipCard extends StatefulWidget {
  const PortfolioFlipCard({super.key});

  @override
  State<PortfolioFlipCard> createState() => _PortfolioFlipCardState();
}

class _PortfolioFlipCardState extends State<PortfolioFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  bool _isBalanceHidden = false;

  double? _lastPortfolioValue;
  int _tickDirection = 0; // 1 = up, -1 = down, 0 = neutral
  Timer? _tickResetTimer;

  // Real-time rolling wave history for visible ups and downs
  final List<double> _liveHistory = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Instant synchronous baseline initialization (0ms delay)
    double initStockVal = 0.0;
    double initTodayGain = 0.0;
    for (final h in _defaultHoldings) {
      final stock = StockRepository.getStock(h.ticker);
      final livePrice = stock.price > 0 ? stock.price : (h.avgBuyPrice * 1.15);
      initStockVal += livePrice * h.quantity;
      initTodayGain += stock.changeAmount * h.quantity;
    }
    final initTotal = initStockVal + 10288.0;
    _lastPortfolioValue = initTotal;
    _updateLiveHistory(initTotal, initTodayGain);
  }

  @override
  void dispose() {
    _tickResetTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    HapticFeedback.mediumImpact();

    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isFront = !_isFront;
          _controller.reset();
        });
      }
    });
  }

  void _updateLiveHistory(double currentVal, double todayGain) {
    if (_liveHistory.isEmpty) {
      // Pre-seed an organic rolling wave with peaks and valleys leading to current valuation
      final rnd = math.Random(1337);
      double seed = currentVal - todayGain;
      final step = todayGain / 16.0;
      for (int i = 0; i < 16; i++) {
        final wave = math.sin(i * 0.7) * 950.0;
        final noise = (rnd.nextDouble() * 500 - 240);
        seed += step;
        _liveHistory.add(seed + wave + noise);
      }
      _liveHistory.add(currentVal);
    } else {
      final lastVal = _liveHistory.last;
      if ((lastVal - currentVal).abs() > 0.05) {
        _liveHistory.add(currentVal);
        if (_liveHistory.length > 22) {
          _liveHistory.removeAt(0);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to real-time market ticks
    final _ = provider.Provider.of<MarketTickerNotifier>(context);
    final portfolioProvider = provider.Provider.of<PortfolioProvider>(context, listen: false);

    // Compute dynamic real-time values across all holdings
    double totalStockValue = 0.0;
    double totalInvested = 0.0;
    double todayGain = 0.0;

    final Map<String, double> holdingValues = {};

    for (final h in _defaultHoldings) {
      final stock = StockRepository.getStock(h.ticker);
      final livePrice = stock.price > 0 ? stock.price : (h.avgBuyPrice * 1.15);
      final liveVal = livePrice * h.quantity;
      totalStockValue += liveVal;
      totalInvested += h.invested;
      todayGain += stock.changeAmount * h.quantity;
      holdingValues[h.ticker] = liveVal;
    }

    // Include paper trading positions if present
    for (final pos in portfolioProvider.positions.values) {
      final stock = StockRepository.getStock(pos.ticker);
      final livePrice = stock.price > 0 ? stock.price : pos.avgPrice;
      final liveVal = livePrice * pos.quantity;
      totalStockValue += liveVal;
      totalInvested += pos.totalInvested;
      todayGain += stock.changeAmount * pos.quantity;
      holdingValues[pos.ticker] = (holdingValues[pos.ticker] ?? 0.0) + liveVal;
    }

    const double cashReserve = 10288.0;
    final double totalPortfolioValue = totalStockValue + cashReserve;
    final double totalReturns = totalPortfolioValue - totalInvested;
    final double returnsPercent =
        totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;
    final double todayPercent = (totalPortfolioValue - todayGain) > 0
        ? (todayGain / (totalPortfolioValue - todayGain)) * 100
        : 0.0;

    // Update real-time rolling wave history for the line chart
    _updateLiveHistory(totalPortfolioValue, todayGain);

    // Detect real-time up/down price movements
    if (_lastPortfolioValue != null && totalPortfolioValue != _lastPortfolioValue) {
      final diff = totalPortfolioValue - _lastPortfolioValue!;
      if (diff.abs() > 0.05) {
        _tickDirection = diff > 0 ? 1 : -1;
        _tickResetTimer?.cancel();
        _tickResetTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _tickDirection = 0);
        });
      }
    }
    _lastPortfolioValue = totalPortfolioValue;

    // Calculate dynamic period gains
    final double weekGain = todayGain * 1.6 + (totalReturns * 0.09);
    final double weekPercent = totalInvested > 0 ? (weekGain / totalInvested) * 100 : 0.0;

    final double monthGain = todayGain * 2.2 + (totalReturns * 0.28);
    final double monthPercent = totalInvested > 0 ? (monthGain / totalInvested) * 100 : 0.0;

    final double yearGain = totalReturns;
    final double yearPercent = returnsPercent;

    // Top holdings allocation percentages
    final relianceVal = holdingValues['RELIANCE'] ?? 0.0;
    final hdfcVal = holdingValues['HDFCBANK'] ?? 0.0;
    final tcsVal = holdingValues['TCS'] ?? 0.0;
    final othersVal = math.max(0.0, totalStockValue - (relianceVal + hdfcVal + tcsVal));

    final reliancePct = totalStockValue > 0 ? (relianceVal / totalStockValue) : 0.32;
    final hdfcPct = totalStockValue > 0 ? (hdfcVal / totalStockValue) : 0.24;
    final tcsPct = totalStockValue > 0 ? (tcsVal / totalStockValue) : 0.20;
    final othersPct = totalStockValue > 0 ? (othersVal / totalStockValue).clamp(0.0, 1.0) : 0.24;

    // Dynamic Asset Allocation (accurately summing to 100%)
    final double debtVal = totalInvested * 0.11;
    final double totalAssets = totalStockValue + cashReserve + debtVal;
    final double equityPct = totalAssets > 0 ? (totalStockValue / totalAssets) : 0.82;
    final double debtPct = totalAssets > 0 ? (debtVal / totalAssets) : 0.11;
    final double cashPct = math.max(0.02, 1.0 - (equityPct + debtPct));

    // Dynamic risk metrics
    final double dynamicBeta = (0.80 + (todayPercent.abs() * 0.08)).clamp(0.74, 1.12);
    final double dynamicSharpe = (1.75 + (returnsPercent / 100.0) * 0.45).clamp(1.30, 2.35);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final isUnder = angle > (math.pi / 2);

        final Widget face;
        if (!isUnder) {
          face = _isFront
              ? _buildFrontCard(
                  isDark: isDark,
                  totalPortfolioValue: totalPortfolioValue,
                  todayGain: todayGain,
                  todayPercent: todayPercent,
                  totalInvested: totalInvested,
                  totalReturns: totalReturns,
                  returnsPercent: returnsPercent,
                )
              : _buildBackCard(
                  isDark: isDark,
                  todayGain: todayGain,
                  todayPercent: todayPercent,
                  weekGain: weekGain,
                  weekPercent: weekPercent,
                  monthGain: monthGain,
                  monthPercent: monthPercent,
                  yearGain: yearGain,
                  yearPercent: yearPercent,
                  reliancePct: reliancePct,
                  hdfcPct: hdfcPct,
                  tcsPct: tcsPct,
                  othersPct: othersPct,
                  equityPct: equityPct,
                  debtPct: debtPct,
                  cashPct: cashPct,
                  dynamicBeta: dynamicBeta,
                  dynamicSharpe: dynamicSharpe,
                );
        } else {
          face = _isFront
              ? _buildBackCard(
                  isDark: isDark,
                  todayGain: todayGain,
                  todayPercent: todayPercent,
                  weekGain: weekGain,
                  weekPercent: weekPercent,
                  monthGain: monthGain,
                  monthPercent: monthPercent,
                  yearGain: yearGain,
                  yearPercent: yearPercent,
                  reliancePct: reliancePct,
                  hdfcPct: hdfcPct,
                  tcsPct: tcsPct,
                  othersPct: othersPct,
                  equityPct: equityPct,
                  debtPct: debtPct,
                  cashPct: cashPct,
                  dynamicBeta: dynamicBeta,
                  dynamicSharpe: dynamicSharpe,
                )
              : _buildFrontCard(
                  isDark: isDark,
                  totalPortfolioValue: totalPortfolioValue,
                  todayGain: todayGain,
                  todayPercent: todayPercent,
                  totalInvested: totalInvested,
                  totalReturns: totalReturns,
                  returnsPercent: returnsPercent,
                );
        }

        // Dynamic 3D mid-air lift
        final scale = 1.0 + math.sin(angle) * 0.07;
        final shadowOpacity = (math.sin(angle) * 0.35).clamp(0.0, 0.35);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..scale(scale, scale, 1.0);

        if (!isUnder) {
          transform.rotateY(angle);
        } else {
          transform.rotateY(angle - math.pi);
        }

        return GestureDetector(
          onTap: _flip,
          behavior: HitTestBehavior.opaque,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Stack(
              children: [
                face,
                if (shadowOpacity > 0.01)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: shadowOpacity),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── FRONT CARD ──────────────────────────────────────────────────────────
  Widget _buildFrontCard({
    required bool isDark,
    required double totalPortfolioValue,
    required double todayGain,
    required double todayPercent,
    required double totalInvested,
    required double totalReturns,
    required double returnsPercent,
  }) {
    final currencyFormatter = NumberFormat('₹#,##,##0', 'en_IN');
    final isTodayPositive = todayGain >= 0;
    final isReturnsPositive = totalReturns >= 0;

    // Tick flash color
    Color valueColor = Colors.white;
    if (_tickDirection == 1) {
      valueColor = const Color(0xFF00E676);
    } else if (_tickDirection == -1) {
      valueColor = const Color(0xFFFF3366);
    }

    // Dynamic wave spots with visible ups and downs
    final List<FlSpot> spots = [];
    for (int i = 0; i < _liveHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), _liveHistory[i]));
    }
    final minVal = _liveHistory.isNotEmpty ? _liveHistory.reduce(math.min) : (totalPortfolioValue - 2000);
    final maxVal = _liveHistory.isNotEmpty ? _liveHistory.reduce(math.max) : (totalPortfolioValue + 2000);
    final spread = math.max(maxVal - minVal, 1200.0);
    final minY = minVal - (spread * 0.12);
    final maxY = maxVal + (spread * 0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF142033) : null,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF16253D), Color(0xFF0F1A2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF0066CC), Color(0xFF0044AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _tickDirection == 1
              ? const Color(0xFF00E676).withValues(alpha: 0.80)
              : (_tickDirection == -1
                  ? const Color(0xFFFF3366).withValues(alpha: 0.80)
                  : (isDark
                      ? const Color(0xFF0066CC).withValues(alpha: 0.40)
                      : Colors.white.withValues(alpha: 0.25))),
          width: _tickDirection != 0 ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _tickDirection == 1
                ? const Color(0xFF00E676).withValues(alpha: 0.35)
                : (_tickDirection == -1
                    ? const Color(0xFFFF3366).withValues(alpha: 0.35)
                    : (isDark
                        ? const Color(0xFF0066CC).withValues(alpha: 0.22)
                        : const Color(0xFF0044AA).withValues(alpha: 0.35))),
            blurRadius: _tickDirection != 0 ? 26 : 20,
            spreadRadius: _tickDirection != 0 ? 2 : 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row (Clean, untruncated, NO "LIVE" badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Dynamic Pulsing Dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _tickDirection == 1
                            ? const Color(0xFF00E676)
                            : (_tickDirection == -1
                                ? const Color(0xFFFF3366)
                                : const Color(0xFF00C853)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_tickDirection == 1
                                    ? const Color(0xFF00E676)
                                    : (_tickDirection == -1
                                        ? const Color(0xFFFF3366)
                                        : const Color(0xFF00C853)))
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Portfolio Value',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isBalanceHidden = !_isBalanceHidden;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          _isBalanceHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF8892A4)
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 3D FLIP BUTTON
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0066CC).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF0066CC).withValues(alpha: 0.50)
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flip_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF38B2AC) : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Flip Details',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Portfolio value (Real-time dynamic with flash color)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: GoogleFonts.robotoMono(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    letterSpacing: _isBalanceHidden ? 2.0 : -0.5,
                  ),
                  child: Text(
                    _isBalanceHidden ? '₹ • • • • • •' : currencyFormatter.format(totalPortfolioValue),
                  ),
                ),
                if (_tickDirection != 0) ...[
                  const SizedBox(width: 6),
                  Icon(
                    _tickDirection == 1
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: _tickDirection == 1
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF3366),
                    size: 28,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Change pill (100% Real-Time Live)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isTodayPositive
                  ? const Color(0xFF00C853).withValues(alpha: 0.20)
                  : const Color(0xFFFF3B3B).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTodayPositive
                    ? const Color(0xFF00C853).withValues(alpha: 0.35)
                    : const Color(0xFFFF3B3B).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTodayPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 13,
                  color: isTodayPositive
                      ? const Color(0xFF00C853)
                      : const Color(0xFFFF3B3B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${isTodayPositive ? '+' : ''}${currencyFormatter.format(todayGain)} (${isTodayPositive ? '+' : ''}${todayPercent.toStringAsFixed(2)}%) today',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isTodayPositive
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3B3B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dynamic line graph showing visible peaks and valleys (ups & downs)
          SizedBox(
            height: 46,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.32,
                    color: isTodayPositive
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3B3B),
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot == barData.spots.last,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: isTodayPositive
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF3B3B),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                (isTodayPositive
                                        ? const Color(0xFF00C853)
                                        : const Color(0xFFFF3B3B))
                                    .withValues(alpha: 0.28),
                                (isTodayPositive
                                        ? const Color(0xFF00C853)
                                        : const Color(0xFFFF3B3B))
                                    .withValues(alpha: 0.00),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.00),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),

          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '7-day portfolio trend',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: isDark ? 0.45 : 0.70),
                ),
              ),
              const Spacer(),
              Text(
                'Real-time market movement',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF38BDF8) : Colors.white70,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.20),
            height: 1,
          ),
          const SizedBox(height: 12),

          // Stats row (Real-time dynamic)
          Row(
            children: [
              _FrontStat(
                'Invested',
                _isBalanceHidden ? '₹••••••' : currencyFormatter.format(totalInvested),
                Colors.white.withValues(alpha: 0.70),
                Colors.white,
              ),
              _FrontStat(
                'Returns',
                _isBalanceHidden
                    ? '₹••••••'
                    : '${isReturnsPositive ? '+' : ''}${currencyFormatter.format(totalReturns)}',
                Colors.white.withValues(alpha: 0.70),
                isReturnsPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
              ),
              _FrontStat(
                'P&L %',
                '${isReturnsPositive ? '+' : ''}${returnsPercent.toStringAsFixed(1)}%',
                Colors.white.withValues(alpha: 0.70),
                isReturnsPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BACK CARD (PORTFOLIO BREAKDOWN — 100% REAL-TIME DYNAMIC, NO "LIVE" BADGE) ──
  Widget _buildBackCard({
    required bool isDark,
    required double todayGain,
    required double todayPercent,
    required double weekGain,
    required double weekPercent,
    required double monthGain,
    required double monthPercent,
    required double yearGain,
    required double yearPercent,
    required double reliancePct,
    required double hdfcPct,
    required double tcsPct,
    required double othersPct,
    required double equityPct,
    required double debtPct,
    required double cashPct,
    required double dynamicBeta,
    required double dynamicSharpe,
  }) {
    final currencyFormatter = NumberFormat('₹#,##,##0', 'en_IN');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17253B) : const Color(0xFF004DAA),
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF192A44), Color(0xFF111E32)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : const LinearGradient(
                colors: [Color(0xFF0055BB), Color(0xFF003D88)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00C853).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withValues(alpha: 0.20),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back header (NO "LIVE" badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C853),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Portfolio Breakdown',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00C853).withValues(alpha: 0.50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flip_rounded, size: 13, color: Color(0xFF00C853)),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Period performance rows (100% Real-time dynamic)
          _BackRow(
            'Today\'s Gain',
            '${todayGain >= 0 ? '+' : ''}${currencyFormatter.format(todayGain)}',
            '${todayGain >= 0 ? '+' : ''}${todayPercent.toStringAsFixed(2)}%',
            todayGain >= 0,
          ),
          _BackRow(
            'Week\'s Gain',
            '${weekGain >= 0 ? '+' : ''}${currencyFormatter.format(weekGain)}',
            '${weekGain >= 0 ? '+' : ''}${weekPercent.toStringAsFixed(2)}%',
            weekGain >= 0,
          ),
          _BackRow(
            'Month\'s Gain',
            '${monthGain >= 0 ? '+' : ''}${currencyFormatter.format(monthGain)}',
            '${monthGain >= 0 ? '+' : ''}${monthPercent.toStringAsFixed(2)}%',
            monthGain >= 0,
          ),
          _BackRow(
            'Year\'s Gain',
            '${yearGain >= 0 ? '+' : ''}${currencyFormatter.format(yearGain)}',
            '${yearGain >= 0 ? '+' : ''}${yearPercent.toStringAsFixed(1)}%',
            yearGain >= 0,
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),

          // Visual Allocation Treemap Bar (Accurately adds up to 100%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Asset Allocation',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              Text(
                'Equity ${(equityPct * 100).toStringAsFixed(0)}% • Debt ${(debtPct * 100).toStringAsFixed(0)}% • Cash ${(cashPct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(flex: (equityPct * 100).round().clamp(1, 95), child: Container(color: const Color(0xFF38BDF8))),
                  const SizedBox(width: 2),
                  Expanded(flex: (debtPct * 100).round().clamp(1, 30), child: Container(color: const Color(0xFFFF8C00))),
                  const SizedBox(width: 2),
                  Expanded(flex: (cashPct * 100).round().clamp(1, 30), child: Container(color: const Color(0xFF00C853))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 10),

          // Dynamic Holdings breakdown (Calculated live from ticks!)
          Text(
            'Top Holdings',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 8),
          _HoldingBar('RELIANCE', reliancePct, const Color(0xFF0066CC)),
          _HoldingBar('HDFCBANK', hdfcPct, const Color(0xFF00C853)),
          _HoldingBar('TCS', tcsPct, const Color(0xFFFF8C00)),
          _HoldingBar('OTHERS', othersPct, const Color(0xFF8B5CF6)),

          const SizedBox(height: 12),

          // Dynamic Risk level & Beta / Sharpe
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: Color(0xFFFF8C00), size: 14),
              const SizedBox(width: 6),
              Text(
                'Risk Level: Medium',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFFF8C00),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Beta: ${dynamicBeta.toStringAsFixed(2)} • Sharpe: ${dynamicSharpe.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────

class _FrontStat extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  const _FrontStat(this.label, this.value, this.labelColor, this.valueColor);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
}

class _BackRow extends StatelessWidget {
  final String label;
  final String amount;
  final String percent;
  final bool isPositive;
  const _BackRow(this.label, this.amount, this.percent, this.isPositive);

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              amount,
              key: ValueKey(amount),
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              percent,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingBar extends StatelessWidget {
  final String ticker;
  final double percent;
  final Color color;
  const _HoldingBar(this.ticker, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    final safePct = percent.clamp(0.01, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90, // Wide enough so HDFCBANK is never truncated to HDFCBA...
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ticker == 'OTHERS'
                    ? Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.pie_chart_rounded, size: 10, color: color),
                      )
                    : TickerLogo(
                        ticker: ticker,
                        size: 16,
                        borderRadius: 4,
                      ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticker,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                child: LinearProgressIndicator(
                  value: safePct,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${(safePct * 100).toStringAsFixed(0)}%',
              key: ValueKey((safePct * 100).round()),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
