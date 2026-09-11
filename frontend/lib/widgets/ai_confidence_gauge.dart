import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiConfidenceGauge extends StatefulWidget {
  final double score; // 0.0 to 100.0
  final double size;
  final String label;

  const AiConfidenceGauge({
    super.key,
    required this.score,
    this.size = 130,
    this.label = 'AI Confidence',
  });

  @override
  State<AiConfidenceGauge> createState() => _AiConfidenceGaugeState();
}

class _AiConfidenceGaugeState extends State<AiConfidenceGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AiConfidenceGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForScore(double score) {
    if (score >= 75) return const Color(0xFF10B981); // Emerald
    if (score >= 50) return const Color(0xFF38BDF8); // Electric Sky
    if (score >= 35) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = widget.score * _animation.value;
        final strokeColor = _getColorForScore(widget.score);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  score: currentScore,
                  color: strokeColor,
                  isDark: isDark,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${currentScore.toStringAsFixed(0)}%',
                    style: GoogleFonts.robotoMono(
                      fontSize: widget.size * 0.23,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: widget.size * 0.09,
                      fontWeight: FontWeight.w600,
                      color: strokeColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final bool isDark;

  _GaugePainter({
    required this.score,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;
    const startAngle = math.pi * 0.75;
    const totalSweep = math.pi * 1.5;

    // Track background arc
    final trackPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Active progress arc
    final progressSweep = totalSweep * (score / 100.0).clamp(0.0, 1.0);
    if (progressSweep > 0.001) {
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweep,
          colors: [
            color.withValues(alpha: 0.65),
            color,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Glow blur pass
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        glowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
