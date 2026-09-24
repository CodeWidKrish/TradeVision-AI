import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/data/stock_data.dart';
import '../services/api_service.dart';
import '../providers/market_data_provider.dart';
import '../widgets/index_card.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/section_header.dart';
import '../widgets/stock_row.dart';

class MarketScreen extends StatefulWidget {
  final Function(StockModel stock)? onSelectStock;

  const MarketScreen({
    super.key,
    this.onSelectStock,
  });

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String selectedFilter = 'All';
  String selectedSector = 'All';
  List<String> _sectors = ['All'];

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  List<StockModel> _searchResults = [];

  List<StockModel> _universeStocks = [];
  bool _isLoadingUniverse = false;

  @override
  void initState() {
    super.initState();
    _universeStocks = StockRepository.getUniverse(limit: 150);
    _sectors = StockRepository.getAllSectors();
    _loadSectors();
    _loadUniverse();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSectors() async {
    try {
      final list = await ApiService.fetchSectors();
      if (list.isNotEmpty && mounted) {
        setState(() {
          _sectors = ['All', ...list];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUniverse({String? sector}) async {
    setState(() => _isLoadingUniverse = true);
    try {
      final items = await ApiService.fetchStocksUniverse(
        limit: 150,
        sector: (sector != null && sector != 'All') ? sector : null,
      );
      if (mounted) {
        final models = items.isNotEmpty
            ? items.map((json) => StockModel.fromMasterJson(json)).toList()
            : StockRepository.getUniverse(sector: sector, limit: 150);
        setState(() {
          _universeStocks = models;
          _isLoadingUniverse = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _universeStocks = StockRepository.getUniverse(sector: sector, limit: 150);
          _isLoadingUniverse = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _isLoadingSearch = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
      _searchResults = StockRepository.searchStocks(q);
    });

    _debounceTimer = Timer(const Duration(milliseconds: 120), () async {
      try {
        final serverResults = await ApiService.searchStocks(q, limit: 30);
        if (!mounted || _searchController.text.trim() != q) return;

        if (serverResults.isNotEmpty) {
          final models = serverResults.map((item) {
            final model = StockModel.fromMasterJson(item);
            StockRepository.registerStock(model);
            return model;
          }).toList();
          setState(() {
            _searchResults = models;
            _isLoadingSearch = false;
          });
        } else {
          setState(() => _isLoadingSearch = false);
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingSearch = false);
      }
    });
  }

  Widget _buildDefaultIndexCards() {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
      child: Row(
        children: [
          IndexCard(
            name: 'NIFTY 50',
            value: '23,242.40',
            change: '+24.80 (+0.11%)',
            isPositive: true,
          ),
          SizedBox(width: 10),
          IndexCard(
            name: 'SENSEX',
            value: '74,336.45',
            change: '+332.63 (+0.45%)',
            isPositive: true,
          ),
          SizedBox(width: 10),
          IndexCard(
            name: 'NIFTY BANK',
            value: '56,262.40',
            change: '-30.05 (-0.05%)',
            isPositive: false,
          ),
          SizedBox(width: 10),
          IndexCard(
            name: 'NIFTY IT',
            value: '28,833.05',
            change: '-254.60 (-0.88%)',
            isPositive: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA);
    final textColor = isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);

    List<StockModel> displayStocks = _universeStocks.isNotEmpty
        ? _universeStocks
        : StockRepository.getUniverse(sector: selectedSector, limit: 150);

    if (selectedFilter == 'Gainers') {
      displayStocks = displayStocks.where((s) => s.isPositive).toList()
        ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    } else if (selectedFilter == 'Losers') {
      displayStocks = displayStocks.where((s) => !s.isPositive).toList()
        ..sort((a, b) => a.changePercent.compareTo(b.changePercent));
    } else if (selectedFilter == '52W High') {
      displayStocks = displayStocks.where((s) => s.changePercent > 1.0).toList()
        ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Market',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '2,595+ NSE/BSE Listed Equities',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, color: Color(0xFF00C853), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'LIVE NSE FEED',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.0),
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
                      hintText: 'Search',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8892A4),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
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
                          : (_isLoadingSearch
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null),
                    ),
                  ),
                ),
              ),

              // Search Overlay or Regular Content
              if (_isSearching) ...[
                if (_searchResults.isEmpty && !_isLoadingSearch)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 16),
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF8892A4)),
                        const SizedBox(height: 10),
                        Text(
                          'No stocks found for "${_searchController.text}"',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8892A4)),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
                        child: Text(
                          'SEARCH RESULTS (${_searchResults.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8892A4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      ..._searchResults.map((stock) {
                        return StockRow(
                          ticker: stock.ticker,
                          fullName: stock.fullName,
                          price: stock.priceFormatted,
                          changePercent: stock.changePercentFormatted,
                          isPositive: stock.isPositive,
                          logoColor: stock.logoColor,
                          logoUrl: stock.logoUrl,
                          onTap: () {
                            StockRepository.registerStock(stock);
                            if (widget.onSelectStock != null) {
                              widget.onSelectStock!(stock);
                            }
                          },
                        );
                      }),
                    ],
                  ),
              ] else ...[
                const SizedBox(height: 8),

                // Index Cards Horizontal List
                Consumer(
                  builder: (context, ref, _) {
                    final indicesAsync = ref.watch(indicesProvider);
                    return indicesAsync.when(
                      data: (indices) {
                        final items = indices.isNotEmpty ? indices : null;
                        if (items == null) return _buildDefaultIndexCards();

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDim.screenH, vertical: 8),
                          child: Row(
                            children: items.map((item) {
                              final sign = item.change >= 0 ? '+' : '';
                              final changeStr =
                                  '$sign${item.change.toStringAsFixed(2)} ($sign${item.changePercent.toStringAsFixed(2)}%)';
                              final valStr =
                                  NumberFormat('#,##0.00').format(item.price);
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: IndexCard(
                                  name: item.name,
                                  value: valStr,
                                  change: changeStr,
                                  isPositive: item.isPositive,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => _buildDefaultIndexCards(),
                      error: (_, __) => _buildDefaultIndexCards(),
                    );
                  },
                ),

                // Primary Mover Filter Chips
                FilterChipRow(
                  options: const ['All', 'Gainers', 'Losers', '52W High'],
                  selectedOption: selectedFilter,
                  onSelected: (val) {
                    setState(() {
                      selectedFilter = val;
                    });
                  },
                ),

                // Sector Filter Chips
                if (_sectors.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 4),
                    child: Row(
                      children: _sectors.map((sec) {
                        final isSelected = selectedSector == sec;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sec),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0066CC),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            backgroundColor: cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: isSelected ? const Color(0xFF0066CC) : borderColor),
                            ),
                            onSelected: (_) {
                              setState(() {
                                selectedSector = sec;
                                _universeStocks = StockRepository.getUniverse(sector: sec, limit: 150);
                              });
                              _loadUniverse(sector: sec);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Top Movers Header
                SectionHeader(
                  title: selectedSector == 'All' ? 'Market Equities' : '$selectedSector Equities',
                  actionText: '${displayStocks.length} Stocks',
                  onActionTap: () {},
                ),

                if (_isLoadingUniverse && _universeStocks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  // Stock Rows
                  Column(
                    children: displayStocks.map((stock) {
                      return StockRow(
                        ticker: stock.ticker,
                        fullName: stock.fullName,
                        price: stock.priceFormatted,
                        changePercent: stock.changePercentFormatted,
                        isPositive: stock.isPositive,
                        logoColor: stock.logoColor,
                        logoUrl: stock.logoUrl,
                        onTap: () {
                          StockRepository.registerStock(stock);
                          if (widget.onSelectStock != null) {
                            widget.onSelectStock!(stock);
                          }
                        },
                      );
                    }).toList(),
                  ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
