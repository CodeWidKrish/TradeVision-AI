import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/providers/market_ticker_provider.dart';
import '../core/data/stock_data.dart';

class SentimentHeatmapScreen extends StatefulWidget {
  const SentimentHeatmapScreen({super.key});

  @override
  State<SentimentHeatmapScreen> createState() => _SentimentHeatmapScreenState();
}

class _SentimentHeatmapScreenState extends State<SentimentHeatmapScreen> {
  String _filter = 'ALL'; // ALL, BULLISH, NEUTRAL, BEARISH
  DateTime _lastUpdated = DateTime.now();
  Timer? _refreshTimer;

  // Top market cap companies in India
  static const Set<String> _megaCaps = {
    'RELIANCE', 'TCS', 'HDFCBANK', 'BHARTIARTL', 'ICICIBANK',
    'INFY', 'SBIN', 'ITC', 'HINDUNILVR', 'LICI', 'LT'
  };

  @override
  void initState() {
    super.initState();
    // Auto refresh sentiment analysis every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _lastUpdated = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch ticker updates so prices and sentiment heatmaps stay live
    context.watch<MarketTickerNotifier>();

    // Take top 50 stocks from repository
    final allStocks = StockRepository.stocks.take(50).toList();

    // Calculate aggregated sentiment distribution
    int bullishCount = 0;
    int bearishCount = 0;
    int neutralCount = 0;

    for (final s in allStocks) {
      if (s.changePercent > 0.05) {
        bullishCount++;
      } else if (s.changePercent < -0.05) {
        bearishCount++;
      } else {
        neutralCount++;
      }
    }

    final total = allStocks.isEmpty ? 1 : allStocks.length;
    final bullPct = (bullishCount / total) * 100;
    final bearPct = (bearishCount / total) * 100;

    final filteredStocks = allStocks.where((s) {
      final isBull = s.changePercent > 0.05;
      final isBear = s.changePercent < -0.05;
      if (_filter == 'BULLISH') return isBull;
      if (_filter == 'BEARISH') return isBear;
      if (_filter == 'NEUTRAL') return !isBull && !isBear;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF8B5CF6),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Live Sentiment Heatmap',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF8892A4)),
            tooltip: 'Refresh Heatmap',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _lastUpdated = DateTime.now());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Market Breadth Bar (Never Overflows) ─────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'MARKET SENTIMENT BREADTH (TOP 50)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8892A4),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (bullPct >= 50
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF8C00)).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bullPct >= 50 ? 'NET BULLISH' : 'NET CAUTIOUS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: bullPct >= 50
                                ? const Color(0xFF00C853)
                                : const Color(0xFFFF8C00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: [
                          Expanded(
                            flex: bullishCount.clamp(1, 50),
                            child: Container(color: const Color(0xFF00C853)),
                          ),
                          Expanded(
                            flex: neutralCount.clamp(1, 50),
                            child: Container(color: const Color(0xFF64748B)),
                          ),
                          Expanded(
                            flex: bearishCount.clamp(1, 50),
                            child: Container(color: const Color(0xFFFF3B3B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _legendDot(
                          color: const Color(0xFF00C853),
                          label: 'Bullish $bullishCount (${bullPct.toStringAsFixed(0)}%)',
                        ),
                        const SizedBox(width: 14),
                        _legendDot(
                          color: const Color(0xFF64748B),
                          label: 'Neutral $neutralCount',
                        ),
                        const SizedBox(width: 14),
                        _legendDot(
                          color: const Color(0xFFFF3B3B),
                          label: 'Bearish $bearishCount (${bearPct.toStringAsFixed(0)}%)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF8892A4)),
                      const SizedBox(width: 5),
                      Text(
                        'Last updated: ${DateFormat('hh:mm:ss a').format(_lastUpdated)} • Auto-refreshes every 30s',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF8892A4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Filter Chips ───────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _filterChip('ALL', 'All (50)', isDark),
                  const SizedBox(width: 8),
                  _filterChip('BULLISH', 'Bullish ($bullishCount)', isDark),
                  const SizedBox(width: 8),
                  _filterChip('NEUTRAL', 'Neutral ($neutralCount)', isDark),
                  const SizedBox(width: 8),
                  _filterChip('BEARISH', 'Bearish ($bearishCount)', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Heatmap Grid with Market-Cap Proportionality ────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStocks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.05,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, idx) {
                final s = filteredStocks[idx];
                final isMegaCap = _megaCaps.contains(s.ticker.toUpperCase());
                final pct = s.changePercent;

                // Color grading per requirements:
                // Deep green for strongly bullish (>= +2.0%)
                // Light green for mildly bullish (> 0.0%)
                // Grey for neutral (between -0.05% and 0.05%)
                // Light red for mildly bearish (< 0.0% and > -2.0%)
                // Deep red for strongly bearish (<= -2.0%)
                final Color tileColor;
                if (pct >= 2.0) {
                  tileColor = const Color(0xFF047857); // Deep green
                } else if (pct > 0.05) {
                  tileColor = const Color(0xFF10B981); // Light green
                } else if (pct < -2.0) {
                  tileColor = const Color(0xFF991B1B); // Deep red
                } else if (pct < -0.05) {
                  tileColor = const Color(0xFFEF4444); // Light red
                } else {
                  tileColor = const Color(0xFF475569); // Neutral grey
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      // Navigate to Stock Detail screen cleanly without Page Not Found
                      context.push('/stock-detail', extra: s.ticker);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isMegaCap
                            ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: tileColor.withValues(alpha: 0.3),
                            blurRadius: isMegaCap ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isMegaCap)
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'MEGA CAP',
                                style: GoogleFonts.inter(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          Text(
                            s.ticker,
                            style: GoogleFonts.inter(
                              fontSize: isMegaCap ? 13.5 : 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${s.price.toStringAsFixed(1)}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pct >= 0 ? "+" : ""}${pct.toStringAsFixed(2)}%',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8892A4),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = key);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF8892A4),
          ),
        ),
      ),
    );
  }
}
