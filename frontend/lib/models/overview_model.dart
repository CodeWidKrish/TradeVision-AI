class StockInfo {
  final String symbol;
  final String? companyName;
  final double? currentPrice;
  final double? changePercent;
  final String status;
  final String? message;

  StockInfo({
    required this.symbol,
    this.companyName,
    this.currentPrice,
    this.changePercent,
    this.status = 'active',
    this.message,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      symbol: json['symbol'] as String? ?? '',
      companyName: json['company_name'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'company_name': companyName,
      'current_price': currentPrice,
      'change_percent': changePercent,
      'status': status,
      'message': message,
    };
  }
}

class IndicatorInfo {
  final String symbol;
  final double? rsi;
  final double? ma20;
  final double? ma50;
  final double? macd;
  final String signal;
  final String? message;

  IndicatorInfo({
    required this.symbol,
    this.rsi,
    this.ma20,
    this.ma50,
    this.macd,
    required this.signal,
    this.message,
  });

  factory IndicatorInfo.fromJson(Map<String, dynamic> json) {
    return IndicatorInfo(
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

class OverviewModel {
  final StockInfo stock;
  final IndicatorInfo indicators;

  OverviewModel({
    required this.stock,
    required this.indicators,
  });

  factory OverviewModel.fromJson(Map<String, dynamic> json) {
    return OverviewModel(
      stock: StockInfo.fromJson(json['stock'] as Map<String, dynamic>? ?? {}),
      indicators: IndicatorInfo.fromJson(
          json['indicators'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock': stock.toJson(),
      'indicators': indicators.toJson(),
    };
  }
}
