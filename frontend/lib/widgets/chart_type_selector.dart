import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/ohlc_point.dart';

class ChartHeaderRow extends StatelessWidget {
  final List<String> periods;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final ChartType selectedType;
  final ValueChanged<ChartType> onTypeChanged;

  const ChartHeaderRow({
    super.key,
    required this.periods,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: periods.map((p) {
                final isSelected = p == selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _PeriodPill(
                    label: p,
                    selected: isSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPeriodChanged(p);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ChartTypeIconToggle(
          selected: selectedType,
          onChanged: onTypeChanged,
        ),
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0066CC)
              : (isDark ? const Color(0xFF141A26) : const Color(0xFFF1F3F6)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF8892A4),
          ),
        ),
      ),
    );
  }
}

class _ChartTypeIconToggle extends StatelessWidget {
  final ChartType selected;
  final ValueChanged<ChartType> onChanged;

  const _ChartTypeIconToggle({
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    (ChartType.line, Icons.show_chart_rounded, 'Line chart'),
    (ChartType.candlestick, Icons.candlestick_chart_rounded, 'Candlestick chart'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141A26) : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((opt) {
          final (type, icon, tooltip) = opt;
          final isSelected = type == selected;
          return Tooltip(
            message: tooltip,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066CC) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF8892A4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Keep ChartTypeSelector as alias/wrapper for backward compatibility
class ChartTypeSelector extends StatelessWidget {
  final ChartType selected;
  final ValueChanged<ChartType> onChanged;

  const ChartTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartTypeIconToggle(
      selected: selected,
      onChanged: onChanged,
    );
  }
}
