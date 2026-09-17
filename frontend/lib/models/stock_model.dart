class StockModel {
  final String symbol;
  final String? companyName;
  final double? currentPrice;
  final double? changePercent;
  final String status;
  final String? message;

  StockModel({
    required this.symbol,
    this.companyName,
    this.currentPrice,
    this.changePercent,
    this.status = 'active',
    this.message,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
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
