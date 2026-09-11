import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipeToExecuteButton extends StatefulWidget {
  final bool isBuy;
  final String stockTicker;
  final String priceFormatted;
  final int quantity;
  final VoidCallback onConfirmed;

  const SwipeToExecuteButton({
    super.key,
    required this.isBuy,
    required this.stockTicker,
    required this.priceFormatted,
    this.quantity = 1,
    required this.onConfirmed,
  });

  @override
  State<SwipeToExecuteButton> createState() => _SwipeToExecuteButtonState();
}

class _SwipeToExecuteButtonState extends State<SwipeToExecuteButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isExecuted = false;
  late AnimationController _animController;
  late Animation<double> _checkScaleAnimation;

  static const double _buttonHeight = 58.0;
  static const double _thumbSize = 48.0;
  static const double _thumbPadding = 5.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkScaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isExecuted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isExecuted) return;
    if (_dragPosition >= maxDrag * 0.82) {
      // Trigger execution
      setState(() {
        _dragPosition = maxDrag;
        _isExecuted = true;
      });
      HapticFeedback.heavyImpact();
      _animController.forward();
      widget.onConfirmed();
    } else {
      // Spring back to start
      setState(() {
        _dragPosition = 0.0;
      });
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        widget.isBuy ? const Color(0xFF00C853) : const Color(0xFFFF3B3B);
    final trackBg = isDark
        ? (widget.isBuy ? const Color(0xFF0A2E1A) : const Color(0xFF330E0E))
        : (widget.isBuy ? const Color(0xFFE8F8EE) : const Color(0xFFFFEEEE));
    final borderTrack = isDark
        ? primaryColor.withOpacity(0.35)
        : primaryColor.withOpacity(0.45);

    if (_isExecuted) {
      return Container(
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: ScaleTransition(
            scale: _checkScaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${widget.isBuy ? "BOUGHT" : "SOLD"} ${widget.quantity} ${widget.stockTicker} • EXECUTED',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - (_thumbPadding * 2);
        final progress = (maxDrag > 0) ? (_dragPosition / maxDrag) : 0.0;

        return Container(
          height: _buttonHeight,
          decoration: BoxDecoration(
            color: trackBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderTrack, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Dynamic Fill Progress Bar
              Container(
                width: _dragPosition + _thumbSize + (_thumbPadding * 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.20),
                      primaryColor.withOpacity(0.45),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.3)).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36, right: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.isBuy
                                ? 'SWIPE TO BUY • ${widget.priceFormatted}'
                                : 'SWIPE TO SELL • ${widget.priceFormatted}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: primaryColor.withOpacity(0.8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Draggable Slider Thumb
              Positioned(
                left: _thumbPadding + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) =>
                      _onDragEnd(details, maxDrag),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isBuy
                            ? [const Color(0xFF00E676), const Color(0xFF00C853)]
                            : [const Color(0xFFFF5252), const Color(0xFFFF1744)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.isBuy
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
