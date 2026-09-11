import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RsiGaugePainter extends CustomPainter {
  final double value; // 0 to 100
  final bool isDark;

  RsiGaugePainter({
    this.value = 62.0,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = min(size.width / 2 - 16, size.height * 0.75);

    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track Background Arc
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = isDark ? const Color(0xFF1E2A3A) : const Color(0xFFE2E8F0);

    canvas.drawArc(rect, pi, pi, false, trackPaint);

    // Zone Arcs:
    // 0 to 30: Red #FF3B3B
    // 30 to 70: Yellow #FFB300
    // 70 to 100: Red #FF3B3B

    final oversoldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFFF3B3B);

    final neutralPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFFFB300);

    final overboughtPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFFF3B3B);

    // Draw 0-30 (30% of pi)
    canvas.drawArc(rect, pi, pi * 0.30, false, oversoldPaint);

    // Draw 30-70 (40% of pi)
    canvas.drawArc(rect, pi + (pi * 0.30), pi * 0.40, false, neutralPaint);

    // Draw 70-100 (30% of pi)
    canvas.drawArc(rect, pi + (pi * 0.70), pi * 0.30, false, overboughtPaint);

    // Draw Needle
    final clampedVal = value.clamp(0.0, 100.0);
    final needleAngle = pi + (clampedVal / 100.0) * pi;
    final needleLength = radius - 10;

    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pinPaint = Paint()..color = needleColor;

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, pinPaint);
  }

  @override
  bool shouldRepaint(covariant RsiGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isDark != isDark;
  }
}

class RsiGaugeWidget extends StatelessWidget {
  final double value;

  const RsiGaugeWidget({
    super.key,
    this.value = 62.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF8892A4) : const Color(0xFF64748B);

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 140),
            painter: RsiGaugePainter(value: value, isDark: isDark),
          ),
          Positioned(
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RSI · Neutral',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          // Zone labels at bottom corners
          Positioned(
            bottom: 0,
            left: 20,
            child: Text(
              'Oversold',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: subtextColor,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 20,
            child: Text(
              'Overbought',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: subtextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
