enum ChartType { line, candlestick }

class OhlcPoint {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double? volume;

  const OhlcPoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume,
  });

  bool get isBullish => close >= open;

  /// Validates a single candle — rejects impossible OHLC combos
  bool get isValid =>
      high >= low &&
      high >= open &&
      high >= close &&
      low <= open &&
      low <= close &&
      !open.isNaN &&
      !high.isNaN &&
      !low.isNaN &&
      !close.isNaN &&
      open.isFinite &&
      high.isFinite &&
      low.isFinite &&
      close.isFinite;
}

class OhlcSanitizer {
  /// Filters out invalid candles and returns a result the UI can react to.
  static ({List<OhlcPoint> data, String? warning}) sanitize(List<OhlcPoint> raw) {
    if (raw.isEmpty) {
      return (data: <OhlcPoint>[], warning: 'No chart data available');
    }
    final valid = raw.where((p) => p.isValid).toList();
    if (valid.isEmpty) {
      return (data: <OhlcPoint>[], warning: 'Chart data is corrupted');
    }
    final droppedCount = raw.length - valid.length;
    return (
      data: valid,
      warning: droppedCount > 0 ? '$droppedCount data points were skipped' : null,
    );
  }
}
