import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chart_model.dart';

class ChartSectionWidget extends StatelessWidget {
  final ChartModel? chart;
  final bool isLoading;

  const ChartSectionWidget({
    super.key,
    required this.chart,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'Loading chart data...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (chart == null || chart!.points.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(Icons.show_chart, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No historical price chart data available.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final points = chart!.points;
    final firstPrice = points.first.close;
    final lastPrice = points.last.close;
    final isUp = lastPrice >= firstPrice;
    final lineColor = isUp ? Colors.green : Colors.red;

    final minPrice = points.map((e) => e.low).reduce(min);
    final maxPrice = points.map((e) => e.high).reduce(max);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.show_chart, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Price History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Range: \$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Custom Painter Price Chart
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _PriceChartPainter(
                  points: points,
                  lineColor: lineColor,
                  minPrice: minPrice,
                  maxPrice: maxPrice,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Date Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  points.first.date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (points.length > 2)
                  Text(
                    points[points.length ~/ 2].date,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                Text(
                  points.last.date,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color lineColor;
  final double minPrice;
  final double maxPrice;

  _PriceChartPainter({
    required this.points,
    required this.lineColor,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final priceRange = (maxPrice - minPrice) == 0 ? 1.0 : (maxPrice - minPrice);

    // Draw gridlines
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (points.length - 1 == 0 ? 1 : points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i].close - minPrice) / priceRange;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == points.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    // Draw gradient area under chart
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw main price line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw dots on data points
    final dotPaint = Paint()..color = lineColor;
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i].close - minPrice) / priceRange;
      final y = size.height - (normalizedY * size.height);
      canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
