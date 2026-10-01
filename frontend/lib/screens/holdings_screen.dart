import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;
import '../widgets/empty_state_widget.dart';
import '../widgets/ticker_logo.dart';
import '../core/data/stock_data.dart';
import '../core/data/user_holdings_data.dart';
import '../core/providers/market_ticker_provider.dart';
import '../core/providers/portfolio_provider.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to real-time market ticks
    final _ = provider.Provider.of<MarketTickerNotifier>(context);
    final portfolioProvider = provider.Provider.of<PortfolioProvider>(context, listen: false);

    // Compute unified real-time snapshot identical to Home screen portfolio
    final snapshot = UserHoldingsRepository.computeSnapshot(portfolioProvider: portfolioProvider);

    final totalPortfolioValue = snapshot.totalPortfolioValue;
    final totalInvested = snapshot.totalInvested;
    final totalPnL = snapshot.totalReturns;
    final totalPnLPercent = snapshot.returnsPercent;
    final isProfit = totalPnL >= 0;
    final cashReserve = snapshot.cashReserve;
    final holdings = snapshot.allHoldings;
    final sectorBreakdown = snapshot.sectorBreakdown;

    final roundFormatter = NumberFormat('₹#,##,##0', 'en_IN');
    final preciseFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFFE8ECF0)
                  : const Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Holdings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF1E2733)
                : const Color(0xFFE2E6EA),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0066CC),
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        onRefresh: _onRefresh,
        child: holdings.isEmpty
            ? EmptyStateWidget(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No holdings yet',
                subtitle: 'Stocks you buy will show up here.',
                actionLabel: 'Explore Market',
                onAction: () => context.go('/market'),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Portfolio Summary Card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF0066CC), Color(0xFF0052AA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: isDark ? const Color(0xFF1A2332) : null,
                        borderRadius: BorderRadius.circular(20),
                        border: isDark
                            ? Border.all(
                                color: const Color(0xFF0066CC)
                                    .withValues(alpha: 0.25))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Portfolio Value',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF8892A4)
                                  : Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              roundFormatter.format(totalPortfolioValue),
                              style: GoogleFonts.robotoMono(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFE8ECF0)
                                    : Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isProfit
                                  ? const Color(0xFF00C853).withValues(
                                      alpha: isDark ? 0.15 : 0.20)
                                  : const Color(0xFFFF3B3B)
                                      .withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${isProfit ? '+' : ''}${roundFormatter.format(totalPnL)} (${isProfit ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isProfit
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFF3B3B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            color: isDark
                                ? const Color(0xFF1E2733)
                                : Colors.white.withValues(alpha: 0.20),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _PortfolioStat(
                                label: 'Invested',
                                value: roundFormatter.format(totalInvested),
                                color: isDark
                                    ? const Color(0xFF8892A4)
                                    : Colors.white.withValues(alpha: 0.80),
                              ),
                              _PortfolioStat(
                                label: 'Returns',
                                value:
                                    '${isProfit ? '+' : ''}${roundFormatter.format(totalPnL)}',
                                color: isProfit
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFF3B3B),
                              ),
                              _PortfolioStat(
                                label: 'P&L %',
                                value:
                                    '${isProfit ? '+' : ''}${totalPnLPercent.toStringAsFixed(1)}%',
                                color: isProfit
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFF3B3B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Cash & Available Margin Banner ──────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E2733)
                              : const Color(0xFFE2E6EA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066CC)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFF0066CC),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash & Available Margin',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFE8ECF0)
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  'Liquid balance included in total valuation',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF8892A4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            roundFormatter.format(cashReserve),
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00C853),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Sector Breakdown ────────────────────────────────
                    Text(
                      'Holdings by Sector',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectorBreakdown(
                        sectorTotals: sectorBreakdown, isDark: isDark),

                    const SizedBox(height: 24),

                    // ── Individual Holdings ─────────────────────────────
                    Text(
                      'Your Stocks (${holdings.length})',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...holdings.map((h) {
                      final currentPrice =
                          snapshot.holdingCurrentPrices[h.ticker] ??
                              h.avgBuyPrice;
                      final current = snapshot.holdingCurrentValues[h.ticker] ??
                          (currentPrice * h.quantity);
                      final invested = h.invested;
                      final pnl = current - invested;
                      final pnlPct =
                          invested > 0 ? (pnl / invested) * 100 : 0.0;
                      final isPos = pnl >= 0;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/stock-detail', extra: h.ticker);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111827)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E2733)
                                  : const Color(0xFFE2E6EA),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  TickerLogo(
                                    ticker: h.ticker,
                                    size: 40,
                                    heroTag: 'holding-logo-${h.ticker}',
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h.ticker,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFFE8ECF0)
                                                : const Color(0xFF1A1A2E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${h.quantity} shares • ${h.sector}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8892A4),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          preciseFormatter.format(currentPrice),
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 14,
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
                                          color: (isPos
                                                  ? const Color(0xFF00C853)
                                                  : const Color(0xFFFF3B3B))
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${isPos ? '+' : ''}${pnlPct.toStringAsFixed(2)}%',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isPos
                                                ? const Color(0xFF00C853)
                                                : const Color(0xFFFF3B3B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _HoldingStat(
                                    'Avg. Buy Price',
                                    preciseFormatter.format(h.avgBuyPrice),
                                    isDark,
                                  ),
                                  _HoldingStat(
                                    'Current Value',
                                    roundFormatter.format(current),
                                    isDark,
                                  ),
                                  _HoldingStat(
                                    'Total P&L',
                                    '${isPos ? '+' : ''}${roundFormatter.format(pnl)}',
                                    isDark,
                                    color: isPos
                                        ? const Color(0xFF00C853)
                                        : const Color(0xFFFF3B3B),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF0066CC), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Holdings shown reflect your integrated portfolio holdings & live market marks. TradeVision AI simulates realistic broker execution.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF0066CC),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PortfolioStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  const _HoldingStat(this.label, this.value, this.isDark, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: const Color(0xFF8892A4),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color ??
                    (isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E)),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectorBreakdown extends StatelessWidget {
  final Map<String, double> sectorTotals;
  final bool isDark;

  const _SectorBreakdown({required this.sectorTotals, required this.isDark});

  @override
  Widget build(BuildContext context) {
    double grandTotal = 0;
    for (final val in sectorTotals.values) {
      grandTotal += val;
    }
    final colors = [
      const Color(0xFF0066CC),
      const Color(0xFF00C853),
      const Color(0xFFFF8C00),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF38BDF8),
    ];
    final sectors = sectorTotals.entries.toList();

    return Column(
      children: List.generate(sectors.length, (i) {
        final pct =
            grandTotal > 0 ? (sectors[i].value / grandTotal) * 100 : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sectors[i].key,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8892A4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors[i % colors.length],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: isDark
                      ? const Color(0xFF1E2A3A)
                      : const Color(0xFFE2E6EA),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors[i % colors.length]),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
