import 'package:flutter/material.dart';

/// A high-performance metallic shimmer gradient animation for dark & light surfaces.
class ShimmerPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerPulse> createState() => _ShimmerPulseState();
}

class _ShimmerPulseState extends State<ShimmerPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF131B26) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF223247) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer block with customizable rounded corners and size.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton mimic for an interactive trading chart.
class ChartSkeleton extends StatelessWidget {
  final double height;

  const ChartSkeleton({super.key, this.height = 280});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShimmerPulse(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          ),
        ),
        child: Column(
          children: [
            // Top metric row skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 80, height: 16, borderRadius: 4),
                SkeletonBox(width: 120, height: 16, borderRadius: 4),
                SkeletonBox(width: 60, height: 16, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 16),
            // Simulated candlestick bars
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _candleBar(80, 140),
                  _candleBar(110, 170),
                  _candleBar(90, 130),
                  _candleBar(130, 200),
                  _candleBar(120, 160),
                  _candleBar(140, 210),
                  _candleBar(160, 230),
                  _candleBar(150, 190),
                  _candleBar(180, 240),
                  _candleBar(170, 210),
                  _candleBar(200, 250),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Bottom volume bar skeletons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                11,
                (index) => SkeletonBox(
                  width: 8,
                  height: (index % 3 + 1) * 10.0,
                  borderRadius: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _candleBar(double lower, double upper) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SkeletonBox(width: 2, height: (upper - lower) * 0.4, borderRadius: 1),
        SkeletonBox(width: 10, height: (upper - lower) * 0.7, borderRadius: 2),
        SkeletonBox(width: 2, height: (upper - lower) * 0.3, borderRadius: 1),
      ],
    );
  }
}

/// Skeleton mimic for a stock row.
class StockRowSkeleton extends StatelessWidget {
  const StockRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ShimmerPulse(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2733) : const Color(0xFFE2E6EA),
          ),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 40, height: 40, borderRadius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 80, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 10, borderRadius: 4),
                ],
              ),
            ),
            const SkeletonBox(width: 50, height: 24, borderRadius: 4),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SkeletonBox(width: 65, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBox(width: 45, height: 10, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
