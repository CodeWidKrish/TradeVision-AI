import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/models/ohlc_point.dart';
import 'candlestick_painter.dart';
import 'empty_state_widget.dart';

class InteractiveStockChart extends StatefulWidget {
  final List<OhlcPoint> rawData;
  final ChartType chartType;
  final String period;
  final double currentPrice;

  const InteractiveStockChart({
    super.key,
    required this.rawData,
    required this.chartType,
    required this.period,
    required this.currentPrice,
  });

  @override
  State<InteractiveStockChart> createState() => _InteractiveStockChartState();
}

class _InteractiveStockChartState extends State<InteractiveStockChart> {
  int? _highlightedIndex;
  bool _dismissWarning = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sanitized = OhlcSanitizer.sanitize(widget.rawData);

    if (sanitized.data.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: EmptyStateWidget(
          icon: Icons.show_chart_rounded,
          title: 'No chart data',
          subtitle: sanitized.warning ?? 'Try a different time range.',
        ),
      );
    }

    final points = sanitized.data;

    // Calculate Y-axis bounds with padding
    double minP = points.map((p) => p.low).reduce((a, b) => a < b ? a : b);
    double maxP = points.map((p) => p.high).reduce((a, b) => a > b ? a : b);

    if ((maxP - minP).abs() < 0.0001) {
      minP = minP * 0.98;
      maxP = maxP * 1.02;
    } else {
      final range = maxP - minP;
      minP = minP - range * 0.05;
      maxP = maxP + range * 0.05;
    }

    final currencyFormatter = NumberFormat('₹#,##,##0.00', 'en_IN');
    final activePoint =
        _highlightedIndex != null && _highlightedIndex! < points.length
            ? points[_highlightedIndex!]
            : points.last;

    return Column(
      children: [
        // Data quality warning banner if items were skipped
        if (sanitized.warning != null && !_dismissWarning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFFF8C00)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sanitized.warning!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF8C00),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _dismissWarning = true),
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: Color(0xFFFF8C00)),
                  ),
                ],
              ),
            ),
          ),

        // Interactive Tooltip Bar
        if (_highlightedIndex != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF0066CC).withValues(alpha: 0.25),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(activePoint.time),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8892A4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildOhlcTag('O', currencyFormatter.format(activePoint.open), isDark),
                  const SizedBox(width: 8),
                  _buildOhlcTag('H', currencyFormatter.format(activePoint.high), isDark, color: const Color(0xFF00C853)),
                  const SizedBox(width: 8),
                  _buildOhlcTag('L', currencyFormatter.format(activePoint.low), isDark, color: const Color(0xFFFF3B3B)),
                  const SizedBox(width: 8),
                  _buildOhlcTag('C', currencyFormatter.format(activePoint.close), isDark),
                ],
              ),
            ),
          ),

        // Chart View Container with AnimatedSwitcher
        SizedBox(
          height: 200,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(widget.chartType),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: switch (widget.chartType) {
                  ChartType.line => _buildLineChart(points, minP, maxP, isDark),
                  ChartType.candlestick => _buildCustomChart(
                      points,
                      minP,
                      maxP,
                      isDark,
                      (data, minVal, maxVal, idx) => CandlestickPainter(
                        data: data,
                        minPrice: minVal,
                        maxPrice: maxVal,
                        highlightedIndex: idx,
                      ),
                    ),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOhlcTag(String label, String val, bool isDark, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF8892A4),
                fontWeight: FontWeight.w600)),
        Text(
          val,
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color ??
                (isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E)),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(
      List<OhlcPoint> points, double minP, double maxP, bool isDark) {
    final isPositive = points.last.close >= points.first.open;
    final color =
        isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B);

    return LineChart(
      LineChartData(
        minY: minP,
        maxY: maxP,
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
              final idx = response.lineBarSpots!.first.spotIndex;
              if (_highlightedIndex != idx) {
                setState(() => _highlightedIndex = idx);
              }
            } else if (!event.isInterestedForInteractions) {
              setState(() => _highlightedIndex = null);
            }
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              points.length,
              (i) => FlSpot(i.toDouble(), points[i].close),
            ),
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              getTitlesWidget: (value, _) => Text(
                NumberFormat('₹#,###', 'en_IN').format(value),
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  color: const Color(0xFF8892A4),
                ),
              ),
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCustomChart(
    List<OhlcPoint> points,
    double minP,
    double maxP,
    bool isDark,
    CustomPainter Function(
            List<OhlcPoint> data, double minVal, double maxVal, int? idx)
        painterBuilder,
  ) {
    return GestureDetector(
      onPanUpdate: (details) => _handleTouch(details.localPosition, points),
      onTapDown: (details) => _handleTouch(details.localPosition, points),
      onPanEnd: (_) => setState(() => _highlightedIndex = null),
      child: Stack(
        children: [
          // Grid lines
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (_) => Container(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF1E2733).withValues(alpha: 0.5)
                      : const Color(0xFFE2E6EA),
                ),
              ),
            ),
          ),

          // Custom Painter
          CustomPaint(
            size: Size.infinite,
            painter: painterBuilder(points, minP, maxP, _highlightedIndex),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset position, List<OhlcPoint> points) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final width = box.size.width;
    if (width <= 0 || points.isEmpty) return;

    final slotWidth = width / points.length;
    final index = (position.dx / slotWidth).floor().clamp(0, points.length - 1);
    if (_highlightedIndex != index) {
      setState(() => _highlightedIndex = index);
    }
  }
}
