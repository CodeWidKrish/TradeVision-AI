import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rpod;
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/data/stock_data.dart';
import '../core/models/ohlc_point.dart';
import '../core/providers/portfolio_provider.dart';
import '../core/providers/chart_pattern_provider.dart';
import '../widgets/ai_insight_strip.dart';
import '../widgets/ticker_logo.dart';
import '../widgets/chart_type_selector.dart';
import '../widgets/interactive_stock_chart.dart';
import '../widgets/real_stock_chart.dart';
import '../widgets/swipe_to_execute_button.dart';

class ChartScreen extends rpod.ConsumerStatefulWidget {
  final StockModel stock;
  final VoidCallback? onBack;

  const ChartScreen({
    super.key,
    required this.stock,
    this.onBack,
  });

  @override
  rpod.ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends rpod.ConsumerState<ChartScreen> {
  String selectedRange = '1W';
  bool showRsi = false;
  bool showMacd = false;
  bool showVolume = false;

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final ranges = ['1D', '1W', '1M', '3M', '1Y'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDim.screenH, 12, AppDim.screenH, 0),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: widget.onBack,
                      ),
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
                            stock.ticker,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stock.fullName} — ${stock.exchange}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Consumer<PortfolioProvider>(
                      builder: (context, portfolio, child) {
                        final isStarred = portfolio.isWatchlisted(stock.ticker);
                        return IconButton(
                          icon: Icon(
                            isStarred ? Icons.star : Icons.star_border,
                            color: isStarred ? AppColors.warning : AppColors.textMuted,
                          ),
                          onPressed: () {
                            portfolio.toggleWatchlist(stock);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isStarred
                                      ? 'Removed ${stock.ticker} from Watchlist'
                                      : 'Added ${stock.ticker} to Watchlist',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Price row
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDim.screenH, 10, AppDim.screenH, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      stock.priceFormatted,
                      style: AppTextStyles.chartPrice,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: stock.isPositive ? AppColors.gainBg : AppColors.lossBg,
                        borderRadius: BorderRadius.circular(AppDim.radiusPill),
                      ),
                      child: Text(
                        stock.changePercentFormatted,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: stock.isPositive ? AppColors.gain : AppColors.loss,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Uniform Chart Header Row (Timeframe pills + Line / Candlestick toggle)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 8),
                child: ChartHeaderRow(
                  periods: const ['1D', '1W', '1M', '3M', '1Y', '5Y', 'MAX'],
                  selectedPeriod: selectedRange,
                  onPeriodChanged: (r) => setState(() => selectedRange = r),
                  selectedType: ref.watch(chartPatternProvider),
                  onTypeChanged: (newType) {
                    ref.read(chartPatternProvider.notifier).setChartType(newType);
                  },
                ),
              ),

              // Main Price Chart (Real Syncfusion trading-grade chart)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RealStockChart(
                  ticker: stock.ticker,
                  period: selectedRange,
                  chartType: ref.watch(chartPatternProvider),
                  onChartTypeChanged: (newType) {
                    ref.read(chartPatternProvider.notifier).setChartType(newType);
                  },
                  showHeader: false,
                ),
              ),

              const SizedBox(height: 8),

              // Technical Indicators Panel Toggle Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildIndicatorChip('RSI', showRsi, () {
                        setState(() => showRsi = !showRsi);
                      }),
                      const SizedBox(width: 8),
                      _buildIndicatorChip('MACD', showMacd, () {
                        setState(() => showMacd = !showMacd);
                      }),
                      const SizedBox(width: 8),
                      _buildIndicatorChip('Volume', showVolume, () {
                        setState(() => showVolume = !showVolume);
                      }),
                    ],
                  ),
                ),
              ),

              // Sub-charts
              if (showRsi) _buildRsiSubChart(stock),
              if (showMacd) _buildMacdSubChart(stock),
              if (showVolume) _buildVolumeSubChart(stock),

              // AI Insight strip
              AiInsightStrip(
                text: stock.aiReason,
              ),

              // Buy / Sell Action Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppDim.btnHeight,
                        child: ElevatedButton(
                          onPressed: () => _openOrderModal(context, isBuy: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDim.radiusMd),
                            ),
                          ),
                          child: const Text(
                            'Buy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: AppDim.btnHeight,
                        child: OutlinedButton(
                          onPressed: () => _openOrderModal(context, isBuy: false),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.loss, width: 1.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDim.radiusMd),
                            ),
                          ),
                          child: const Text(
                            'Sell',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.loss,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.borderStrong),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRsiSubChart(StockModel stock) {
    final spots = stock.rsiData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 2,
            left: 4,
            child: Text(
              'RSI (14)',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      if (val == 30 || val == 70) {
                        return Text('${val.toInt()}', style: const TextStyle(fontSize: 8, color: AppColors.textMuted));
                      }
                      return const SizedBox();
                    },
                    reservedSize: 20,
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(y: 70, color: AppColors.loss.withAlpha(150), strokeWidth: 1, dashArray: [4, 4]),
                  HorizontalLine(y: 30, color: AppColors.gain.withAlpha(150), strokeWidth: 1, dashArray: [4, 4]),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF7C3AED),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacdSubChart(StockModel stock) {
    final macdSpots = stock.macdLine
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final signalSpots = stock.signalLine
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 2,
            left: 4,
            child: Text(
              'MACD',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(y: 0, color: AppColors.textMuted.withAlpha(100), strokeWidth: 1, dashArray: [4, 4]),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: macdSpots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: signalSpots,
                  isCurved: true,
                  color: AppColors.warning,
                  barWidth: 1.5,
                  dashArray: [4, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSubChart(StockModel stock) {
    final barGroups = stock.volumeData.asMap().entries.map((e) {
      final isUp = e.key % 2 == 0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value,
            color: isUp ? AppColors.gain : AppColors.loss,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 2,
            left: 4,
            child: Text(
              'Volume',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ],
      ),
    );
  }

  void _openOrderModal(BuildContext context, {required bool isBuy}) {
    final controller = TextEditingController(text: '1');
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final totalValue = widget.stock.price * quantity;
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
                  padding: EdgeInsets.fromLTRB(
                    AppDim.screenH,
                    16,
                    AppDim.screenH,
                    bottomPadding + 14,
                  ),
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
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Paper Trading Simulation Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066CC).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0066CC).withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066CC).withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Color(0xFF0066CC),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'PAPER TRADING • SIMULATION',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0066CC),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0066CC).withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ZERO RISK',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0066CC),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Virtual Cash: ₹5,00,000.00 • Practice Trading',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              TickerLogo(
                                ticker: widget.stock.ticker,
                                logoUrl: widget.stock.logoUrl,
                                logoColor: widget.stock.logoColor,
                                size: 32,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${isBuy ? "Buy" : "Sell"} ${widget.stock.ticker}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isBuy ? AppColors.primary : AppColors.loss,
                                    ),
                                  ),
                                  Text(
                                    '${widget.stock.exchange} • ${widget.stock.priceFormatted}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      const Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setModalState(() {
                              quantity = parsed;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Value', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          Text(
                            StockModel.formatINR(totalValue),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SwipeToExecuteButton(
                        isBuy: isBuy,
                        stockTicker: widget.stock.ticker,
                        priceFormatted: StockModel.formatINR(totalValue),
                        quantity: quantity,
                        onConfirmed: () {
                          final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
                          if (isBuy) {
                            portfolio.buyStock(widget.stock, quantity);
                          } else {
                            portfolio.sellStock(widget.stock, quantity);
                          }
                          Future.delayed(const Duration(milliseconds: 1400), () {
                            if (Navigator.canPop(ctx)) {
                              Navigator.pop(ctx);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${isBuy ? "Bought" : "Sold"} $quantity shares of ${widget.stock.ticker} at ${widget.stock.priceFormatted}',
                                ),
                                backgroundColor: isBuy ? AppColors.gain : AppColors.loss,
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
}
