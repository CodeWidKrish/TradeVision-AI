import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/ticker_logo.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  final List<Map<String, dynamic>> _holdings = [
    {
      'ticker': 'RELIANCE',
      'name': 'Reliance Industries',
      'qty': 10,
      'avgBuy': 2650.00,
      'current': 2886.76,
      'sector': 'Energy'
    },
    {
      'ticker': 'TCS',
      'name': 'Tata Consultancy Services',
      'qty': 5,
      'avgBuy': 3200.00,
      'current': 3543.42,
      'sector': 'IT'
    },
    {
      'ticker': 'HDFCBANK',
      'name': 'HDFC Bank',
      'qty': 20,
      'avgBuy': 1580.00,
      'current': 1723.22,
      'sector': 'Banking'
    },
    {
      'ticker': 'INFY',
      'name': 'Infosys',
      'qty': 15,
      'avgBuy': 1820.00,
      'current': 1775.76,
      'sector': 'IT'
    },
    {
      'ticker': 'WIPRO',
      'name': 'Wipro',
      'qty': 30,
      'avgBuy': 490.00,
      'current': 558.10,
      'sector': 'IT'
    },
    {
      'ticker': 'SBIN',
      'name': 'State Bank of India',
      'qty': 25,
      'avgBuy': 750.00,
      'current': 812.43,
      'sector': 'Banking'
    },
  ];

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate totals safely
    double totalInvested = 0;
    double totalCurrent = 0;
    for (final h in _holdings) {
      totalInvested += (h['avgBuy'] as double) * (h['qty'] as int);
      totalCurrent += (h['current'] as double) * (h['qty'] as int);
    }
    final totalPnL = totalCurrent - totalInvested;
    final totalPnLPercent =
        totalInvested > 0 ? (totalPnL / totalInvested) * 100 : 0.0;
    final isProfit = totalPnL >= 0;

    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
    final roundFormatter = NumberFormat('₹#,##,##0', 'en_IN');

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
        child: _holdings.isEmpty
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
                          Text(
                            currencyFormatter.format(totalCurrent),
                            style: GoogleFonts.robotoMono(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFE8ECF0)
                                  : Colors.white,
                              letterSpacing: -0.5,
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
                              '${isProfit ? '+' : ''}${currencyFormatter.format(totalPnL)} (${isProfit ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%)',
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
                    _SectorBreakdown(holdings: _holdings, isDark: isDark),

                    const SizedBox(height: 24),

                    // ── Individual Holdings ─────────────────────────────
                    Text(
                      'Your Stocks (${_holdings.length})',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._holdings.map((h) {
                      final invested =
                          (h['avgBuy'] as double) * (h['qty'] as int);
                      final current =
                          (h['current'] as double) * (h['qty'] as int);
                      final pnl = current - invested;
                      final pnlPct =
                          invested > 0 ? (pnl / invested) * 100 : 0.0;
                      final isPos = pnl >= 0;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/stock-detail/${h['ticker']}');
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
                                    ticker: h['ticker'].toString(),
                                    size: 40,
                                    heroTag: 'holding-logo-${h['ticker']}',
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h['ticker'],
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
                                          '${h['qty']} shares • ${h['sector']}',
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
                                          currencyFormatter.format(h['current']),
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
                                    currencyFormatter.format(h['avgBuy']),
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
                              'Holdings shown are for learning purposes. TradeVision AI does not connect to your broker account.',
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
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
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
  final List<Map<String, dynamic>> holdings;
  final bool isDark;

  const _SectorBreakdown({required this.holdings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sectorTotals = <String, double>{};
    double grandTotal = 0;
    for (final h in holdings) {
      final val = (h['current'] as double) * (h['qty'] as int);
      sectorTotals[h['sector']] = (sectorTotals[h['sector']] ?? 0) + val;
      grandTotal += val;
    }
    final colors = [
      const Color(0xFF0066CC),
      const Color(0xFF00C853),
      const Color(0xFFFF8C00),
      const Color(0xFF8B5CF6),
      const Color(0xFFFF3B3B),
    ];
    final sectors = sectorTotals.entries.toList();

    return Column(
      children: List.generate(sectors.length, (i) {
        final pct = grandTotal > 0 ? (sectors[i].value / grandTotal) * 100 : 0.0;
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
