import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart' as provider;
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/data/stock_data.dart';
import '../core/models/ohlc_point.dart';
import '../core/providers/market_ticker_provider.dart';
import '../widgets/index_card.dart';
import '../widgets/ticker_logo.dart';
import '../widgets/live_pulse_badge.dart';
import '../widgets/animated_press_card.dart';
import '../widgets/market_depth_widget.dart';
import '../widgets/signal_badge.dart';
import '../widgets/chart_type_selector.dart';
import '../widgets/interactive_stock_chart.dart';
import '../widgets/real_stock_chart.dart';
import '../core/providers/chart_pattern_provider.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/clock_provider.dart';
import '../widgets/ist_clock_widget.dart';
import '../services/storage_service.dart';

class MarketChartsScreen extends ConsumerStatefulWidget {
  final StockModel initialStock;
  final VoidCallback? onOpenProfile;

  const MarketChartsScreen({
    super.key,
    required this.initialStock,
    this.onOpenProfile,
  });

  @override
  ConsumerState<MarketChartsScreen> createState() => _MarketChartsScreenState();
}

class _MarketChartsScreenState extends ConsumerState<MarketChartsScreen> {
  late StockModel _selectedStock;
  int _selectedTab = 0; // 0=Overview, 1=Watchlist, 2=Stocks, 3=Charts
  String _selectedIndex = 'NIFTY 50';
  String _selectedTimeframe = '1D'; // 1D, 1W, 1M, 3M, 6M, 1Y, 5Y, MAX
  bool _isCandleMode = false;
  bool _showIndicators = true;
  final TextEditingController _searchController = TextEditingController();
  List<StockModel> _searchResults = [];
  bool _isSearching = false;
  final Set<String> _watchlistTickers = {'RELIANCE', 'TCS', 'HDFCBANK', 'INFY'};

  @override
  void initState() {
    super.initState();
    _selectedStock = widget.initialStock;
  }

  @override
  void didUpdateWidget(MarketChartsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStock.ticker != widget.initialStock.ticker) {
      setState(() {
        _selectedStock = widget.initialStock;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearching = true;
        _searchResults = StockRepository.searchStocks(query);
      });
    }
  }

  void _toggleWatchlist(String ticker) {
    setState(() {
      if (_watchlistTickers.contains(ticker)) {
        _watchlistTickers.remove(ticker);
      } else {
        _watchlistTickers.add(ticker);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _watchlistTickers.contains(ticker)
              ? '$ticker added to Watchlist'
              : '$ticker removed from Watchlist',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<StockModel> get _filteredSegmentStocks {
    final tickerNotifier = provider.Provider.of<MarketTickerNotifier>(context, listen: false);
    final all = tickerNotifier.stocks;

    switch (_selectedTab) {
      case 1: // Watchlist
        return all.where((s) => _watchlistTickers.contains(s.ticker)).toList();
      case 2: // Stocks
      case 3: // Charts
      case 0: // Overview
      default:
        return all;
    }
  }


  Widget _buildWatchlistTab() {
    final watchlistStocks = [
      {'ticker': 'RELIANCE', 'name': 'Reliance Industries', 'price': '₹2,886.76', 'change': '+1.10%', 'positive': true},
      {'ticker': 'TCS',      'name': 'Tata Consultancy Services', 'price': '₹3,543.42', 'change': '-0.46%', 'positive': false},
      {'ticker': 'HDFCBANK', 'name': 'HDFC Bank', 'price': '₹1,723.22', 'change': '+2.27%', 'positive': true},
      {'ticker': 'INFY',     'name': 'Infosys', 'price': '₹1,775.76', 'change': '-0.17%', 'positive': false},
      {'ticker': 'WIPRO',    'name': 'Wipro', 'price': '₹558.10', 'change': '-0.74%', 'positive': false},
      {'ticker': 'SBIN',     'name': 'State Bank of India', 'price': '₹812.43', 'change': '+0.90%', 'positive': true},
    ];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: watchlistStocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = watchlistStocks[i];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final stock = StockRepository.stocks.firstWhere(
          (s) => s.ticker == item['ticker'],
          orElse: () => StockRepository.stocks.first,
        );
        return AnimatedPressCard(
          onTap: () {
            setState(() {
              _selectedStock = stock;
              _selectedTab = 0;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
              ),
            ),
            child: Row(
              children: [
                TickerLogo(
                  ticker: stock.ticker,
                  logoUrl: stock.logoUrl,
                  logoColor: stock.logoColor,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['ticker'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        item['name'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8892A4),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item['price'] as String,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      item['change'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (item['positive'] as bool) ? AppColors.gain : AppColors.loss,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStocksTab() {
    final stocks = [
      {'ticker': 'BAJFINANCE', 'name': 'Bajaj Finance', 'sector': 'Finance', 'signal': 'AI Suggestion: Consider Buying', 'signalType': 'BUY', 'price': '₹7,284.50'},
      {'ticker': 'HINDUNILVR', 'name': 'Hindustan Unilever', 'sector': 'FMCG', 'signal': 'AI Suggestion: Wait and Watch', 'signalType': 'HOLD', 'price': '₹2,456.30'},
      {'ticker': 'ICICIBANK',  'name': 'ICICI Bank', 'sector': 'Banking', 'signal': 'AI Suggestion: Consider Buying', 'signalType': 'BUY', 'price': '₹1,143.60'},
      {'ticker': 'MARUTI',     'name': 'Maruti Suzuki', 'sector': 'Auto', 'signal': 'AI Suggestion: Consider Buying', 'signalType': 'BUY', 'price': '₹12,340.00'},
      {'ticker': 'TATASTEEL',  'name': 'Tata Steel', 'sector': 'Metals', 'signal': 'AI Suggestion: Wait and Watch', 'signalType': 'HOLD', 'price': '₹143.25'},
      {'ticker': 'ADANIENT',   'name': 'Adani Enterprises', 'sector': 'Conglomerate', 'signal': 'AI Suggestion: Consider Selling', 'signalType': 'SELL', 'price': '₹2,876.40'},
    ];
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = stocks[i];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final signalType = s['signalType'];
        final signalColor = signalType == 'BUY'
            ? const Color(0xFF00C853)
            : signalType == 'SELL'
                ? const Color(0xFFFF3B3B)
                : const Color(0xFFFF8C00);
        final stock = StockRepository.stocks.firstWhere(
          (st) => st.ticker == s['ticker'],
          orElse: () => StockRepository.stocks.first,
        );
        return AnimatedPressCard(
          onTap: () {
            context.push('/stock-detail/${stock.ticker}');
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
              ),
            ),
            child: Row(
              children: [
                TickerLogo(
                  ticker: stock.ticker,
                  logoUrl: stock.logoUrl,
                  logoColor: stock.logoColor,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        s['sector']!,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8892A4)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s['price']!,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: signalColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: signalColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        s['signal']!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: signalColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartPattern = ref.watch(chartPatternProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          AnimatedPressCard(
            onTap: () => context.push('/stock-detail/${_selectedStock.ticker}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
                ),
              ),
              child: Row(
                children: [
                  TickerLogo(
                    ticker: _selectedStock.ticker,
                    logoUrl: _selectedStock.logoUrl,
                    logoColor: _selectedStock.logoColor,
                    size: 40,
                    heroTag: 'charts-tab-logo-${_selectedStock.ticker}',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedStock.ticker,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066CC).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedStock.sector,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0066CC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedStock.fullName,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _selectedStock.priceFormatted,
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedStock.changePercentFormatted,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _selectedStock.isPositive
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF3B3B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ChartHeaderRow(
            periods: const ['1D', '1W', '1M', '3M', '6M', '1Y', '5Y', 'MAX'],
            selectedPeriod: _selectedTimeframe,
            onPeriodChanged: (tf) => setState(() => _selectedTimeframe = tf),
            selectedType: chartPattern,
            onTypeChanged: (newType) {
              ref.read(chartPatternProvider.notifier).setChartType(newType);
            },
          ),
          const SizedBox(height: 12),
          RealStockChart(
            ticker: _selectedStock.ticker,
            period: _selectedTimeframe,
            chartType: chartPattern,
            onChartTypeChanged: (newType) {
              ref.read(chartPatternProvider.notifier).setChartType(newType);
            },
            showHeader: false,
          ),
          const SizedBox(height: 16),
          // Chart reading guide for beginners
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to read this chart',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),
                _buildChartTip(
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF00C853),
                  text: 'Green candle/line rising indicates buying volume and upward momentum',
                ),
                _buildChartTip(
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFFF3B3B),
                  text: 'Red candle/line falling indicates selling pressure and downward correction',
                ),
                _buildChartTip(
                  icon: Icons.timeline_rounded,
                  color: const Color(0xFFFF8C00),
                  text: 'Orange dashed line is the 20-period Moving Average (MA20)',
                ),
                _buildChartTip(
                  icon: Icons.touch_app_rounded,
                  color: const Color(0xFF0066CC),
                  text: 'Tap or drag on chart for crosshair, OHLC details, zoom & pan',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTip({required IconData icon, required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8892A4), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global Header with Avatar & Live Pulse
              _buildHeader(),

              // Global Stock Search Bar
              _buildSearchBar(),

              // Search Overlay Results if searching
              if (_isSearching) _buildSearchResultsOverlay(),

              if (!_isSearching) ...[
                // Major Indian Market Indices
                _buildIndicesSection(),

                const SizedBox(height: 12),

                // Segmented Tabs: Overview | Watchlist | Stocks | Charts
                _buildSegmentedControl(),

                const SizedBox(height: 16),

                if (_selectedTab == 0) ...[
                  _buildStockDetailCard(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
                    child: MarketDepthWidget(currentPrice: _selectedStock.price),
                  ),
                  const SizedBox(height: 20),
                ] else if (_selectedTab == 1) ...[
                  _buildWatchlistTab(),
                ] else if (_selectedTab == 2) ...[
                  _buildStocksTab(),
                ] else if (_selectedTab == 3) ...[
                  _buildChartsTab(),
                ],

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDim.screenH, 16, AppDim.screenH, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Equity & Technical Command Center',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AnimatedPressCard(
            onTap: widget.onOpenProfile,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (StorageService.getUserDisplayName() ?? 'K')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA);
    final textColor = isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search symbol, company...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF8892A4),
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              icon: Icon(
                Icons.search_rounded,
                size: 20,
                color: _searchController.text.isNotEmpty
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF8892A4),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8892A4)),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA);
    final textColor = isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);

    if (_searchResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF8892A4)),
            const SizedBox(height: 12),
            Text(
              'No stocks found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF8892A4),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by company name or NSE symbol',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF8892A4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
        itemBuilder: (context, index) {
          final s = _searchResults[index];
          return AnimatedPressCard(
            onTap: () {
              setState(() {
                _selectedStock = s;
                _isSearching = false;
                _searchController.clear();
              });
              context.push('/stock-detail/${s.ticker}');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  TickerLogo(
                    ticker: s.ticker,
                    logoUrl: s.logoUrl,
                    logoColor: s.logoColor,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s.ticker,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066CC).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s.exchange,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF0066CC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.fullName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8892A4),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        s.priceFormatted,
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.changePercentFormatted,
                        style: GoogleFonts.inter(
                          color: s.isPositive
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF3B3B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildIndicesSection() {
    final tickerNotifier = provider.Provider.of<MarketTickerNotifier>(context);
    final rawIndices = tickerNotifier.indices;

    final indices = rawIndices.map((idx) {
      final double val = (idx['value'] as num).toDouble();
      final double chg = (idx['change'] as num).toDouble();
      final double chgPct = (idx['changePercent'] as num).toDouble();
      final bool up = idx['up'] as bool;

      final valStr = NumberFormat('#,##0.00', 'en_IN').format(val);
      final chgStr = '${up ? "+" : ""}₹${chg.toStringAsFixed(2)}';
      final pctStr = '(${up ? "+" : ""}${chgPct.toStringAsFixed(2)}%)';

      return {
        'name': idx['name'] as String,
        'value': valStr,
        'change': chgStr,
        'changePercent': pctStr,
        'up': up,
      };
    }).toList();

    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
        itemCount: indices.length,
        itemBuilder: (context, index) {
          final idx = indices[index];
          final isSelected = _selectedIndex == idx['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IndexCard(
              name: idx['name'] as String,
              value: idx['value'] as String,
              change: idx['change'] as String,
              changePercent: idx['changePercent'] as String,
              isPositive: idx['up'] as bool,
              isSelected: isSelected,
              onTap: () {
                setState(() => _selectedIndex = idx['name'] as String);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSegmentedControl() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
        ),
      ),
      child: Row(
        children: [
          _buildTab('Overview', 0),
          _buildTab('Watchlist', 1),
          _buildTab('Stocks', 2),
          _buildTab('Charts', 3),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTab = index;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildStockDetailCard() {
    final theme = Theme.of(context);
    final isWatched = _watchlistTickers.contains(_selectedStock.ticker);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDim.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Header Row & Bookmark Watchlist Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TickerLogo(
                ticker: _selectedStock.ticker,
                logoUrl: _selectedStock.logoUrl,
                logoColor: _selectedStock.logoColor,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedStock.ticker,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _selectedStock.exchange,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedStock.fullName,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Watchlist Bookmark Button with Press scale
              AnimatedPressCard(
                onTap: () => _toggleWatchlist(_selectedStock.ticker),
                child: Icon(
                  isWatched ? Icons.bookmark : Icons.bookmark_border,
                  color: isWatched ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Price & Change Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedStock.priceFormatted,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${_selectedStock.changeAmountFormatted} (${_selectedStock.changePercentFormatted})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedStock.isPositive ? AppColors.gain : AppColors.loss,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SignalBadge(signal: _selectedStock.aiSignal),
            ],
          ),

          const SizedBox(height: 20),

          // Chart Type Selector & Timeframe Controls
          ChartHeaderRow(
            periods: const ['1D', '1W', '1M', '3M', '6M', '1Y', '5Y', 'MAX'],
            selectedPeriod: _selectedTimeframe,
            onPeriodChanged: (tf) {
              setState(() => _selectedTimeframe = tf);
            },
            selectedType: ref.watch(chartPatternProvider),
            onTypeChanged: (newType) {
              ref.read(chartPatternProvider.notifier).setChartType(newType);
            },
          ),

          const SizedBox(height: 12),

          // Real Stock Chart (New Syncfusion trading-grade chart)
          RealStockChart(
            ticker: _selectedStock.ticker,
            period: _selectedTimeframe,
            chartType: ref.watch(chartPatternProvider),
            onChartTypeChanged: (newType) {
              ref.read(chartPatternProvider.notifier).setChartType(newType);
            },
            showHeader: false,
          ),

          const SizedBox(height: 18),

          // Educational Disclaimer (Replaces Buy/Sell order buttons)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0066CC).withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF0066CC), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TradeVision AI is a learning and analysis tool only. '
                    'To buy or sell shares, use your broker app (Zerodha, Groww, etc.)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF0066CC),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Technical Indicators Expandable Toggle with rotation animation
          AnimatedPressCard(
            onTap: () => setState(() => _showIndicators = !_showIndicators),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Technical Indicators (RSI, MACD, S/R)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _showIndicators ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showIndicators) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildIndicatorRow('RSI Momentum (RSI)', '${_selectedStock.rsi}', 'Normal (40-60)'),
                  Divider(height: 14, color: theme.dividerColor),
                  _buildIndicatorRow('Trend Direction (MACD)', _selectedStock.macd, 'Bullish Crossover'),
                  Divider(height: 14, color: theme.dividerColor),
                  _buildIndicatorRow('Support Zone (Floor)', _selectedStock.support, 'Key Buying Level'),
                  Divider(height: 14, color: theme.dividerColor),
                  _buildIndicatorRow('Target Zone (Ceiling)', _selectedStock.resistance, 'Target Level'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Market Statistics Grid
          Text(
            'Company Financial Metrics',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildStatCard('Company Size (Market Cap)', _selectedStock.marketCap),
              _buildStatCard('Price-to-Earnings (P/E)', _selectedStock.peRatio),
              _buildStatCard('1-Year Highest Price', _selectedStock.week52High),
              _buildStatCard('1-Year Lowest Price', _selectedStock.week52Low),
              _buildStatCard('Sector', _selectedStock.sector),
              _buildStatCard('ISIN', _selectedStock.isin),
            ],
          ),

          const SizedBox(height: 20),

          // AI Insight Explanation Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedStock.aiReason,
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildIndicatorRow(String name, String val, String sub) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
            Text(sub, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF8892A4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignalExplanation(BuildContext context, String signal) {
    final explanations = {
      'BUY': 'Our AI thinks this stock has a good chance of going up '
          'based on its chart pattern, RSI, and recent news. '
          'This is a suggestion — always do your own research.',
      'SELL': 'Our AI thinks this stock may go down based on its '
          'current pattern and indicators. '
          'This means it might not be the best time to hold it.',
      'HOLD': 'Our AI thinks this stock could go either way right now. '
          'It is best to wait and watch before making a decision.',
    };
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What does "$signal" mean?',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(explanations[signal] ?? explanations['HOLD']!,
                style: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF8892A4), height: 1.6)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF8C00), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is for learning only. TradeVision AI does not give '
                      'financial advice. Always consult a SEBI-registered advisor.',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFFF8C00),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
