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
        return Image.asset(
          'assets/images/logo_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
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
