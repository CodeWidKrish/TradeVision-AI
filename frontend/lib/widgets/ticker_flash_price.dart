import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A financial price widget that briefly flashes a subtle green or red
/// background pulse whenever the price ticks up or down.
class TickerFlashPrice extends StatefulWidget {
  final double price;
  final String? formattedPrice;
  final TextStyle? textStyle;
  final Alignment alignment;

  const TickerFlashPrice({
    super.key,
    required this.price,
    this.formattedPrice,
    this.textStyle,
    this.alignment = Alignment.centerLeft,
  });

  @override
  State<TickerFlashPrice> createState() => _TickerFlashPriceState();
}

class _TickerFlashPriceState extends State<TickerFlashPrice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _flashColorAnimation;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flashColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant TickerFlashPrice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      final isUp = widget.price > (oldWidget.price);
      _flashColor = isUp
          ? const Color(0xFF00C853).withValues(alpha: 0.28)
          : const Color(0xFFFF3B3B).withValues(alpha: 0.28);

      _flashColorAnimation = ColorTween(
        begin: _flashColor,
        end: Colors.transparent,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = GoogleFonts.robotoMono(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _flashColorAnimation.value ?? Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: widget.alignment,
            child: Text(
              widget.formattedPrice ?? '₹${widget.price.toStringAsFixed(2)}',
              style: widget.textStyle ?? defaultStyle,
              maxLines: 1,
            ),
          ),
        );
      },
    );
  }
}
