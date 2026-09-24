import 'dart:convert';

enum AlertType {
  priceAbove,
  priceBelow,
  percentGain,
  percentLoss,
  aiSignalShift,
  rsiOversold,
  rsiOverbought,
}

class PriceAlert {
  final String id;
  final String ticker;
  final String stockName;
  final AlertType type;
  final double? targetPrice;
  final double? targetPercent;
  final String? targetSignal;
  final DateTime createdAt;
  bool isActive;
  bool isTriggered;
  double? triggeredPrice;
  DateTime? triggeredAt;
  String? triggerMessage;

  PriceAlert({
    required this.id,
    required this.ticker,
    required this.stockName,
    required this.type,
    this.targetPrice,
    this.targetPercent,
    this.targetSignal,
    DateTime? createdAt,
    this.isActive = true,
    this.isTriggered = false,
    this.triggeredPrice,
    this.triggeredAt,
    this.triggerMessage,
  }) : createdAt = createdAt ?? DateTime.now();

  String get title {
    switch (type) {
      case AlertType.priceAbove:
        return '$ticker crosses above ₹${targetPrice?.toStringAsFixed(2)}';
      case AlertType.priceBelow:
        return '$ticker drops below ₹${targetPrice?.toStringAsFixed(2)}';
      case AlertType.percentGain:
        return '$ticker gains > +${targetPercent?.toStringAsFixed(1)}%';
      case AlertType.percentLoss:
        return '$ticker falls > -${targetPercent?.toStringAsFixed(1)}%';
      case AlertType.aiSignalShift:
        return '$ticker AI signal shifts to $targetSignal';
      case AlertType.rsiOversold:
        return '$ticker RSI enters Oversold (< 30)';
      case AlertType.rsiOverbought:
        return '$ticker RSI enters Overbought (> 70)';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticker': ticker,
    'stockName': stockName,
    'type': type.index,
    'targetPrice': targetPrice,
    'targetPercent': targetPercent,
    'targetSignal': targetSignal,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'isTriggered': isTriggered,
    'triggeredPrice': triggeredPrice,
    'triggeredAt': triggeredAt?.toIso8601String(),
    'triggerMessage': triggerMessage,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> map) => PriceAlert(
    id: map['id'] ?? '',
    ticker: map['ticker'] ?? '',
    stockName: map['stockName'] ?? '',
    type: AlertType.values[(map['type'] as num?)?.toInt() ?? 0],
    targetPrice: (map['targetPrice'] as num?)?.toDouble(),
    targetPercent: (map['targetPercent'] as num?)?.toDouble(),
    targetSignal: map['targetSignal'] as String?,
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'])
        : DateTime.now(),
    isActive: map['isActive'] ?? true,
    isTriggered: map['isTriggered'] ?? false,
    triggeredPrice: (map['triggeredPrice'] as num?)?.toDouble(),
    triggeredAt: map['triggeredAt'] != null
        ? DateTime.tryParse(map['triggeredAt'])
        : null,
    triggerMessage: map['triggerMessage'] as String?,
  );
}
