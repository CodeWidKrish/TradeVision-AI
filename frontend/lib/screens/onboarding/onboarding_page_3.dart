import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/ai_node_painter.dart';

class OnboardingPage3 extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OnboardingPage3({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = Theme.of(context).cardColor;
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final recCardBg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC);
    final recCardBorder = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF8892A4) : const Color(0xFF64748B);

    return Column(
      children: [
        // Illustration Area (Top Card)
        Container(
          height: 320,
          margin: EdgeInsets.fromLTRB(24, statusBarHeight + 40, 24, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Radial AI Node Graphic
              const SizedBox(
                height: 200,
                child: Center(
                  child: AiNodeGraphicWidget(),
                ),
              ),

              const Spacer(),

              // Recommendation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: recCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: recCardBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Left Accent Bar 3px #FF8C00
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Strong BUY Recommendation',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confidence: 87% · Risk: Medium · AI Score: 8.4',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Text Section
        Text(
          'AI\nRecommendations',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Smart, explainable AI insights on any stock with confidence scores, risk levels, and clear reasoning.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: subtextColor,
              height: 1.4,
            ),
          ),
        ),

        const Spacer(),
      ],
    );
  }
}
