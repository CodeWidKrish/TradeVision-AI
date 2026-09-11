import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/data/stock_data.dart';
import '../core/models/ohlc_point.dart';
import '../core/providers/watchlist_provider.dart';
import '../core/providers/chart_pattern_provider.dart';
import '../services/storage_service.dart';
import '../widgets/chart_type_selector.dart';
import '../widgets/interactive_stock_chart.dart';
import '../widgets/real_stock_chart.dart';
import '../widgets/ai_explanation_sheet.dart';
import 'package:provider/provider.dart' as provider;
import '../core/providers/portfolio_provider.dart';
import '../widgets/ticker_logo.dart';
import '../widgets/swipe_to_execute_button.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final String symbol;

  const StockDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '1D';
  final List<String> _periods = ['1D', '1W', '1M', '3M', '6M', '1Y', '5Y', 'MAX'];
  late TabController _tabController;
  int _selectedTab = 0;

  late StockModel _stock;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    _stock = StockRepository.stocks.firstWhere(
      (s) => s.ticker.toUpperCase() == widget.symbol.toUpperCase(),
      orElse: () => StockRepository.stocks.first,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSignalDisclaimerSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    AiExplanationSheet.show(
      context,
      ticker: _stock.ticker,
      stockName: _stock.name,
      signal: _stock.aiRecommendation,
      confidenceScore: (_stock.sentimentScore * 100).clamp(45.0, 96.0),
      currentPrice: _stock.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final watchlist = ref.watch(watchlistProvider);
    final isBookmarked = watchlist.contains(_stock.ticker.toUpperCase());

    final isPositive = _stock.isPositive;
    final priceColor =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B);
    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');

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
        title: Row(
          children: [
            TickerLogo(
              ticker: _stock.ticker,
              logoUrl: _stock.logoUrl,
              logoColor: _stock.logoColor,
              size: 34,
              heroTag: 'stock-logo-${_stock.ticker}',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stock.ticker,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFE8ECF0)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    _stock.fullName,
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
          ],
        ),
        actions: [
          // Exchange badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF0066CC).withValues(alpha: 0.30),
              ),
            ),
            child: Text(
              _stock.exchange,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0066CC),
              ),
            ),
          ),
          // Bookmark with optimistic micro-bounce and feedback
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                key: ValueKey<bool>(isBookmarked),
                color: isBookmarked
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF8892A4),
                size: 22,
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              watchlistNotifier.toggleWatchlist(_stock.ticker);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        !isBookmarked ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        !isBookmarked
                            ? 'Added ${_stock.ticker} to Watchlist'
                            : 'Removed ${_stock.ticker} from Watchlist',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 1400),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ],
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Price Header ──────────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currencyFormatter.format(_stock.price),
                      style: GoogleFonts.robotoMono(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : const Color(0xFF1A1A2E),
                        letterSpacing: -1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                              color: priceColor,
                              size: 20,
                            ),
                            Flexible(
                              child: Text(
                                '${isPositive ? '+' : ''}${currencyFormatter.format(_stock.changeAmount.abs())} (${isPositive ? '+' : ''}${_stock.changePercent.toStringAsFixed(2)}%)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: priceColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Today',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8892A4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Signal badge
                      _SignalBadgeWithInfo(
                        signal: _stock.aiSignal,
                        onTap: () => _showSignalDisclaimerSheet(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Chart Section ─────────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  ChartHeaderRow(
                    periods: _periods,
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: (p) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPeriod = p);
                    },
                    selectedType: ref.watch(chartPatternProvider),
                    onTypeChanged: (newType) {
                      ref.read(chartPatternProvider.notifier).setChartType(newType);
                    },
                  ),
                  const SizedBox(height: 12),
                  RealStockChart(
                    ticker: _stock.ticker,
                    period: _selectedPeriod,
                    chartType: ref.watch(chartPatternProvider),
                    onChartTypeChanged: (newType) {
                      ref.read(chartPatternProvider.notifier).setChartType(newType);
                    },
                    showHeader: false,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── OHLV Stats Row ────────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Open',
                    value: currencyFormatter.format(_stock.openPrice),
                    isDark: isDark,
                  ),
                  _StatChip(
                    label: 'High',
                    value: currencyFormatter.format(_stock.dayHigh),
                    isDark: isDark,
                    color: const Color(0xFF00C853),
                  ),
                  _StatChip(
                    label: 'Low',
                    value: currencyFormatter.format(_stock.dayLow),
                    isDark: isDark,
                    color: const Color(0xFFFF3B3B),
                  ),
                  _StatChip(
                    label: 'Volume',
                    value: _stock.volume,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Bar: AI Analysis / Technical / Company ────────
            Container(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              child: Column(
                children: [
                  // Tab bar
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2A3A)
                          : const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildDetailTab('AI Analysis', 0, isDark),
                        _buildDetailTab('Technical', 1, isDark),
                        _buildDetailTab('Company', 2, isDark),
                      ],
                    ),
                  ),

                  // Animated tab content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: switch (_selectedTab) {
                        0 => _buildAITab(isDark),
                        1 => _buildTechnicalTab(isDark),
                        2 => _buildCompanyTab(isDark),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── SEBI Disclaimer ───────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFFF8C00), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This analysis is for learning only. TradeVision AI does not provide financial advice. Always consult a SEBI-registered advisor before investing.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFFFF8C00),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          math.max(MediaQuery.of(context).padding.bottom, 22.0),
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Current price summary
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stock.priceFormatted,
                    style: GoogleFonts.robotoMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _stock.isPositive
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        color: _stock.isPositive
                            ? const Color(0xFF00C853)
                            : const Color(0xFFFF3B3B),
                        size: 16,
                      ),
                      Text(
                        _stock.changePercentFormatted,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _stock.isPositive
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF3B3B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BUY button
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => _openOrderSheet(context, isBuy: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'BUY',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // SELL button
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () => _openOrderSheet(context, isBuy: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B3B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      'SELL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrderSheet(BuildContext context, {required bool isBuy}) {
    HapticFeedback.mediumImpact();
    int quantity = 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final totalValue = _stock.price * quantity;
            final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
            final bottomPadding = math.max(MediaQuery.of(ctx).padding.bottom, 22.0) +
                MediaQuery.of(ctx).viewInsets.bottom;

            return SafeArea(
              bottom: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Handle Bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A374A) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Paper Trading Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'PAPER TRADING • SIMULATION',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF00E5FF),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E5FF).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ZERO RISK',
                                          style: GoogleFonts.inter(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF00E5FF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Virtual Cash: ₹5,00,000.00 • Practice Trading',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Stock Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TickerLogo(
                                ticker: _stock.ticker,
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${isBuy ? "BUY" : "SELL"} ${_stock.ticker}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                    ),
                                  ),
                                  Text(
                                    '${_stock.exchange} • ${_stock.priceFormatted}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF8892A4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: isDark ? Colors.white70 : Colors.black54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                        height: 1,
                      ),
                      const SizedBox(height: 14),

                      // Quantity Selector with - and + buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quantity (Shares)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                color: isDark ? Colors.white70 : Colors.black87,
                                onPressed: quantity > 1
                                    ? () => setModalState(() => quantity--)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF0F4F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$quantity',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                color: isDark ? Colors.white70 : Colors.black87,
                                onPressed: () => setModalState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Total Value
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Total',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF8892A4),
                              ),
                            ),
                            Text(
                              currencyFormatter.format(totalValue),
                              style: GoogleFonts.robotoMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Swipe To Execute Slider
                      SwipeToExecuteButton(
                        isBuy: isBuy,
                        stockTicker: _stock.ticker,
                        priceFormatted: currencyFormatter.format(totalValue),
                        quantity: quantity,
                        onConfirmed: () {
                          final portfolio = provider.Provider.of<PortfolioProvider>(context, listen: false);
                          if (isBuy) {
                            portfolio.buyStock(_stock, quantity);
                          } else {
                            portfolio.sellStock(_stock, quantity);
                          }
                          Future.delayed(const Duration(milliseconds: 1400), () {
                            if (Navigator.canPop(ctx)) {
                              Navigator.pop(ctx);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${isBuy ? "Bought" : "Sold"} $quantity shares of ${_stock.ticker} at ${_stock.priceFormatted}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTab(String label, int index, bool isDark) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0066CC) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF8892A4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAITab(bool isDark) {
    final confidence = 89;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0066CC).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Signal: ${_stock.aiSignal}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        'Confidence: $confidence%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0066CC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _stock.aiReason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : const Color(0xFF1A1A2E),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'How confident is the AI?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: isDark
                  ? const Color(0xFF1E2A3A)
                  : const Color(0xFFE2E6EA),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0066CC),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0% — Not sure',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF8892A4))),
              Text('$confidence%',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0066CC))),
              Text('100% — Very sure',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF8892A4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalTab(bool isDark) {
    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RSIGauge(rsi: 62.4, isDark: isDark),
          const SizedBox(height: 16),
          Text(
            'Important Price Levels',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          _PriceLevel(
            label: '52-Week Highest Price',
            value: _stock.week52High,
            color: const Color(0xFF00C853),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _PriceLevel(
            label: '52-Week Lowest Price',
            value: _stock.week52Low,
            color: const Color(0xFFFF3B3B),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _PriceLevel(
            label: 'Support Level (Buy Zone)',
            value: currencyFormatter.format(_stock.price * 0.95),
            color: const Color(0xFF0066CC),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _PriceLevel(
            label: 'Resistance Level (Sell Zone)',
            value: currencyFormatter.format(_stock.price * 1.05),
            color: const Color(0xFFFF8C00),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FundamentalRow(
            label: 'Company Size (Market Cap)',
            value: _stock.marketCap,
            tooltip:
                'How much the entire company is worth if you add up all shares',
            isDark: isDark,
          ),
          _FundamentalRow(
            label: 'Price-to-Earnings (P/E)',
            value: _stock.peRatio,
            tooltip:
                'How much you pay for every ₹1 the company earns. Lower = cheaper.',
            isDark: isDark,
          ),
          _FundamentalRow(
            label: '1-Year Highest Price',
            value: _stock.week52High,
            isDark: isDark,
          ),
          _FundamentalRow(
            label: '1-Year Lowest Price',
            value: _stock.week52Low,
            isDark: isDark,
          ),
          _FundamentalRow(
            label: 'Daily Volume',
            value: _stock.volume,
            tooltip: 'How many shares were bought and sold today',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SignalBadgeWithInfo extends StatelessWidget {
  final String signal;
  final VoidCallback onTap;

  const _SignalBadgeWithInfo({
    required this.signal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final signalColor = switch (signal.toUpperCase()) {
      'BUY' => const Color(0xFF00C853),
      'SELL' => const Color(0xFFFF3B3B),
      _ => const Color(0xFFFF8C00),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: signalColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: signalColor.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              signal,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: signalColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded, size: 12, color: signalColor),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF8892A4),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
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

class _PriceLevel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _PriceLevel({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8892A4),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundamentalRow extends StatelessWidget {
  final String label;
  final String value;
  final String? tooltip;
  final bool isDark;

  const _FundamentalRow({
    required this.label,
    required this.value,
    this.tooltip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8892A4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor:
                              isDark ? const Color(0xFF111827) : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? const Color(0xFFE8ECF0)
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          content: Text(
                            tooltip!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF8892A4),
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Got it!',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0066CC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.help_outline_rounded,
                        size: 13, color: Color(0xFF8892A4)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RSIGauge extends StatelessWidget {
  final double rsi;
  final bool isDark;

  const _RSIGauge({required this.rsi, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = rsi < 30
        ? const Color(0xFFFF3B3B)
        : rsi > 70
            ? const Color(0xFFFF8C00)
            : const Color(0xFF00C853);
    final label = rsi < 30
        ? 'Oversold — Possibly cheap'
        : rsi > 70
            ? 'Overbought — Possibly expensive'
            : 'Neutral — Healthy momentum';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RSI (Momentum Score)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                rsi.toStringAsFixed(1),
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rsi / 100,
              backgroundColor:
                  isDark ? const Color(0xFF111827) : const Color(0xFFE2E6EA),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(
            'Below 30 = Too many sellers. Above 70 = Too many buyers. 30–70 = Balanced market.',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF8892A4),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
