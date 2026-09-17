class StockDetailModel {
  final String symbol;
  final String? companyName;
  final double? currentPrice;
  final double? changePercent;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final int? volume;
  final String status;
  final String? message;

  StockDetailModel({
    required this.symbol,
    this.companyName,
    this.currentPrice,
    this.changePercent,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.status = 'active',
    this.message,
  });

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    return StockDetailModel(
      symbol: json['symbol'] as String? ?? '',
      companyName: json['company_name'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      openPrice: (json['open_price'] as num?)?.toDouble(),
      highPrice: (json['high_price'] as num?)?.toDouble(),
      lowPrice: (json['low_price'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toInt(),
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
      'open_price': openPrice,
      'high_price': highPrice,
      'low_price': lowPrice,
      'volume': volume,
      'status': status,
      'message': message,
    };
  }
}
