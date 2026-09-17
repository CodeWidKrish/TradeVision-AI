import 'package:flutter/material.dart';

enum LogoVariant { iconOnly, fullStacked }

class TVLogoWidget extends StatelessWidget {
  final LogoVariant variant;
  final double size;

  const TVLogoWidget({
    super.key,
    this.variant = LogoVariant.iconOnly,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LogoVariant.iconOnly:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0077FF).withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF00FF88).withOpacity(0.20),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Image.asset(
              'assets/images/logo_icon.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        );

      case LogoVariant.fullStacked:
        return Image.asset(
          'assets/images/logo_full.png',
          width: size * 1.2,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
    }
  }
}
