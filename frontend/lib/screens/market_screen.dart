import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/data/stock_data.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.fromLTRB(AppDim.screenH, 16, AppDim.screenH, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Market Command Center',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Index Cards Horizontal List
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
                child: Row(
                  children: [
                    IndexCard(
                      name: 'NIFTY 50',
                      value: '24,613',
                      change: '+178 +0.73%',
                      isPositive: true,
                    ),
                    const SizedBox(width: 10),
                    IndexCard(
                      name: 'SENSEX',
                      value: '81,042',
                      change: '+412 +0.51%',
                      isPositive: true,
                    ),
                    const SizedBox(width: 10),
                    IndexCard(
                      name: 'NIFTY BANK',
                      value: '52,310',
                      change: '-92 -0.17%',
                      isPositive: false,
                    ),
                    const SizedBox(width: 10),
                    IndexCard(
                      name: 'NIFTY IT',
                      value: '38,940',
                      change: '+245 +0.63%',
                      isPositive: true,
                    ),
                  ],
                ),
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
