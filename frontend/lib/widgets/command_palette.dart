import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/data/stock_data.dart';
import '../core/theme/dark_surfaces.dart';
import 'ticker_logo.dart';

class CommandPalette extends StatefulWidget {
  final Function(StockModel)? onSelectStock;

  const CommandPalette({super.key, this.onSelectStock});

  static void show(BuildContext context, {Function(StockModel)? onSelectStock}) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return CommandPalette(onSelectStock: onSelectStock);
      },
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'AI Strong Buy', 'Top Gainers', 'Banking', 'IT', 'Energy'];

  List<StockModel> _filteredStocks = [];

  @override
  void initState() {
    super.initState();
    _filteredStocks = List.from(StockRepository.stocks);
    _searchController.addListener(_applyFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredStocks = StockRepository.stocks.where((stock) {
        final matchesQuery = query.isEmpty ||
            stock.ticker.toLowerCase().contains(query) ||
            stock.name.toLowerCase().contains(query) ||
            stock.sector.toLowerCase().contains(query);

        if (!matchesQuery) return false;

        switch (_selectedFilter) {
          case 'AI Strong Buy':
            return stock.aiRecommendation.toUpperCase().contains('BUY');
          case 'Top Gainers':
            return stock.change >= 0;
          case 'Banking':
            return stock.sector.toLowerCase().contains('bank') ||
                stock.sector.toLowerCase().contains('financial');
          case 'IT':
            return stock.sector.toLowerCase().contains('technology') ||
                stock.sector.toLowerCase().contains('it');
          case 'Energy':
            return stock.sector.toLowerCase().contains('energy') ||
                stock.sector.toLowerCase().contains('oil');
          default:
            return true;
        }
      }).toList();
    });
  }

  void _onStockTapped(StockModel stock) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    if (widget.onSelectStock != null) {
      widget.onSelectStock!(stock);
    } else {
      context.push('/stock/${stock.ticker}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF142033) : const Color(0xFFF8FAFC);
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 680 ? 620.0 : size.width * 0.94;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: size.height * 0.78,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                  : const Color(0xFF0066CC).withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF0066CC), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search symbol, sector, or company (e.g. RELIANCE, Banking)...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: DarkSurface.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                        child: Icon(Icons.cancel_rounded, size: 18, color: DarkSurface.textMuted),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ESC',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1, color: border),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedFilter = f;
                          });
                          _applyFilter();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0066CC)
                                : isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0066CC)
                                  : isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              Divider(height: 1, thickness: 1, color: border),

              // Results List
              Flexible(
                child: _filteredStocks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: DarkSurface.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No matching instruments found',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: DarkSurface.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _filteredStocks.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: border.withValues(alpha: 0.5)),
                        itemBuilder: (context, index) {
                          final stock = _filteredStocks[index];
                          final isPositive = stock.change >= 0;
                          final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                          return InkWell(
                            onTap: () => _onStockTapped(stock),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                   // Ticker Logo
                                   TickerLogo(
                                     ticker: stock.ticker,
                                     logoUrl: stock.logoUrl,
                                     logoColor: stock.logoColor,
                                     size: 44,
                                   ),
                                   const SizedBox(width: 12),

                                  // Name & Sector
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              stock.ticker,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                stock.aiRecommendation,
                                                style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF38BDF8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${stock.name} • ${stock.sector}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: DarkSurface.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Price & Change
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${stock.price.toStringAsFixed(2)}',
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${isPositive ? '+' : ''}${stock.changePercentage.toStringAsFixed(2)}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: changeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.chevron_right_rounded, size: 18, color: DarkSurface.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              Divider(height: 1, thickness: 1, color: border),

              // Footer Quick Tip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Press stock to open deep analytical charts',
                      style: GoogleFonts.inter(fontSize: 10, color: DarkSurface.textMuted),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'NSE Live Engine',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
