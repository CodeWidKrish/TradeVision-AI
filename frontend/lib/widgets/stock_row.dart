import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/dark_surfaces.dart';
import 'ticker_logo.dart';
import 'mini_sparkline.dart';

class StockRow extends StatelessWidget {
  final String ticker;
  final String fullName;
  final String price;
  final String changePercent;
  final bool isPositive;
  final Color logoColor;
  final String logoUrl;
  final VoidCallback onTap;

  const StockRow({
    super.key,
    required this.ticker,
    required this.fullName,
    required this.price,
    required this.changePercent,
    required this.isPositive,
    required this.logoColor,
    this.logoUrl = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA);
    final primaryTextColor = isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF0066CC).withOpacity(0.08),
          highlightColor: const Color(0xFF0066CC).withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                TickerLogo(
                  ticker: ticker,
                  logoUrl: logoUrl,
                  logoColor: logoColor,
                  size: 40,
                  heroTag: 'stock-logo-$ticker',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticker,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: DarkSurface.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MiniSparkline(
                  isGain: isPositive,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        price,
                        style: GoogleFonts.robotoMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      changePercent,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? const Color(0xFF00C853)
                            : const Color(0xFFFF3B3B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
