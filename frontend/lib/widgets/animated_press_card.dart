import 'package:flutter/material.dart';

class AnimatedPressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const AnimatedPressCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
  });

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (mounted) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (mounted) setState(() => _isPressed = false);
      },
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
