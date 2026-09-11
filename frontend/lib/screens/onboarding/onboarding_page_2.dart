import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/rsi_gauge_painter.dart';

class OnboardingPage2 extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingPage2({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = Theme.of(context).cardColor;
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF8892A4) : const Color(0xFF64748B);

    return Column(
      children: [
        // Illustration Area (Top Card)
        Container(
          height: 320,
          margin: EdgeInsets.fromLTRB(24, statusBarHeight + 40, 24, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Half: RSI Gauge
              const RsiGaugeWidget(value: 62.0),

              const Spacer(),

              // Bottom Half: MACD Histogram Bar Chart
              SizedBox(
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 12,
                        minY: -12,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _makeBarGroup(0, 4, true),
                          _makeBarGroup(1, 8, true),
                          _makeBarGroup(2, 6, true),
                          _makeBarGroup(3, -5, false),
                          _makeBarGroup(4, -8, false),
                          _makeBarGroup(5, 3, true),
                          _makeBarGroup(6, 9, true),
                          _makeBarGroup(7, 11, true),
                        ],
                      ),
                    ),
                    // Orange #FF6B00 Signal Line across bars
                    Positioned(
                      top: 36,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'MACD Histogram',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Text Section
        Text(
          'Technical\nIndicators',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'RSI, MACD, and Moving Averages explained in plain language — always know what the charts are telling you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: subtextColor,
              height: 1.4,
            ),
          ),
        ),

        const Spacer(),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, bool isPositive) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isPositive ? const Color(0xFF00C853) : const Color(0xFFFF3B3B),
          width: 14,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
