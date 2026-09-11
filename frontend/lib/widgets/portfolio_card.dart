import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/dark_surfaces.dart';

class PortfolioCard extends StatelessWidget {
  final double totalValue;
  final double todayChangeAmount;
  final double todayChangePercent;
  final double investedAmount;
  final double returnsAmount;
  final double returnsPercent;

  const PortfolioCard({
    super.key,
    this.totalValue = 481090.00,
    this.todayChangeAmount = 3210.00,
    this.todayChangePercent = 0.67,
    this.investedAmount = 410000.00,
    this.returnsAmount = 71090.00,
    this.returnsPercent = 17.3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTodayPositive = todayChangeAmount >= 0;
    final isReturnsPositive = returnsAmount >= 0;
    final currencyFormatter = NumberFormat('#,##,##0', 'en_IN');

    Widget buildSparkline(Color sparkColor) {
      return SizedBox(
        height: 36,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 460000),
                  FlSpot(1, 455000),
                  FlSpot(2, 468000),
                  FlSpot(3, 471000),
                  FlSpot(4, 469000),
                  FlSpot(5, 478000),
                  FlSpot(6, 481090),
                ],
                isCurved: true,
                color: sparkColor.withValues(alpha: 0.75),
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      sparkColor.withValues(alpha: 0.18),
                      sparkColor.withValues(alpha: 0.00),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      );
    }

    if (isDark) {
      // Dark Mode Elevation Level 2 — Dark Blue-Grey Card with Subtle Blue Border Accent
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DarkSurface.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0066CC).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Total Portfolio Value',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: DarkSurface.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₹${currencyFormatter.format(totalValue.toInt())}',
                style: GoogleFonts.robotoMono(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: DarkSurface.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isTodayPositive
                    ? const Color(0xFF00C853).withValues(alpha: 0.12)
                    : const Color(0xFFFF3B3B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${isTodayPositive ? "+" : "-"}₹${currencyFormatter.format(todayChangeAmount.abs().toInt())} (${isTodayPositive ? "+" : ""}${todayChangePercent.toStringAsFixed(2)}%) today',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isTodayPositive
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3B3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildSparkline(const Color(0xFF00C853)),
            const SizedBox(height: 4),
            Text(
              '7-day portfolio trend',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: DarkSurface.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: DarkSurface.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  'Invested',
                  '₹${currencyFormatter.format(investedAmount.toInt())}',
                  DarkSurface.textMuted,
                ),
                _buildVerticalDivider(),
                _buildStatItem(
                  'Returns',
                  '${isReturnsPositive ? "+" : "-"}₹${currencyFormatter.format(returnsAmount.abs().toInt())}',
                  isReturnsPositive
                      ? const Color(0xFF00C853)
                      : const Color(0xFFFF3B3B),
                ),
                _buildVerticalDivider(),
                _buildStatItem(
                  'P&L %',
                  '${isReturnsPositive ? "+" : ""}${returnsPercent.toStringAsFixed(1)}%',
                  isReturnsPositive
                      ? const Color(0xFF00C853)
                      : const Color(0xFFFF3B3B),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Light Mode — Royal Blue Gradient Card
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066CC), Color(0xFF0044AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066CC).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Portfolio Value',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${currencyFormatter.format(totalValue.toInt())}',
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${isTodayPositive ? "+" : "-"}₹${currencyFormatter.format(todayChangeAmount.abs().toInt())} (${isTodayPositive ? "+" : ""}${todayChangePercent.toStringAsFixed(2)}%) today',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          buildSparkline(Colors.white),
          const SizedBox(height: 4),
          Text(
            '7-day portfolio trend',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('Invested', '₹${currencyFormatter.format(investedAmount.toInt())}', Colors.white),
              _buildVerticalDivider(),
              _buildStatItem('Returns', '${isReturnsPositive ? "+" : "-"}₹${currencyFormatter.format(returnsAmount.abs().toInt())}', Colors.white),
              _buildVerticalDivider(),
              _buildStatItem('P&L %', '${isReturnsPositive ? "+" : ""}${returnsPercent.toStringAsFixed(1)}%', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF8892A4),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.robotoMono(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: DarkSurface.border,
    );
  }
}
