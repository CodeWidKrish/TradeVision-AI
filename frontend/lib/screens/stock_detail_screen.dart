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
import '../services/api_service.dart';
import '../widgets/chart_type_selector.dart';
import '../widgets/interactive_stock_chart.dart';
import '../widgets/real_stock_chart.dart';
import '../widgets/ai_explanation_sheet.dart';
import 'package:provider/provider.dart' as provider;
import '../core/providers/portfolio_provider.dart';
import '../widgets/ticker_logo.dart';
import '../widgets/swipe_to_execute_button.dart';
import '../widgets/create_alert_sheet.dart';
import '../services/alert_service.dart';
import '../widgets/xai_contribution_widget.dart';


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

  // ── Dynamic data: loaded from backend per stock ──────────────────────
  Map<String, dynamic> _technicals = {};
  Map<String, dynamic> _fundamentals = {};
  bool _techLoading = true;
  bool _fundLoading = true;

  static double? _toDbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toI(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    _stock = StockRepository.getStock(widget.symbol);
    _loadLiveStock();
    _loadDynamicData();
  }

  Future<void> _loadLiveStock() async {
    try {
      final updated = await StockRepository.fetchAndCacheStock(widget.symbol);
      if (mounted) {
        setState(() {
          _stock = updated;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDynamicData() async {
    final sym = widget.symbol.replaceAll('.NS', '').replaceAll('.BO', '').trim();
    try {
      final tech = ApiService.fetchTechnicals(sym);
      final fund = ApiService.fetchFundamentals(sym);
      final results = await Future.wait([tech, fund]);
      if (mounted) {
        setState(() {
          _technicals = results[0];
          _fundamentals = results[1];
          _techLoading = false;
          _fundLoading = false;
        });
        final sig = _technicals['ai_signal'] as String? ?? _stock.aiSignal;
        final rsiVal = _toDbl(_technicals['rsi']);
        AlertService.instance.evaluateSignal(
          ticker: _stock.ticker,
          signal: sig,
          rsi: rsiVal,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _techLoading = false;
          _fundLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSignalDisclaimerSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    final dynamicSignal = (_technicals['ai_signal'] as String?)?.isNotEmpty == true
        ? (_technicals['ai_signal'] as String)
        : _stock.aiRecommendation;
    final dynamicConfidence = _toDbl(_technicals['ai_confidence'])
        ?? ((_stock.sentimentScore * 100).clamp(45.0, 96.0));
    AiExplanationSheet.show(
      context,
      ticker: _stock.ticker,
      stockName: _stock.name,
      signal: dynamicSignal,
      confidenceScore: dynamicConfidence,
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
          // Price Alert trigger button
          IconButton(
            icon: const Icon(
              Icons.add_alert_rounded,
              color: Color(0xFF0066CC),
              size: 22,
            ),
            tooltip: 'Set Price Alert',
            onPressed: () {
              HapticFeedback.mediumImpact();
              CreateAlertSheet.show(context, _stock);
            },
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
                      // Dynamic AI Signal badge
                      _SignalBadgeWithInfo(
                        signal: (_technicals['ai_signal'] as String?)?.isNotEmpty == true
                            ? (_technicals['ai_signal'] as String)
                            : _stock.aiSignal,
                        confidence: _toI(_technicals['ai_confidence']),
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
                    key: ValueKey('${_stock.ticker}_$_selectedPeriod'),
                    ticker: _stock.ticker,
                    period: _selectedPeriod,
                    chartType: ref.watch(chartPatternProvider),
                    onChartTypeChanged: (newType) {
                      ref.read(chartPatternProvider.notifier).setChartType(newType);
                    },
                    showHeader: false,
                    onPriceTick: (livePrice) {
                      if (!mounted) return;
                      final prevPrice = _stock.price - _stock.changeAmount;
                      final newChg = double.parse((livePrice - prevPrice).toStringAsFixed(2));
                      final newPct = double.parse((prevPrice > 0 ? (newChg / prevPrice * 100) : 0.0).toStringAsFixed(2));
                      setState(() {
                        _stock = _stock.copyWith(
                          price: livePrice,
                          changeAmount: newChg,
                          changePercent: newPct,
                        );
                      });
                      StockRepository.registerStock(_stock);
                    },
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

            const SizedBox(height: 70),
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
    bool isLimitOrder = false;
    double limitPrice = _stock.price;
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
            final portfolio = provider.Provider.of<PortfolioProvider>(context, listen: false);
            final totalValue = (isLimitOrder ? limitPrice : _stock.price) * quantity;
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
                                    'Virtual Cash: ${currencyFormatter.format(portfolio.virtualCash)} • Paper Trading',
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
                      const SizedBox(height: 12),

                      // Order Type Segmented Switch (Market vs Limit)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => isLimitOrder = false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isLimitOrder ? const Color(0xFF0066CC) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Market (Instant)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: !isLimitOrder ? Colors.white : const Color(0xFF8892A4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => isLimitOrder = true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isLimitOrder ? const Color(0xFF0066CC) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Limit (Target Price)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isLimitOrder ? Colors.white : const Color(0xFF8892A4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (isLimitOrder) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target Limit Price',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded),
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  onPressed: limitPrice > 1
                                      ? () => setModalState(() => limitPrice = double.parse((limitPrice - 1.0).toStringAsFixed(2)))
                                      : null,
                                ),
                                Text(
                                  currencyFormatter.format(limitPrice),
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0066CC),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  onPressed: () => setModalState(() => limitPrice = double.parse((limitPrice + 1.0).toStringAsFixed(2))),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

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
                          if (isLimitOrder) {
                            portfolio.placeLimitOrder(
                              stock: _stock,
                              isBuy: isBuy,
                              quantity: quantity,
                              limitPrice: limitPrice,
                            );
                            Future.delayed(const Duration(milliseconds: 1200), () {
                              if (Navigator.canPop(ctx)) {
                                Navigator.pop(ctx);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Placed Limit ${isBuy ? "BUY" : "SELL"} for $quantity shares of ${_stock.ticker} at ₹${limitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: const Color(0xFF0066CC),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            });
                            return;
                          }
                          final cost = _stock.price * quantity;
                          if (isBuy && portfolio.virtualCash < cost) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Insufficient simulated balance! Available: ${currencyFormatter.format(portfolio.virtualCash)}'),
                                backgroundColor: const Color(0xFFFF3B3B),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final currentHolding = portfolio.getHoldingQuantity(_stock.ticker);
                          if (!isBuy && currentHolding < quantity) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cannot sell $quantity shares. You hold $currentHolding shares of ${_stock.ticker}.'),
                                backgroundColor: const Color(0xFFFF3B3B),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
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
    if (_techLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: const Color(0xFF0066CC),
              strokeWidth: 2,
            ),
            const SizedBox(height: 14),
            Text('Loading AI analysis...', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8892A4))),
          ],
        ),
      );
    }

    final aiSignal = (_technicals['ai_signal'] as String? ?? _stock.aiSignal).toUpperCase();
    final confidence = _toI(_technicals['ai_confidence']) ?? 72;
    final aiReason = _technicals['ai_reason'] as String? ?? _stock.aiReason;
    final buyersPct = _toDbl(_technicals['buyers_pct']) ?? 54.0;
    final sellersPct = _toDbl(_technicals['sellers_pct']) ?? 46.0;
    final buySellRatio = _toDbl(_technicals['buy_sell_ratio']) ?? 1.17;
    final rsi = _toDbl(_technicals['rsi']);
    final macd = _toDbl(_technicals['macd']);
    final stoch = _toDbl(_technicals['stochastic']);
    final volSurge = _toDbl(_technicals['vol_surge_pct']) ?? 100.0;

    final signalColor = switch (aiSignal) {
      'BUY' || 'STRONG BUY' => const Color(0xFF00C853),
      'SELL' || 'STRONG SELL' => const Color(0xFFFF3B3B),
      _ => const Color(0xFFFF8C00),
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI Signal card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: signalColor.withValues(alpha: isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: signalColor.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: signalColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI: $aiSignal',
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF0066CC).withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        'Confidence: $confidence%',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: const Color(0xFF0066CC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  aiReason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Confidence bar ───────────────────────────────────────────
          Text('AI Confidence', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence / 100,
              backgroundColor: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE2E6EA),
              valueColor: AlwaysStoppedAnimation<Color>(signalColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Not sure', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8892A4))),
              Text('$confidence%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: signalColor)),
              Text('Very sure', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8892A4))),
            ],
          ),
          const SizedBox(height: 14),

          // ── Live Buyers vs Sellers ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 14, color: const Color(0xFF8892A4)),
                    const SizedBox(width: 6),
                    Text('Live Market Sentiment — Buyers vs Sellers',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E))),
                  ],
                ),
                const SizedBox(height: 10),
                // Stacked bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        Expanded(
                          flex: buyersPct.round(),
                          child: Container(color: const Color(0xFF00C853)),
                        ),
                        Expanded(
                          flex: sellersPct.round(),
                          child: Container(color: const Color(0xFFFF3B3B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(
                      color: Color(0xFF00C853), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Buyers ${buyersPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                            color: const Color(0xFF00C853))),
                    const Spacer(),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(
                      color: Color(0xFFFF3B3B), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Sellers ${sellersPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF3B3B))),
                    const Spacer(),
                    Text('Ratio ${buySellRatio.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8892A4))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Quick indicator chips ───────────────────────────────────
          Row(
            children: [
              _MiniIndicatorChip(
                label: 'RSI',
                value: rsi != null ? rsi.toStringAsFixed(1) : '--',
                color: rsi == null ? const Color(0xFF8892A4)
                    : rsi < 30 ? const Color(0xFFFF3B3B)
                    : rsi > 70 ? const Color(0xFFFF8C00)
                    : const Color(0xFF00C853),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MiniIndicatorChip(
                label: 'MACD',
                value: macd != null ? '${macd > 0 ? '+' : ''}${macd.toStringAsFixed(2)}' : '--',
                color: macd == null ? const Color(0xFF8892A4)
                    : macd > 0 ? const Color(0xFF00C853)
                    : const Color(0xFFFF3B3B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MiniIndicatorChip(
                label: 'Stoch',
                value: stoch != null ? stoch.toStringAsFixed(1) : '--',
                color: stoch == null ? const Color(0xFF8892A4)
                    : stoch < 20 ? const Color(0xFF00C853)
                    : stoch > 80 ? const Color(0xFFFF3B3B)
                    : const Color(0xFFFF8C00),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MiniIndicatorChip(
                label: 'Vol',
                value: '${volSurge.toStringAsFixed(0)}%',
                color: volSurge > 150 ? const Color(0xFF00C853)
                    : volSurge < 70 ? const Color(0xFF8892A4)
                    : const Color(0xFFFF8C00),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Explainable AI (XAI) Feature Attribution (SHAP / LSTM) ──
          XaiContributionWidget(
            ticker: _stock.ticker,
            signal: aiSignal,
            confidence: confidence.toDouble(),
            rsi: rsi,
            macd: macd,
            buyersPct: buyersPct,
            sellersPct: sellersPct,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalTab(bool isDark) {
    if (_techLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: Color(0xFF0066CC), strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Computing real-time technical indicators...',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF8892A4)),
            ),
          ],
        ),
      );
    }

    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
    final rsi = _toDbl(_technicals['rsi']) ?? 50.0;
    final ma20 = _toDbl(_technicals['ma20']) ?? _toDbl(_technicals['ma_20']);
    final ma50 = _toDbl(_technicals['ma50']) ?? _toDbl(_technicals['ma_50']);
    final ma200 = _toDbl(_technicals['ma200']) ?? _toDbl(_technicals['ma_200']);
    final macd = _toDbl(_technicals['macd']);
    final macdSig = _toDbl(_technicals['macd_signal']) ?? _toDbl(_technicals['signal_val']);
    final macdHist = _toDbl(_technicals['macd_histogram']);
    final bollUp = _toDbl(_technicals['bollinger_upper']);
    final bollMid = _toDbl(_technicals['bollinger_mid']);
    final bollDn = _toDbl(_technicals['bollinger_lower']);
    final atr = _toDbl(_technicals['atr']);
    final support = _toDbl(_technicals['support']) ?? _toDbl(_technicals['support_1']) ?? (_stock.price * 0.95);
    final resistance = _toDbl(_technicals['resistance']) ?? _toDbl(_technicals['resistance_1']) ?? (_stock.price * 1.05);
    final week52High = double.tryParse(_stock.week52High.replaceAll(RegExp(r'[^0-9.]'), '')) ?? (_stock.price * 1.25);
    final week52Low  = double.tryParse(_stock.week52Low.replaceAll(RegExp(r'[^0-9.]'), '')) ?? (_stock.price * 0.75);

    final titleColor = isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);
    final cardBg = isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF1E2D42) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. RSI Momentum Gauge ──────────────────────────────────
          _RSIGauge(rsi: rsi, isDark: isDark),
          const SizedBox(height: 20),

          // ── 2. Moving Averages ────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: Color(0xFF0066CC)),
              const SizedBox(width: 8),
              Text(
                'Moving Averages',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const Spacer(),
              if (ma20 != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_stock.price >= ma20 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (_stock.price >= ma20 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B))
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _stock.price >= ma20 ? 'Short Bullish ↑' : 'Short Bearish ↓',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _stock.price >= ma20 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MAChip(
                  label: 'MA-20',
                  sublabel: '20D',
                  value: ma20 != null ? currencyFormatter.format(ma20) : 'N/A',
                  isAbove: ma20 != null ? _stock.price > ma20 : null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MAChip(
                  label: 'MA-50',
                  sublabel: '50D',
                  value: ma50 != null ? currencyFormatter.format(ma50) : 'N/A',
                  isAbove: ma50 != null ? _stock.price > ma50 : null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MAChip(
                  label: 'MA-200',
                  sublabel: '200D',
                  value: ma200 != null ? currencyFormatter.format(ma200) : 'N/A',
                  isAbove: ma200 != null ? _stock.price > ma200 : null,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 3. MACD Oscillator ────────────────────────────────────
          if (macd != null) ...[
            Row(
              children: [
                const Icon(Icons.waterfall_chart_rounded, size: 18, color: Color(0xFF00B0FF)),
                const SizedBox(width: 8),
                Text(
                  'MACD Trend Oscillator',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (macd > 0 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (macd > 0 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B))
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    macd > 0 ? 'BULLISH MOMENTUM' : 'BEARISH MOMENTUM',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: macd > 0 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  // MACD Line
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MACD Line', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4))),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${macd > 0 ? '+' : ''}${macd.toStringAsFixed(2)}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: macd > 0 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('12, 26 EMA', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 42, color: cardBorder),
                  const SizedBox(width: 12),
                  // Signal Line
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Signal Line', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4))),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            macdSig != null ? '${macdSig > 0 ? '+' : ''}${macdSig.toStringAsFixed(2)}' : '--',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('9 EMA Signal', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 42, color: cardBorder),
                  const SizedBox(width: 12),
                  // Histogram
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Histogram', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4))),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            macdHist != null ? '${macdHist > 0 ? '+' : ''}${macdHist.toStringAsFixed(2)}' : '--',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: (macdHist ?? 0) > 0 ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (macdHist ?? 0) > 0 ? 'Divergence ↑' : 'Convergence ↓',
                          style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── 4. Bollinger Bands ────────────────────────────────────
          if (bollUp != null) ...[
            Row(
              children: [
                const Icon(Icons.waves_rounded, size: 18, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Text(
                  'Bollinger Bands (20, 2σ)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BollingerCard(
                    title: 'Upper Band',
                    tag: 'Resistance',
                    value: currencyFormatter.format(bollUp),
                    color: const Color(0xFFFF5252),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BollingerCard(
                    title: 'Middle (SMA)',
                    tag: 'Baseline',
                    value: bollMid != null ? currencyFormatter.format(bollMid) : 'N/A',
                    color: const Color(0xFF00B0FF),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BollingerCard(
                    title: 'Lower Band',
                    tag: 'Support',
                    value: currencyFormatter.format(bollDn ?? 0),
                    color: const Color(0xFF00E676),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── 5. Key Price Levels & 52-Week Range ────────────────────
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: Color(0xFFFF8C00)),
              const SizedBox(width: 8),
              Text(
                'Price Range & Key Boundaries',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 52-Week Visual Range Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('52W Low', style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF8892A4))),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(week52Low),
                          style: GoogleFonts.robotoMono(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFFFF3B3B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Current: ${currencyFormatter.format(_stock.price)}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0066CC),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('52W High', style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF8892A4))),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(week52High),
                          style: GoogleFonts.robotoMono(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF00C853)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final range = week52High - week52Low;
                    final ratio = range > 0
                        ? ((_stock.price - week52Low) / range).clamp(0.0, 1.0)
                        : 0.5;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF3B3B),
                                  Color(0xFFFFB300),
                                  Color(0xFF00C853),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (constraints.maxWidth * ratio - 6).clamp(0.0, constraints.maxWidth - 12),
                          top: -3,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0066CC), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Support & Resistance (Side by side)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: isDark ? 0.08 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF00E676)),
                          const SizedBox(width: 4),
                          Text(
                            'Support (Buy)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currencyFormatter.format(support),
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00E676),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Buyer demand floor',
                        style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF8892A4)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3366).withValues(alpha: isDark ? 0.08 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vertical_align_top_rounded, size: 14, color: Color(0xFFFF3366)),
                          const SizedBox(width: 4),
                          Text(
                            'Resistance (Sell)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF3366),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currencyFormatter.format(resistance),
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF3366),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Seller supply ceiling',
                        style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF8892A4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ATR banner
          if (atr != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_graph_rounded, size: 16, color: Color(0xFF0066CC)),
                  const SizedBox(width: 8),
                  Text(
                    'Average True Range (ATR):',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8892A4)),
                  ),
                  const Spacer(),
                  Text(
                    '±${currencyFormatter.format(atr)} / day',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCompanyTab(bool isDark) {
    if (_fundLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: const Color(0xFF0066CC), strokeWidth: 2),
            const SizedBox(height: 14),
            Text('Loading company data...', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8892A4))),
          ],
        ),
      );
    }

    final fund = _fundamentals;
    final marketCapDisplay = fund['market_cap_display'] as String? ?? _stock.marketCap;
    final peDisplay = fund['pe_ratio_display'] as String? ?? _stock.peRatio;
    final epsDisplay = fund['eps_display'] as String? ?? 'N/A';
    final divDisplay = fund['dividend_yield_display'] as String? ?? '—';
    final bookDisplay = fund['book_value_display'] as String? ?? 'N/A';
    final debtDisplay = fund['debt_to_equity_display'] as String? ?? 'N/A';
    final roeDisplay = fund['roe_display'] as String? ?? 'N/A';
    final betaDisplay = fund['beta_display'] as String? ?? 'N/A';
    final sectorDisplay = fund['sector'] as String? ?? _stock.sector;
    final industryDisplay = fund['industry'] as String? ?? sectorDisplay;
    final description = fund['description'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          if (description != null && description.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2332) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0066CC).withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF0066CC)),
                    const SizedBox(width: 6),
                    Text('About ${_stock.ticker}', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0066CC))),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    description.length > 320 ? '${description.substring(0, 320)}...' : description,
                    style: GoogleFonts.inter(fontSize: 11.5, color: isDark
                        ? const Color(0xFFB0BEC5) : const Color(0xFF4A5568), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          _FundamentalRow(label: 'Market Cap', value: marketCapDisplay,
              tooltip: 'Total value of all company shares combined', isDark: isDark),
          _FundamentalRow(label: 'P/E Ratio', value: peDisplay,
              tooltip: 'Price-to-Earnings — how much you pay per ₹1 earned. Lower is cheaper.', isDark: isDark),
          _FundamentalRow(label: 'EPS (Earnings/Share)', value: epsDisplay,
              tooltip: 'How much profit the company makes per single share', isDark: isDark),
          _FundamentalRow(label: 'Dividend Yield', value: divDisplay,
              tooltip: 'Annual dividend paid as % of current share price', isDark: isDark),
          _FundamentalRow(label: 'Book Value/Share', value: bookDisplay,
              tooltip: 'Net asset value per share (assets minus liabilities)', isDark: isDark),
          _FundamentalRow(label: 'Debt-to-Equity', value: debtDisplay,
              tooltip: 'How much debt the company holds vs. shareholders equity. Lower is safer.', isDark: isDark),
          _FundamentalRow(label: 'Return on Equity (ROE)', value: roeDisplay,
              tooltip: 'Profit earned for every rupee of shareholders equity', isDark: isDark),
          _FundamentalRow(label: 'Beta (Volatility)', value: betaDisplay,
              tooltip: 'How volatile the stock is vs market. >1 = more volatile, <1 = more stable', isDark: isDark),
          _FundamentalRow(label: '52-Week High', value: _stock.week52High, isDark: isDark),
          _FundamentalRow(label: '52-Week Low', value: _stock.week52Low, isDark: isDark),
          _FundamentalRow(label: 'Daily Volume', value: _stock.volume,
              tooltip: 'Total shares traded today', isDark: isDark),
          _FundamentalRow(label: 'Sector', value: sectorDisplay, isDark: isDark),
          _FundamentalRow(label: 'Industry', value: industryDisplay, isDark: isDark),
        ],
      ),
    );
  }
}

class _SignalBadgeWithInfo extends StatelessWidget {
  final String signal;
  final int? confidence;
  final VoidCallback onTap;

  const _SignalBadgeWithInfo({
    required this.signal,
    this.confidence,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sigUpper = signal.toUpperCase().trim();

    final Color mainColor;
    final Color endColor;
    final IconData trendIcon;
    final String displayTag;

    if (sigUpper.contains('BUY')) {
      mainColor = const Color(0xFF00E676);
      endColor = const Color(0xFF00B0FF);
      trendIcon = Icons.trending_up_rounded;
      displayTag = sigUpper.contains('STRONG') ? 'STRONG BUY' : 'BUY';
    } else if (sigUpper.contains('SELL')) {
      mainColor = const Color(0xFFFF3366);
      endColor = const Color(0xFFFF5252);
      trendIcon = Icons.trending_down_rounded;
      displayTag = sigUpper.contains('STRONG') ? 'STRONG SELL' : 'SELL';
    } else {
      mainColor = const Color(0xFFFFB300);
      endColor = const Color(0xFFFF8F00);
      trendIcon = Icons.swap_horiz_rounded;
      displayTag = 'HOLD';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mainColor.withValues(alpha: 0.20),
              endColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: mainColor.withValues(alpha: 0.65),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: mainColor.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing pulsing indicator dot
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.95),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              displayTag,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: mainColor,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              trendIcon,
              size: 13,
              color: mainColor,
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.info_outline_rounded,
              size: 11,
              color: mainColor.withValues(alpha: 0.75),
            ),
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

    final statusTag = rsi < 30
        ? 'Oversold'
        : rsi > 70
            ? 'Overbought'
            : 'Neutral';

    final insightText = rsi < 30
        ? 'Selling momentum is stretched. Price may be near a technical bottom.'
        : rsi > 70
            ? 'Heavy buying pressure. Caution: price is in an overbought condition.'
            : 'Balanced momentum. Healthy equilibrium between buyers and sellers.';

    final cardBg = isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF1E2D42) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'RSI (14D)',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                rsi.toStringAsFixed(1),
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  statusTag,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (rsi / 100).clamp(0.0, 1.0),
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 Oversold', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
              Text('50 Neutral', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
              Text('100 Overbought', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insightText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIndicatorChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniIndicatorChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.robotoMono(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(
                fontSize: 9.5, color: const Color(0xFF8892A4))),
          ],
        ),
      ),
    );
  }
}

class _MAChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String value;
  final bool? isAbove;
  final bool isDark;

  const _MAChip({
    required this.label,
    this.sublabel,
    required this.value,
    required this.isAbove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAbove == null
        ? const Color(0xFF8892A4)
        : isAbove! ? const Color(0xFF00C853) : const Color(0xFFFF3B3B);

    final cardBg = isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 6,
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
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              if (isAbove != null)
                Icon(
                  isAbove! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 13,
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isAbove == null ? 'N/A' : (isAbove! ? 'Above MA' : 'Below MA'),
              style: GoogleFonts.inter(
                fontSize: 9.5,
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

class _BollingerCard extends StatelessWidget {
  final String title;
  final String tag;
  final String value;
  final Color color;
  final bool isDark;

  const _BollingerCard({
    required this.title,
    required this.tag,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: GoogleFonts.inter(
                fontSize: 9.5,
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
