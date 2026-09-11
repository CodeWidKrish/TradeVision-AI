import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage1 extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingPage1({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = Theme.of(context).cardColor;
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final chipBg = isDark ? const Color(0xFF0A0E1A).withOpacity(0.85) : const Color(0xFFF8FAFC);
    final chipBorder = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF8892A4) : const Color(0xFF64748B);
    final gridLineColor = isDark ? const Color(0xFF1E2A3A) : const Color(0xFFF1F5F9);

    return Column(
      children: [
        // Illustration Area (Top Card)
        Container(
          height: 320,
          margin: EdgeInsets.fromLTRB(24, statusBarHeight + 40, 24, 0),
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
          child: Stack(
            children: [
              // NIFTY 50 Top-Left Chip Card Overlay
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: chipBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NIFTY 50',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '22,418',
                            style: GoogleFonts.robotoMono(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+0.56%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00C853),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Line Chart
              Positioned.fill(
                top: 80,
                bottom: 16,
                left: 12,
                right: 16,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: gridLineColor,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                color: subtextColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 5,
                    minY: 22000,
                    maxY: 22600,
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 22100),
                          FlSpot(1, 22350),
                          FlSpot(2, 22220),
                          FlSpot(3, 22480),
                          FlSpot(4, 22390),
                          FlSpot(5, 22560),
                        ],
                        isCurved: true,
                        color: const Color(0xFF0066CC),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0066CC).withOpacity(0.3),
                              const Color(0xFF0066CC).withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Text Section
        Text(
          'Understand\nthe Market',
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
            'Get real-time insights on stocks, indices, and trends with AI analysis designed for complete beginners.',
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
}
