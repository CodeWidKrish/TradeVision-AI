import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

enum RecommendationType { buy, hold, sell }

class RecommendationRow extends StatelessWidget {
  final String stock;
  final String reason;
  final RecommendationType type;

  const RecommendationRow({
    super.key,
    required this.stock,
    required this.reason,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (type) {
      case RecommendationType.buy:
        badgeBg = AppColors.gainBg;
        badgeText = AppColors.gain;
        badgeLabel = 'BUY';
        break;
      case RecommendationType.hold:
        badgeBg = AppColors.warningBg;
        badgeText = AppColors.warning;
        badgeLabel = 'HOLD';
        break;
      case RecommendationType.sell:
        badgeBg = AppColors.lossBg;
        badgeText = AppColors.loss;
        badgeLabel = 'SELL';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDim.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppDim.radiusPill),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
