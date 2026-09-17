import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/data/stock_data.dart';
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
    List<StockModel> filteredStocks = StockRepository.stocks;
    if (selectedFilter == 'Gainers') {
      filteredStocks = StockRepository.stocks.where((s) => s.isPositive).toList();
    } else if (selectedFilter == 'Losers') {
      filteredStocks = StockRepository.stocks.where((s) => !s.isPositive).toList();
    } else if (selectedFilter == '52W High') {
      filteredStocks = StockRepository.stocks.where((s) => s.changePercent > 1.0).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Equity & Technical Command Center',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Index Cards Horizontal List (Live Synchronized Stream)
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

              // Filter Chips
              FilterChipRow(
                options: const ['All', 'Gainers', 'Losers', '52W High'],
                selectedOption: selectedFilter,
                onSelected: (val) {
                  setState(() {
                    selectedFilter = val;
                  });
                },
              ),

              // Top Movers Header
              SectionHeader(
                title: 'Top Movers',
                actionText: '${filteredStocks.length} Stocks',
                onActionTap: () {},
              ),

              // Stock Rows
              Column(
                children: filteredStocks.map((stock) {
                  return StockRow(
                    ticker: stock.ticker,
                    fullName: stock.fullName,
                    price: stock.priceFormatted,
                    changePercent: stock.changePercentFormatted,
                    isPositive: stock.isPositive,
                    logoColor: stock.logoColor,
                    logoUrl: stock.logoUrl,
                    onTap: () {
                      if (widget.onSelectStock != null) widget.onSelectStock!(stock);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
