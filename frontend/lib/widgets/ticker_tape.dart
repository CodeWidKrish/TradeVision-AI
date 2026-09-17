import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TickerItem {
  final String symbol;
  final String change;
  final bool isPositive;

  const TickerItem({
    required this.symbol,
    required this.change,
    required this.isPositive,
  });
}

class TickerTapeWidget extends StatefulWidget {
  const TickerTapeWidget({super.key});

  @override
  State<TickerTapeWidget> createState() => _TickerTapeWidgetState();
}

class _TickerTapeWidgetState extends State<TickerTapeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<TickerItem> _items = [
    TickerItem(symbol: 'NIFTY 50', change: '+0.11%', isPositive: true),
    TickerItem(symbol: 'SENSEX', change: '+0.45%', isPositive: true),
    TickerItem(symbol: 'NIFTY BANK', change: '-0.05%', isPositive: false),
    TickerItem(symbol: 'NIFTY IT', change: '-0.88%', isPositive: false),
    TickerItem(symbol: 'RELIANCE', change: '+1.24%', isPositive: true),
    TickerItem(symbol: 'TCS', change: '+2.09%', isPositive: true),
    TickerItem(symbol: 'HDFCBANK', change: '+1.15%', isPositive: true),
    TickerItem(symbol: 'INFY', change: '+3.52%', isPositive: true),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              const double itemWidth = 140.0;
              final double totalWidth = _items.length * itemWidth;
              final double offset = _controller.value * totalWidth;

              return ClipRect(
                child: OverflowBox(
                  minWidth: totalWidth * 3,
                  maxWidth: totalWidth * 3,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._buildItemList(context),
                        ..._buildItemList(context),
                        ..._buildItemList(context),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildItemList(BuildContext context) {
    final symbolColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8892A4)
        : const Color(0xFF64748B);

    return _items.map((item) {
      return Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                item.symbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: symbolColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.change,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: item.isPositive
                    ? const Color(0xFF00C853)
                    : const Color(0xFFFF3B3B),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
