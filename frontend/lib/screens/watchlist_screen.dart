import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/data/stock_data.dart';
import '../core/providers/watchlist_provider.dart';
import '../widgets/ticker_logo.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedSymbols = ref.watch(watchlistProvider);
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');

    final allWatchlistStocks = StockRepository.stocks
        .where((s) => savedSymbols.contains(s.ticker.toUpperCase()))
        .toList();

    final filteredStocks = _searchQuery.isEmpty
        ? allWatchlistStocks
        : allWatchlistStocks.where((s) {
            final q = _searchQuery.trim().toLowerCase();
            return s.ticker.toLowerCase().contains(q) ||
                s.fullName.toLowerCase().contains(q);
          }).toList();

    final upCount = allWatchlistStocks.where((s) => s.isPositive).length;
    final downCount = allWatchlistStocks.length - upCount;

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
          'My Watchlist (${allWatchlistStocks.length})',
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
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E2733)
                      : const Color(0xFFE2E6EA),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Color(0xFF8892A4), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(
                            () => _searchQuery = v.toLowerCase().trim()),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFE8ECF0)
                              : const Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search stocks by name or symbol...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF8892A4),
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFF8892A4), size: 16),
                      ),
                  ],
                ),
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${allWatchlistStocks.length} stocks',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF8892A4),
                    ),
                  ),
                  const Spacer(),
                  // Gainers count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$upCount up today',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$downCount down today',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF3B3B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stock list or empty state
            Expanded(
              child: filteredStocks.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                color: Color(0xFF8892A4), size: 40),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No stocks found for "$_searchQuery"'
                                  : 'No stocks in watchlist',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF8892A4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try searching by company name or NSE symbol'
                                  : 'Tap the bookmark icon on any stock to add it here',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8892A4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredStocks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = filteredStocks[i];
                        final signalColor = switch (s.aiSignal.toUpperCase()) {
                          'BUY' => const Color(0xFF00C853),
                          'SELL' => const Color(0xFFFF3B3B),
                          _ => const Color(0xFFFF8C00),
                        };

                        return Dismissible(
                          key: Key(s.ticker),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B3B),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 24),
                          ),
                          onDismissed: (_) {
                            HapticFeedback.lightImpact();
                            watchlistNotifier.removeSymbol(s.ticker);
                          },
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/stock-detail/${s.ticker}');
                            },
                            child: Container(
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
                              child: Row(
                                children: [
                                  TickerLogo(
                                    ticker: s.ticker,
                                    logoUrl: s.logoUrl,
                                    logoColor: s.logoColor,
                                    size: 40,
                                    heroTag: 'watchlist-logo-${s.ticker}',
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.ticker,
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
                                          s.fullName,
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
                                          currencyFormatter.format(s.price),
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
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (s.isPositive
                                                      ? const Color(0xFF00C853)
                                                      : const Color(0xFFFF3B3B))
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${s.isPositive ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: s.isPositive
                                                    ? const Color(0xFF00C853)
                                                    : const Color(0xFFFF3B3B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: signalColor.withValues(
                                                  alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: signalColor.withValues(
                                                    alpha: 0.30),
                                              ),
                                            ),
                                            child: Text(
                                              s.aiSignal,
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
