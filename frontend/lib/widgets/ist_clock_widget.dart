import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/clock_provider.dart';

class ISTClockWidget extends ConsumerWidget {
  final bool compact; // true = just time, false = time + market status
  const ISTClockWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeString = ref.watch(istTimeStringProvider);
    final marketStatus = ref.watch(marketStatusProvider);

    final statusColor = switch (marketStatus) {
      MarketStatus.open    => const Color(0xFF00C853),
      MarketStatus.preOpen => const Color(0xFFFF8C00),
      MarketStatus.closed  => const Color(0xFFFF3B3B),
    };

    final statusLabel = switch (marketStatus) {
      MarketStatus.open    => 'LIVE',
      MarketStatus.preOpen => 'PRE-OPEN',
      MarketStatus.closed  => 'CLOSED',
    };

    if (compact) {
      // Compact version — just the time in Roboto Mono
      return Text(
        timeString,
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? const Color(0xFFE8ECF0)
              : const Color(0xFF1A1A2E),
        ),
      );
    }

    // Full version — time + market status badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111827)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2733)
              : const Color(0xFFE2E6EA),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clock icon
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: Color(0xFF8892A4),
          ),
          const SizedBox(width: 6),

          // Live time — Roboto Mono so digits don't jump width
          Text(
            timeString,
            style: GoogleFonts.robotoMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFE8ECF0)
                  : const Color(0xFF1A1A2E),
            ),
          ),

          const SizedBox(width: 8),

          // Vertical divider
          Container(
            width: 1,
            height: 14,
            color: isDark
                ? const Color(0xFF1E2733)
                : const Color(0xFFE2E6EA),
          ),

          const SizedBox(width: 8),

          // Pulsing dot
          _PulsingDot(color: statusColor),
          const SizedBox(width: 4),

          // Market status label
          Text(
            statusLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// Pulsing dot animation for live indicator
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
