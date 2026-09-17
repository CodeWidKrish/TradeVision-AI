import 'package:flutter/material.dart';
import '../models/indicator_model.dart';

class IndicatorCard extends StatelessWidget {
  final IndicatorModel? indicators;
  final bool isLoading;

  const IndicatorCard({
    super.key,
    required this.indicators,
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
                  'Calculating technical indicators...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (indicators == null || indicators!.signal == 'N/A') {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No technical indicators available for this stock.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ind = indicators!;
    final signalColor = _getSignalColor(ind.signal);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'Technical Indicators',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: signalColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: signalColor),
                  ),
                  child: Text(
                    ind.signal.toUpperCase(),
                    style: TextStyle(
                      color: signalColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildIndicatorTile(
                  'RSI (14)',
                  ind.rsi != null ? ind.rsi!.toStringAsFixed(2) : 'N/A',
                  _getRsiInterpretation(ind.rsi),
                ),
                _buildIndicatorTile(
                  'MA 20',
                  ind.ma20 != null ? '\$${ind.ma20!.toStringAsFixed(2)}' : 'N/A',
                  'Short-term trend',
                ),
                _buildIndicatorTile(
                  'MA 50',
                  ind.ma50 != null ? '\$${ind.ma50!.toStringAsFixed(2)}' : 'N/A',
                  'Medium-term trend',
                ),
                _buildIndicatorTile(
                  'MACD',
                  ind.macd != null ? ind.macd!.toStringAsFixed(2) : 'N/A',
                  'Momentum indicator',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorTile(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor(String signal) {
    final s = signal.toLowerCase();
    if (s.contains('buy') || s.contains('bullish')) return Colors.green;
    if (s.contains('sell') || s.contains('bearish')) return Colors.red;
    return Colors.orange;
  }

  String _getRsiInterpretation(double? rsi) {
    if (rsi == null) return '';
    if (rsi >= 70) return 'Overbought';
    if (rsi <= 30) return 'Oversold';
    return 'Neutral';
  }
}
