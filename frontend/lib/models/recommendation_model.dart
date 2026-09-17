class RecommendationModel {
  final String symbol;
  final String decision;
  final double confidence;
  final String reason;
  final List<String> keyFactors;
  final String? message;

  RecommendationModel({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.reason,
    required this.keyFactors,
    this.message = 'Recommendation loaded',
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawFactors = json['key_factors'];
    List<String> parsedFactors = [];
    if (rawFactors is List) {
      parsedFactors = rawFactors.map((e) => e.toString()).toList();
    }

    return RecommendationModel(
      symbol: json['symbol'] as String? ?? '',
      decision: json['decision'] as String? ?? 'N/A',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
      keyFactors: parsedFactors,
      message: json['message'] as String? ?? 'Recommendation loaded',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'decision': decision,
      'confidence': confidence,
      'reason': reason,
      'key_factors': keyFactors,
      'message': message,
    };
  }
}
