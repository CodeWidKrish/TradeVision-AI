import 'package:flutter/material.dart';
import '../core/models/ohlc_point.dart';

class CandlestickPainter extends CustomPainter {
  final List<OhlcPoint> data;
  final double minPrice;
  final double maxPrice;
  final int? highlightedIndex;

  CandlestickPainter({
    required this.data,
    required this.minPrice,
    required this.maxPrice,
    this.highlightedIndex,
  });

  static const _bullColor = Color(0xFF00C853);
  static const _bearColor = Color(0xFFFF3B3B);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) return;

    final priceRange = (maxPrice - minPrice).abs();
    final safeRange = priceRange < 0.0001 ? 1.0 : priceRange; // avoid div-by-zero on flat data
    final slotWidth = size.width / data.length;
    final candleWidth = (slotWidth * 0.6).clamp(1.0, 14.0);

    double yFor(double price) =>
        size.height - ((price - minPrice) / safeRange) * size.height;

    for (var i = 0; i < data.length; i++) {
      final candle = data[i];
      final centerX = slotWidth * i + slotWidth / 2;
      final isBull = candle.isBullish;
      final color = isBull ? _bullColor : _bearColor;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Wick
      canvas.drawLine(
        Offset(centerX, yFor(candle.high)),
        Offset(centerX, yFor(candle.low)),
        paint,
      );

      // Body
      final bodyTop = yFor(isBull ? candle.close : candle.open);
      final bodyBottom = yFor(isBull ? candle.open : candle.close);
      final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.5, size.height);

      final rect = Rect.fromLTWH(
        centerX - candleWidth / 2,
        bodyTop,
        candleWidth,
        bodyHeight,
      );

      // Slight gradient fill for depth
      final bodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.95),
            color,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        bodyPaint,
      );

      // Highlighted selection ring
      if (highlightedIndex == i) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(2)),
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.minPrice != minPrice ||
      oldDelegate.maxPrice != maxPrice ||
      oldDelegate.highlightedIndex != highlightedIndex;
}
