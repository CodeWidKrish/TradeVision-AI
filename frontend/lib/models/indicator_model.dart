class IndicatorModel {
  final String symbol;
  final double? rsi;
  final double? ma20;
  final double? ma50;
  final double? macd;
  final String signal;
  final String? message;

  IndicatorModel({
    required this.symbol,
    this.rsi,
    this.ma20,
    this.ma50,
    this.macd,
    required this.signal,
    this.message,
  });

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    return IndicatorModel(
      symbol: json['symbol'] as String? ?? '',
      rsi: (json['rsi'] as num?)?.toDouble(),
      ma20: (json['ma20'] as num?)?.toDouble(),
      ma50: (json['ma50'] as num?)?.toDouble(),
      macd: (json['macd'] as num?)?.toDouble(),
      signal: json['signal'] as String? ?? 'N/A',
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'rsi': rsi,
      'ma20': ma20,
      'ma50': ma50,
      'macd': macd,
      'signal': signal,
      'message': message,
    };
  }
}
