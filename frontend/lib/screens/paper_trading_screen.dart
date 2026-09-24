import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/providers/portfolio_provider.dart';
import '../core/providers/market_ticker_provider.dart';
import '../core/data/stock_data.dart';
import '../widgets/ticker_logo.dart';

class PaperTradingScreen extends StatefulWidget {
  const PaperTradingScreen({super.key});

  @override
  State<PaperTradingScreen> createState() => _PaperTradingScreenState();
}

class _PaperTradingScreenState extends State<PaperTradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmReset(BuildContext context, PortfolioProvider portfolio) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8C00), size: 24),
            const SizedBox(width: 8),
            Text(
              'Reset Portfolio?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'This will wipe all active positions, pending limit orders, and trade ledger history. Your virtual cash balance will be reset to ₹1,00,000.\n\nAre you sure you want to proceed?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF8892A4),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8892A4),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              portfolio.resetPortfolio();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Portfolio reset to ₹1,00,000 cash'),
                  backgroundColor: Color(0xFF00C853),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Watch ticker stream for live floating P&L ticks
    context.watch<MarketTickerNotifier>();

    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, _) {
        final totalValue = portfolio.totalPortfolioValue;
        final invested = portfolio.totalInvested;
        final cash = portfolio.virtualCash;
        final floatingPnL = portfolio.getPnL();
        final floatingPnLPct = portfolio.getPnLPercent();
        final isProfit = floatingPnL >= 0;
        final winRate = portfolio.winRate;

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
                    color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.candlestick_chart_rounded,
                    color: Color(0xFF00C853),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Paper Trading Pro',
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
                icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF8892A4)),
                tooltip: 'Reset Portfolio',
                onPressed: () => _confirmReset(context, portfolio),
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
          body: Column(
            children: [
              // ── Top Balance Card with Equity Curve ─────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B).withValues(alpha: 0.45), const Color(0xFF0F172A)]
                        : [const Color(0xFF059669), const Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL PORTFOLIO VALUE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SIMULATED ₹1L',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormatter.format(totalValue),
                      style: GoogleFonts.robotoMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isProfit ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                          size: 20,
                        ),
                        Text(
                          '${isProfit ? "+" : ""}${currencyFormatter.format(floatingPnL)} (${isProfit ? "+" : ""}${floatingPnLPct.toStringAsFixed(2)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Unrealized P&L',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Mini Equity Curve Sparkline
                    SizedBox(
                      height: 48,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: portfolio.getEquitySpots(),
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                              barWidth: 2.2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (isProfit ? const Color(0xFF4ADE80) : const Color(0xFFF87171))
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                    const SizedBox(height: 10),

                    // Summary Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Available Cash', currencyFormatter.format(cash)),
                        _buildStat('Invested', currencyFormatter.format(invested)),
                        _buildStat('Win Rate', '${winRate.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tab Bar ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0066CC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF8892A4),
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Positions (${portfolio.positions.length})'),
                    Tab(text: 'Limit Orders (${portfolio.activeLimitOrders.length})'),
                    Tab(text: 'Ledger (${portfolio.tradeHistory.length})'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Tab Content ──────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Tab 1: Positions ──────────────────────────
                    portfolio.positions.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            title: 'No Active Positions',
                            subtitle: 'Explore 2000+ stocks and execute zero-risk paper trades.',
                            buttonText: 'Explore Stocks',
                            onTap: () => context.push('/market'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: portfolio.positions.length,
                            itemBuilder: (context, idx) {
                              final entry = portfolio.positions.entries.elementAt(idx);
                              final pos = entry.value;
                              final stock = StockRepository.getStock(pos.ticker);
                              final currentPrice = stock.price;
                              final currentValue = currentPrice * pos.quantity;
                              final positionPnL = currentValue - pos.totalInvested;
                              final positionPnLPct = pos.totalInvested > 0
                                  ? (positionPnL / pos.totalInvested) * 100
                                  : 0.0;
                              final posProfit = positionPnL >= 0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF111827) : Colors.white,
                                child: InkWell(
                                  onTap: () => context.push('/stock-detail', extra: pos.ticker),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        TickerLogo(
                                          ticker: stock.ticker,
                                          logoUrl: stock.logoUrl,
                                          logoColor: stock.logoColor,
                                          size: 38,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pos.ticker,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                '${pos.quantity} Shares • Avg ₹${pos.avgPrice.toStringAsFixed(2)}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF8892A4),
                                                ),
                                              ),
                                              Text(
                                                'Now: ₹${currentPrice.toStringAsFixed(2)}',
                                                style: GoogleFonts.robotoMono(
                                                  fontSize: 10.5,
                                                  color: const Color(0xFF0066CC),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormatter.format(currentValue),
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '${posProfit ? "+" : ""}${currencyFormatter.format(positionPnL)} (${posProfit ? "+" : ""}${positionPnLPct.toStringAsFixed(2)}%)',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: posProfit ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ElevatedButton(
                                              onPressed: () {
                                                HapticFeedback.mediumImpact();
                                                final success = portfolio.closePosition(pos.ticker);
                                                if (success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Sold ${pos.quantity} shares of ${pos.ticker} at ₹${currentPrice.toStringAsFixed(2)}',
                                                      ),
                                                      backgroundColor: const Color(0xFF00C853),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFF3B3B).withValues(alpha: 0.15),
                                                foregroundColor: const Color(0xFFFF3B3B),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  side: const BorderSide(color: Color(0xFFFF3B3B), width: 1),
                                                ),
                                              ),
                                              child: Text(
                                                'Sell',
                                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                    // ── Tab 2: Limit Orders ───────────────────────
                    portfolio.limitOrders.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            title: 'No Limit Orders',
                            subtitle: 'Place target price limit orders on any stock to execute automatically when triggered.',
                            buttonText: 'Explore Stocks',
                            onTap: () => context.push('/market'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: portfolio.limitOrders.length,
                            itemBuilder: (context, idx) {
                              final order = portfolio.limitOrders[idx];
                              final isBuy = order.isBuy;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF111827) : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBuy
                                              ? const Color(0xFF00C853).withValues(alpha: 0.12)
                                              : const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isBuy ? 'LIMIT BUY' : 'LIMIT SELL',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.ticker,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '${order.quantity} Shares @ Target ₹${order.limitPrice.toStringAsFixed(2)}',
                                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (order.isExecuted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00C853).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'EXECUTED',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF00C853),
                                            ),
                                          ),
                                        )
                                      else
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            portfolio.cancelLimitOrder(order.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Limit order cancelled'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.close_rounded, size: 14),
                                          label: const Text('Cancel'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                                            foregroundColor: const Color(0xFFFF3B3B),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    // ── Tab 3: Trade History Ledger ───────────────
                    portfolio.tradeHistory.isEmpty
                        ? _buildEmptyState(
                            isDark: isDark,
                            title: 'No Trade History Yet',
                            subtitle: 'Every buy and sell order executes in real time and is recorded in this persistent ledger.',
                            buttonText: 'Explore Stocks',
                            onTap: () => context.push('/market'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: portfolio.tradeHistory.length,
                            itemBuilder: (context, idx) {
                              final trade = portfolio.tradeHistory[idx];
                              final timeStr = DateFormat('dd MMM, hh:mm a').format(trade.timestamp);
                              final isBuy = trade.isBuy;
                              final totalAmount = trade.quantity * trade.price;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF111827) : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBuy
                                              ? const Color(0xFF00C853).withValues(alpha: 0.12)
                                              : const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isBuy ? 'BUY' : 'SELL',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${trade.stockName} (${trade.ticker})',
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${trade.quantity} Shares @ ₹${trade.price.toStringAsFixed(2)} • $timeStr',
                                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            currencyFormatter.format(totalAmount),
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (!isBuy)
                                            Text(
                                              '${trade.realizedPnL >= 0 ? "+" : ""}${currencyFormatter.format(trade.realizedPnL)}',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: trade.realizedPnL >= 0
                                                    ? const Color(0xFF00C853)
                                                    : const Color(0xFFFF3B3B),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 40,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8892A4),
                height: 1.5,
              ),
            ),
            if (buttonText != null && onTap != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
