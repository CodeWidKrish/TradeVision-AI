import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

class MiniSparkline extends StatelessWidget {
  final List<double> heights;
  final bool isGain;

  const MiniSparkline({
    super.key,
    this.heights = const [8, 12, 10, 18, 14, 22],
    this.isGain = true,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isGain ? AppColors.gain : AppColors.loss;

    return SizedBox(
      height: AppDim.miniChartH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights.map((h) {
          return Container(
            width: 3,
            height: h,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
