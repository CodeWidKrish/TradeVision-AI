import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SignalBadge extends StatelessWidget {
  final String signal;

  const SignalBadge({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    return SignalBadgeWithInfo(signal: signal);
  }
}

class SignalBadgeWithInfo extends StatelessWidget {
  final String signal;
  const SignalBadgeWithInfo({super.key, required this.signal});

  Color get _color => switch (signal.toUpperCase()) {
        'BUY' => const Color(0xFF00C853),
        'SELL' => const Color(0xFFFF3B3B),
        _ => const Color(0xFFFF8C00),
      };

  String get _explanation => switch (signal.toUpperCase()) {
        'BUY' =>
          'Our AI thinks this stock has a good chance of going up based on its price pattern, RSI score, and recent news. This is a suggestion only — always do your own research.',
        'SELL' =>
          'Our AI thinks this stock may go down soon based on its current pattern and indicators. It may not be the best time to hold this stock right now.',
        _ =>
          'Our AI thinks this stock could go either way right now. It is best to wait and watch before making a decision.',
      };

  String get _label => switch (signal.toUpperCase()) {
        'BUY' => 'Consider Buying',
        'SELL' => 'Consider Selling',
        _ => 'Wait and Watch',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What does "$signal" mean?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _explanation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF8892A4),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF8C00), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For learning only. Not financial advice. Consult a SEBI-registered advisor before investing.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFFF8C00),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _color.withValues(alpha: 0.35), width: 1),
            ),
            child: Text(
              _label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.help_outline_rounded,
            size: 13,
            color: Color(0xFF8892A4),
          ),
        ],
      ),
    );
  }
}
