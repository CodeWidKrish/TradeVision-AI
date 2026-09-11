import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiInsightStrip extends StatefulWidget {
  final String label;
  final List<String>? insights;
  final String? text;

  const AiInsightStrip({
    super.key,
    this.label = 'TRADEVISION AI',
    this.insights,
    this.text,
  });

  @override
  State<AiInsightStrip> createState() => _AiInsightStripState();
}

class _AiInsightStripState extends State<AiInsightStrip> {
  late List<String> _insights;
  int _currentIndex = 0;
  Timer? _timer;

  static const List<String> _defaultInsights = [
    'NIFTY Bank breakout above 52,300 signals strong bullish momentum for Indian private banks.',
    'RELIANCE testing major resistance at ₹2,900 with high institutional buying volume.',
    'IT Sector Index gains +1.2% as Infosys & TCS record positive Q3 earnings guidance.',
    'FII net inflows cross ₹2,450 Cr today following RBI monetary policy outlook.',
    'Auto stocks surge: Tata Motors & M&M show bullish flag pattern setup.',
    'SENSEX holding key support above 81,000 level with low volatility VIX index.',
    'Bajaj Finance triggers AI Strong Buy signal with 2.4x average volume breakout.',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.text != null && widget.text!.isNotEmpty) {
      _insights = [widget.text!];
    } else {
      _insights = widget.insights ?? _defaultInsights;
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _insights.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentText = _insights[_currentIndex];

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _insights.length;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    const Color(0xFF0066CC).withOpacity(0.14),
                    const Color(0xFF0A0E1A),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isDark ? null : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF0066CC).withOpacity(0.25)
                : const Color(0xFF0066CC).withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0066CC),
                            letterSpacing: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _insights.length,
                          (idx) => Container(
                            width: idx == _currentIndex ? 10 : 4,
                            height: 4,
                            margin: const EdgeInsets.only(left: 3),
                            decoration: BoxDecoration(
                              color: idx == _currentIndex
                                  ? const Color(0xFF0066CC)
                                  : const Color(0xFF0066CC).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      currentText,
                      key: ValueKey<int>(_currentIndex),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFCDD5E0)
                            : const Color(0xFF1A1A2E),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
