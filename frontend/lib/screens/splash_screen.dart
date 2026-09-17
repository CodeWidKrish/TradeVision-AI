// lib/screens/splash_screen.dart
// TradeVision AI — Institutional "Market Opening Bell" Splash Animation (0.75x Speed)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../services/storage_service.dart';
import '../widgets/ticker_tape.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers (Calibrated to 0.75x Cinematic Speed) ───────────────────
  late AnimationController _flatlineCtrl; // Phase 1: flatline draw
  late AnimationController _barsCtrl; // Phase 2: 3D bars spring up
  late AnimationController _trendCtrl; // Phase 3: laser trend line
  late AnimationController _sparkleCtrl; // Phase 3b: jewel sparkle
  late AnimationController _textCtrl; // Phase 4: wordmark + AI badge
  late AnimationController _pulseCtrl; // Phase 5: heartbeat pulse
  late AnimationController _progressCtrl; // 4.2s smooth loading bar

  // ── Animations ───────────────────────────────────────────────────────────
  late Animation<double> _flatlineProgress;
  late Animation<double> _bar1Height;
  late Animation<double> _bar2Height;
  late Animation<double> _bar3Height;
  late Animation<double> _bar4Height;
  late Animation<double> _trendProgress;
  late Animation<double> _glowOpacity;
  late Animation<double> _sparkleScale;
  late Animation<double> _sparkleOpacity;
  late Animation<double> _tradeFade;
  late Animation<double> _visionFade;
  late Animation<double> _aiBadgeScale;
  late Animation<double> _taglineFade;
  late Animation<double> _logoScale;
  late Animation<double> _progressBar;

  bool _showTicker = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // 0.75x Speed = 1 / 0.75 = 1.33x standard duration for ultra-smooth fluidity

    // Phase 1 — Flatline draws across (1050ms)
    _flatlineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _flatlineProgress = CurvedAnimation(
      parent: _flatlineCtrl,
      curve: Curves.easeOutCubic,
    );

    // Phase 2 — 3D Bars grow up with spring physics bounce (1200ms)
    _barsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bar1Height = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.0, 0.65, curve: _SpringCurve()),
      ),
    );
    _bar2Height = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.15, 0.78, curve: _SpringCurve()),
      ),
    );
    _bar3Height = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.30, 0.88, curve: _SpringCurve()),
      ),
    );
    _bar4Height = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(
        parent: _barsCtrl,
        curve: const Interval(0.45, 1.00, curve: _SpringCurve()),
      ),
    );

    // Phase 3 — Laser trend line shoots across bar crowns (800ms)
    _trendCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _trendProgress = CurvedAnimation(
      parent: _trendCtrl,
      curve: Curves.easeInOutCubic,
    );
    _glowOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _trendCtrl,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );

    // Phase 3b — Proportional jewel sparkle at peak (650ms)
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _sparkleScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1.35), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _sparkleCtrl, curve: Curves.easeOutCubic));

    _sparkleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _sparkleCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Phase 4 — Wordmark + glowing [AI] badge (1050ms)
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _tradeFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );
    _visionFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    );
    _aiBadgeScale = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.45, 0.90, curve: _SpringCurve()),
    );
    _taglineFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    // Phase 5 — Heartbeat pulse (800ms)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.055), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.055, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Progress bar (total 0.75x sequence = 4260ms)
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4260),
    );
    _progressBar = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.linear),
    );
  }

  Future<void> _startSequence() async {
    _progressCtrl.forward();

    // Phase 1 — Flatline lead
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _flatlineCtrl.forward();

    // Phase 2 — 3D volume bars spring up
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _barsCtrl.forward();

    // Phase 3 — Trend line glides over crowns
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    _trendCtrl.forward();

    // Phase 3b — Jewel sparkle burst at the apex
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _sparkleCtrl.forward();

    // Phase 4 — Wordmark + AI badge
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _textCtrl.forward();

    // Phase 5 — Heartbeat pulse & ticker tape
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _pulseCtrl.forward();
    if (mounted) setState(() => _showTicker = true);

    // Let the complete glowing crest & ticker settle smoothly for 1.1s
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    final bool isLoggedIn = StorageService.getIsLoggedIn();
    final bool hasOnboarded = StorageService.hasOnboarded();

    if (kIsWeb) {
      // On web/chrome test: always showcase full flow: Splash -> Onboarding -> Auth -> Home
      context.go('/onboarding');
    } else {
      if (isLoggedIn) {
        context.go('/home');
      } else if (hasOnboarded) {
        context.go('/auth');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _flatlineCtrl.dispose();
    _barsCtrl.dispose();
    _trendCtrl.dispose();
    _sparkleCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final W = size.width;

    // Responsive clamped stage dimensions (Zero overflow on desktop Chrome or mobile)
    final stageWidth = min(W * 0.85, 330.0);
    final stageHeight = stageWidth * 0.68;

    return Scaffold(
      backgroundColor: const Color(0xFF040812),
      body: Stack(
        children: [
          // ── BACKGROUND GLOWS ──────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundGlowPainter()),
          ),

          // ── MAIN CONTENT (Clamped & Scroll-Safe) ────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // ── CHART ANIMATION STAGE (Ample Headroom) ─────────────
                      SizedBox(
                        width: stageWidth,
                        height: stageHeight,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _flatlineCtrl,
                            _barsCtrl,
                            _trendCtrl,
                            _sparkleCtrl,
                          ]),
                          builder: (_, __) => ScaleTransition(
                            scale: _logoScale,
                            child: CustomPaint(
                              painter: _ChartAnimationPainter(
                                flatlineProgress: _flatlineProgress.value,
                                bar1: _bar1Height.value,
                                bar2: _bar2Height.value,
                                bar3: _bar3Height.value,
                                bar4: _bar4Height.value,
                                trendProgress: _trendProgress.value,
                                glowOpacity: _glowOpacity.value,
                                sparkleScale: _sparkleScale.value,
                                sparkleOpacity: _sparkleOpacity.value,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── WORDMARK & [AI] BADGE ──────────────────────────────
                      AnimatedBuilder(
                        animation: _textCtrl,
                        builder: (_, __) => Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FadeTransition(
                                  opacity: _tradeFade,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-0.25, 0),
                                      end: Offset.zero,
                                    ).animate(_tradeFade),
                                    child: Text(
                                      'Trade',
                                      style: GoogleFonts.inter(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                FadeTransition(
                                  opacity: _visionFade,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.25, 0),
                                      end: Offset.zero,
                                    ).animate(_visionFade),
                                    child: Text(
                                      'Vision',
                                      style: GoogleFonts.inter(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0077FF),
                                        letterSpacing: -1,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Glowing [ AI ] Pill Badge
                                ScaleTransition(
                                  scale: _aiBadgeScale,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00FF88).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'AI',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF00FF88),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _taglineFade,
                              child: Text(
                                'REAL-TIME MARKET INTELLIGENCE',
                                style: GoogleFonts.inter(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 3.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── TICKER TAPE (Smooth Fade-In) ───────────────────────
                      AnimatedOpacity(
                        opacity: _showTicker ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: const SizedBox(
                          height: 32,
                          child: TickerTapeWidget(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── PROGRESS BAR (Blue → Green Gradient) ───────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: AnimatedBuilder(
                          animation: _progressBar,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressBar.value,
                              backgroundColor: const Color(0xFF101928),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.lerp(
                                  const Color(0xFF0077FF),
                                  const Color(0xFF00FF88),
                                  _progressBar.value,
                                )!,
                              ),
                              minHeight: 3.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Connecting live NSE/BSE institutional feeds...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF55657E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CHART ANIMATION PAINTER (No Wicks • Headroom Protected • Razor Spark) ──

class _ChartAnimationPainter extends CustomPainter {
  final double flatlineProgress;
  final double bar1, bar2, bar3, bar4;
  final double trendProgress;
  final double glowOpacity;
  final double sparkleScale;
  final double sparkleOpacity;

  const _ChartAnimationPainter({
    required this.flatlineProgress,
    required this.bar1,
    required this.bar2,
    required this.bar3,
    required this.bar4,
    required this.trendProgress,
    required this.glowOpacity,
    required this.sparkleScale,
    required this.sparkleOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    const barCount = 4;
    final barW = W * 0.165;
    final barGap = W * 0.06;
    final totalBarsW = barCount * barW + (barCount - 1) * barGap;
    final barsStartX = (W - totalBarsW) / 2;
    final barsBottom = H * 0.86;

    // Generous headroom: 4th bar stops at H * 0.28, leaving 28% canvas clearance above
    final maxHeights = [H * 0.20, H * 0.33, H * 0.46, H * 0.58];
    final heights = [
      maxHeights[0] * bar1,
      maxHeights[1] * bar2,
      maxHeights[2] * bar3,
      maxHeights[3] * bar4,
    ];

    // FinTech Palette: Deep Sapphire -> Electric Sky -> Dalal Emerald -> Breakout Neon
    final barColors = [
      [const Color(0xFF0D50B8), const Color(0xFF388BFD)],
      [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      [const Color(0xFF00873E), const Color(0xFF00E676)],
      [const Color(0xFF00A84E), const Color(0xFF00FF88)],
    ];

    // ── 0. Ground Floor Reflections ──────────────────────────────────────
    if (bar1 > 0.1) {
      for (int i = 0; i < barCount; i++) {
        if (heights[i] <= 0) continue;
        final x = barsStartX + i * (barW + barGap);
        final reflectH = heights[i] * 0.22;

        final refShader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColors[i][1].withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x, barsBottom, barW, reflectH));

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, barsBottom + 2, barW, reflectH),
            const Radius.circular(4),
          ),
          Paint()..shader = refShader,
        );
      }
    }

    // ── 1. Baseline Trading Axis ─────────────────────────────────────────
    if (bar1 > 0) {
      canvas.drawLine(
        Offset(barsStartX - 16, barsBottom),
        Offset(barsStartX + totalBarsW + 16, barsBottom),
        Paint()
          ..color = const Color(0xFF141E2E)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }

    // ── 2. Phase 1: Flatline Lead ────────────────────────────────────────
    if (flatlineProgress > 0) {
      final flatY = barsBottom;
      final flatEnd = W * flatlineProgress;

      // Soft green aura
      canvas.drawLine(
        Offset(0, flatY),
        Offset(flatEnd, flatY),
        Paint()
          ..color = const Color(0xFF00FF88).withValues(alpha: 0.2)
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round,
      );

      // Sharp core
      canvas.drawLine(
        Offset(0, flatY),
        Offset(flatEnd, flatY),
        Paint()
          ..color = const Color(0xFF00FF88)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      if (flatlineProgress < 0.98) {
        // Leading radar pulse dot
        canvas.drawCircle(
          Offset(flatEnd, flatY),
          8.0,
          Paint()..color = const Color(0xFF00FF88).withValues(alpha: 0.25),
        );
        canvas.drawCircle(
          Offset(flatEnd, flatY),
          4.0,
          Paint()..color = Colors.white,
        );
      }
    }

    // ── 3. Phase 2: 3D Volumetric Volume Bars (NO WICKS / NO TOP LINES) ──
    for (int i = 0; i < barCount; i++) {
      final h = heights[i];
      if (h <= 0) continue;

      final x = barsStartX + i * (barW + barGap);
      final y = barsBottom - h;
      const radius = Radius.circular(7);
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, h), radius);

      // Atmospheric Bloom
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = barColors[i][1].withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14),
      );

      // 3D Body Gradient
      final grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [barColors[i][1], barColors[i][0]],
      ).createShader(Rect.fromLTWH(x, y, barW, h));

      canvas.drawRRect(rrect, Paint()..shader = grad);

      // Glassmorphic Left-Edge Bevel Highlight (Tactile 3D Depth)
      final leftBevel = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x + 1, y + 2, 4, max(4, h - 4)));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1, y + 2, 3.5, max(4, h - 4)),
          const Radius.circular(2),
        ),
        Paint()..shader = leftBevel,
      );
    }

    // ── 4. Phase 3: Trend Line Hugging Bar Crowns + Luminous Area Fill ───
    if (trendProgress > 0 && bar1 > 0.4) {
      final points = <Offset>[];
      for (int i = 0; i < barCount; i++) {
        if (heights[i] <= 0) continue;
        final x = barsStartX + i * (barW + barGap) + barW / 2;
        final y = barsBottom - heights[i] - 6; // Hugs crowns cleanly
        points.add(Offset(x, y));
      }

      if (points.length >= 2) {
        final totalLen = _pathLength(points);
        final drawn = totalLen * trendProgress;

        // Area Fill Gradient beneath curve
        if (glowOpacity > 0) {
          final areaPath = _buildPartialPath(points, drawn);
          final currentTip = _pointAtLength(points, drawn);
          areaPath.lineTo(currentTip.dx, barsBottom);
          areaPath.lineTo(points[0].dx, barsBottom);
          areaPath.close();

          final areaShader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF00FF88).withValues(alpha: 0.22 * glowOpacity),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTRB(
            0,
            points.last.dy,
            0,
            barsBottom,
          ));

          canvas.drawPath(areaPath, Paint()..shader = areaShader);
        }

        // Luminous Glow Path
        if (glowOpacity > 0) {
          final glowPath = _buildPartialPath(points, drawn);
          canvas.drawPath(
            glowPath,
            Paint()
              ..color = const Color(0xFF00FF88).withValues(alpha: 0.35 * glowOpacity)
              ..strokeWidth = 16.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
          );
        }

        // Sharp Vector Trend Line
        final linePath = _buildPartialPath(points, drawn);
        canvas.drawPath(
          linePath,
          Paint()
            ..color = const Color(0xFF00FF88)
            ..strokeWidth = 3.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );

        // Arrow Tip
        if (trendProgress > 0.92) {
          final tip = points.last;
          final prev = points[points.length - 2];
          final angle = atan2(tip.dy - prev.dy, tip.dx - prev.dx);
          const arrowLen = 20.0;
          const arrowAngle = 0.45;

          final a1 = Offset(
            tip.dx - arrowLen * cos(angle - arrowAngle),
            tip.dy - arrowLen * sin(angle - arrowAngle),
          );
          final a2 = Offset(
            tip.dx - arrowLen * cos(angle + arrowAngle),
            tip.dy - arrowLen * sin(angle + arrowAngle),
          );

          final arrowPaint = Paint()
            ..color = const Color(0xFF00FF88)
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round;

          canvas.drawLine(tip, a1, arrowPaint);
          canvas.drawLine(tip, a2, arrowPaint);

          // ── Phase 3b: Jewel Sparkle (Proportionate 22px, Zero Clipping) ──
          if (sparkleOpacity > 0 && sparkleScale > 0) {
            _drawJewelSparkle(canvas, tip, sparkleScale, sparkleOpacity);
          }
        }
      }
    }
  }

  void _drawJewelSparkle(Canvas canvas, Offset center, double scale, double opacity) {
    // 1. Soft Emerald Halo
    canvas.drawCircle(
      center,
      22.0 * scale,
      Paint()
        ..color = const Color(0xFF00FF88).withValues(alpha: 0.25 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 2. Radiant Inner Core
    canvas.drawCircle(
      center,
      8.0 * scale,
      Paint()..color = const Color(0xFF00E676).withValues(alpha: 0.75 * opacity),
    );

    // 3. Crisp Pure White Center
    canvas.drawCircle(
      center,
      4.0 * scale,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    // 4. Primary Vertical & Horizontal Star Spikes (22px Compact)
    final spikePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final spikeLen = 22.0 * scale;
    final diagLen = 13.0 * scale;

    canvas.drawLine(
      Offset(center.dx, center.dy - spikeLen),
      Offset(center.dx, center.dy + spikeLen),
      spikePaint,
    );
    canvas.drawLine(
      Offset(center.dx - spikeLen, center.dy),
      Offset(center.dx + spikeLen, center.dy),
      spikePaint,
    );

    // 5. Diagonal Star Spikes
    final diagPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.75)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - diagLen, center.dy - diagLen),
      Offset(center.dx + diagLen, center.dy + diagLen),
      diagPaint,
    );
    canvas.drawLine(
      Offset(center.dx + diagLen, center.dy - diagLen),
      Offset(center.dx - diagLen, center.dy + diagLen),
      diagPaint,
    );

    // 6. 6 Orbiting Stardust Particles
    for (int i = 0; i < 6; i++) {
      final angle = i * (pi / 3);
      final dist = 24.0 * scale;
      final r = i % 2 == 0 ? 2.2 : 1.4;
      canvas.drawCircle(
        Offset(center.dx + dist * cos(angle), center.dy + dist * sin(angle)),
        r * scale,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.85),
      );
    }
  }

  double _pathLength(List<Offset> points) {
    double len = 0;
    for (int i = 1; i < points.length; i++) {
      len += (points[i] - points[i - 1]).distance;
    }
    return len;
  }

  Path _buildPartialPath(List<Offset> points, double drawn) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);

    double traveled = 0;
    for (int i = 1; i < points.length; i++) {
      final segLen = (points[i] - points[i - 1]).distance;
      if (traveled + segLen >= drawn) {
        final t = (drawn - traveled) / segLen;
        final px = points[i - 1].dx + (points[i].dx - points[i - 1].dx) * t;
        final py = points[i - 1].dy + (points[i].dy - points[i - 1].dy) * t;
        path.lineTo(px, py);
        break;
      }
      path.lineTo(points[i].dx, points[i].dy);
      traveled += segLen;
    }
    return path;
  }

  Offset _pointAtLength(List<Offset> points, double targetLen) {
    if (points.isEmpty) return Offset.zero;
    double traveled = 0;
    for (int i = 1; i < points.length; i++) {
      final segLen = (points[i] - points[i - 1]).distance;
      if (traveled + segLen >= targetLen) {
        final t = (targetLen - traveled) / segLen;
        return Offset(
          points[i - 1].dx + (points[i].dx - points[i - 1].dx) * t,
          points[i - 1].dy + (points[i].dy - points[i - 1].dy) * t,
        );
      }
      traveled += segLen;
    }
    return points.last;
  }

  @override
  bool shouldRepaint(_ChartAnimationPainter old) => true;
}

// ── BACKGROUND GLOW PAINTER ────────────────────────────────────────────────

class _BackgroundGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-center blue radial glow
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.32),
      size.width * 0.70,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF0066CC).withValues(alpha: 0.14),
            const Color(0xFF040812).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.32),
          radius: size.width * 0.70,
        )),
    );

    // Bottom-left emerald accent glow
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.78),
      size.width * 0.40,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00C853).withValues(alpha: 0.08),
            const Color(0xFF040812).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.12, size.height * 0.78),
          radius: size.width * 0.40,
        )),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── SPRING CURVE (Fluid Overshoot Physics) ──────────────────────────────────

class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    const c4 = (2 * pi) / 3;
    if (t == 0 || t == 1) return t;
    return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
  }
}
