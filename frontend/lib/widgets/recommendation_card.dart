import 'package:flutter/material.dart';
import '../models/recommendation_model.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationModel? recommendation;
  final bool isLoading;

  const RecommendationCard({
    super.key,
    required this.recommendation,
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
                  'Generating AI recommendation...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (recommendation == null || recommendation!.decision == 'N/A') {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(Icons.psychology_outlined, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No recommendation analysis available for this stock.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rec = recommendation!;
    final decisionColor = _getDecisionColor(rec.decision);
    final confidencePct = (rec.confidence * 100).clamp(0, 100).toInt();

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
                    Icon(Icons.psychology, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'AI Recommendation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: decisionColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rec.decision.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Confidence Bar
            Row(
              children: [
                Text(
                  'Confidence: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: rec.confidence.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: decisionColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$confidencePct%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: decisionColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reason
            if (rec.reason.isNotEmpty) ...[
              Text(
                'Analysis Reason:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rec.reason,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Key Factors List
            if (rec.keyFactors.isNotEmpty) ...[
              Text(
                'Key Factors:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: rec.keyFactors.map((factor) {
                  return Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.purple.shade50,
                    side: BorderSide(color: Colors.purple.shade100),
                    label: Text(
                      factor,
                      style: TextStyle(
                        color: Colors.purple.shade900,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDecisionColor(String decision) {
    final d = decision.toUpperCase();
    if (d.contains('BUY')) return Colors.green.shade700;
    if (d.contains('SELL')) return Colors.red.shade700;
    return Colors.orange.shade700;
  }
}
