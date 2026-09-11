import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tv_logo_widget.dart';

class AiNodeGraphicWidget extends StatefulWidget {
  const AiNodeGraphicWidget({super.key});

  @override
  State<AiNodeGraphicWidget> createState() => _AiNodeGraphicWidgetState();
}

class _AiNodeGraphicWidgetState extends State<AiNodeGraphicWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(220, 200),
          painter: AiNodePainter(progress: _controller.value, isDark: isDark),
          child: SizedBox(
            width: 220,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center Icon (56px)
                const TVLogoWidget(
                  variant: LogoVariant.iconOnly,
                  size: 56,
                ),
                // 6 Orbiting Node Circles
                ...List.generate(6, (index) {
                  final double angle = (index * 60.0) * (pi / 180.0);
                  const double radius = 80.0;
                  final double x = radius * cos(angle);
                  final double y = radius * sin(angle);

                  final colors = [
                    const Color(0xFF0066CC),
                    const Color(0xFF00C853),
                    const Color(0xFFFF6B00),
                    const Color(0xFF0066CC),
                    const Color(0xFF00C853),
                    const Color(0xFFFF6B00),
                  ];

                  final nodeColor = colors[index % colors.length];

                  // Staggered scale pulse calculation
                  final double staggeredProgress =
                      (_controller.value + (index * 0.15)) % 1.0;
                  final double scale =
                      1.0 + (0.08 * sin(staggeredProgress * pi));

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: nodeColor,
                          boxShadow: [
                            BoxShadow(
                              color: nodeColor.withOpacity(0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AiNodePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  AiNodePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double radius = 80.0;

    final linePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60.0) * (pi / 180.0);
      final nodePos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      // Draw dashed line from center to node
      _drawDashedLine(canvas, center, nodePos, linePaint);
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double angle = atan2(dy, dx);

    double currentDist = 0;
    while (currentDist < distance) {
      final double startX = p1.dx + currentDist * cos(angle);
      final double startY = p1.dy + currentDist * sin(angle);

      final double nextDist = min(currentDist + dashWidth, distance);
      final double endX = p1.dx + nextDist * cos(angle);
      final double endY = p1.dy + nextDist * sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant AiNodePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
