class ChartPoint {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  ChartPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      date: json['date'] as String? ?? '',
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}

class ChartModel {
  final String symbol;
  final List<ChartPoint> points;
  final String message;

  ChartModel({
    required this.symbol,
    required this.points,
    this.message = 'Chart data loaded',
  });

  factory ChartModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    List<ChartPoint> parsedPoints = [];
    if (rawPoints is List) {
      parsedPoints = rawPoints
          .map((item) => ChartPoint.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ChartModel(
      symbol: json['symbol'] as String? ?? '',
      points: parsedPoints,
      message: json['message'] as String? ?? 'Chart data loaded',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'points': points.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}
