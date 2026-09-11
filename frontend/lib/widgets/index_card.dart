import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndexCard extends StatelessWidget {
  final String name;
  final String value;
  final String change;
  final String? changePercent;
  final bool isPositive;
  final bool isSelected;
  final VoidCallback? onTap;

  const IndexCard({
    super.key,
    required this.name,
    required this.value,
    required this.change,
    this.changePercent,
    required this.isPositive,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayChange = changePercent != null && changePercent!.isNotEmpty
        ? '$change $changePercent'
        : change;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? const Color(0xFF1A2332) : const Color(0xFF111827))
              : (isSelected ? Colors.white : const Color(0xFFF4F6F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066CC)
                : (isDark
                    ? const Color(0xFF1E2733)
                    : const Color(0xFFE2E6EA)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF0066CC).withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: isSelected
                      ? const Color(0xFF0066CC)
                      : const Color(0xFF8892A4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.robotoMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayChange,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPositive
                            ? const Color(0xFF00C853)
                            : const Color(0xFFFF3B3B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
