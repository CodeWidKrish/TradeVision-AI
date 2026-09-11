import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TickerLogo extends StatelessWidget {
  final String ticker;
  final String logoUrl;
  final Color logoColor;
  final double size;
  final double? borderRadius;
  final String? heroTag;

  const TickerLogo({
    super.key,
    required this.ticker,
    this.logoUrl = '',
    this.logoColor = const Color(0xFF0066CC),
    this.size = 40.0,
    this.borderRadius,
    this.heroTag,
  });

  /// Official brand vector SVGs inlined for 100% reliable, zero-latency rendering
  /// across Web CanvasKit, mobile, and desktop without HTTP requests or asset-manifest lag.
  static const Map<String, String> _vectorSvgStrings = {
    'RELIANCE':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#0A2540"/><circle cx="50" cy="38" r="22" stroke="#FFD700" stroke-width="3" fill="#0C2F52"/><path d="M50 22 C44 30 42 36 46 42 C48 46 52 46 54 42 C58 36 56 30 50 22 Z" fill="#FFC72C"/><path d="M50 27 C47 32 46 36 49 40 C50 42 52 42 53 40 C55 36 54 32 50 27 Z" fill="#FF4500"/><text x="50" y="78" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="13" font-weight="800" letter-spacing="0.5">Reliance</text></svg>',
    'TCS':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#051937"/><text x="50" y="36" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="12" font-weight="700" letter-spacing="3.5">TATA</text><text x="47" y="70" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="28" font-weight="900" letter-spacing="1">tcs</text><circle cx="75" cy="50" r="4.5" fill="#00D2FF"/><circle cx="75" cy="50" r="2" fill="#FFFFFF"/></svg>',
    'HDFCBANK':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#004C8F"/><rect x="20" y="20" width="60" height="60" rx="6" fill="#FFFFFF"/><rect x="24" y="24" width="22" height="22" rx="3" fill="#ED232A"/><rect x="54" y="24" width="22" height="22" rx="3" fill="#ED232A"/><rect x="24" y="54" width="22" height="22" rx="3" fill="#ED232A"/><rect x="54" y="54" width="22" height="22" rx="3" fill="#ED232A"/><rect x="39" y="39" width="22" height="22" rx="3" fill="#004C8F"/></svg>',
    'INFY':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#007CC3"/><text x="50" y="58" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="22" font-weight="700" letter-spacing="-0.5">infosys</text><rect x="22" y="66" width="56" height="3.5" rx="1.75" fill="#FFC72C"/></svg>',
    'WIPRO':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#FFFFFF"/><circle cx="41" cy="33" r="9" fill="#00AEEF" opacity="0.95"/><circle cx="59" cy="33" r="9" fill="#8DC63F" opacity="0.95"/><circle cx="36" cy="45" r="9" fill="#92278F" opacity="0.9"/><circle cx="64" cy="45" r="9" fill="#F7941D" opacity="0.9"/><circle cx="50" cy="41" r="10" fill="#ED1C24" opacity="0.95"/><text x="50" y="75" text-anchor="middle" fill="#231F20" font-family="system-ui,-apple-system,sans-serif" font-size="16" font-weight="700" letter-spacing="-0.5">wipro</text></svg>',
    'SBIN':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#152438"/><circle cx="50" cy="44" r="28" fill="#00A3E0"/><circle cx="50" cy="51" r="7.5" fill="#152438"/><rect x="46.5" y="51" width="7" height="21" fill="#152438"/><text x="50" y="87" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="700" letter-spacing="2">SBI</text></svg>',
    'ICICIBANK':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#8F1424"/><circle cx="50" cy="28" r="7" fill="#F37021"/><path d="M44 40 C44 37 47 35 51 35 C55 35 57 37 57 41 L57 61 C64 61 68 59 71 56 L71 63 C67 67 61 69 51 69 C43 69 41 65 41 58 L41 40 Z" fill="#F37021"/><path d="M32 44 C37 39 42 39 46 43 L46 47 C42 44 38 44 34 47 Z" fill="#FFC20E"/><text x="50" y="86" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="9" font-weight="800" letter-spacing="1">ICICI BANK</text></svg>',
    'BAJFINANCE':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#003399"/><path d="M22 36 C32 36 40 43 46 55 C40 50 32 46 22 46 Z" fill="#00D2FF"/><path d="M78 36 C68 36 60 43 54 55 C60 50 68 46 78 46 Z" fill="#00D2FF"/><path d="M28 26 C40 26 50 38 50 58 C50 38 60 26 72 26 C58 26 50 41 50 49 C50 41 42 26 28 26 Z" fill="#FFFFFF"/><text x="50" y="78" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="13" font-weight="900" letter-spacing="2">BAJAJ</text></svg>',
    'ZOMATO':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#E23744"/><text x="50" y="58" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="22" font-weight="900" font-style="italic" letter-spacing="-0.5">zomato</text><path d="M28 66 Q50 74 72 66" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.85"/></svg>',
    'TATAMOTORS':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#003366"/><ellipse cx="50" cy="38" rx="28" ry="18" stroke="#FFFFFF" stroke-width="3.5" fill="none"/><path d="M50 23 L50 53 M38 33 C45 28 55 28 62 33" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" fill="none"/><text x="50" y="76" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="12" font-weight="800" letter-spacing="3">TATA</text></svg>',
    'MARUTI':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#FFFFFF"/><path d="M70 24 L32 24 L30 38 L66 46 L70 58 L30 68 L30 63 L63 55 L59 45 L30 37 L30 18 L70 18 Z" fill="#E31B23"/><text x="50" y="86" text-anchor="middle" fill="#1C2D42" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="800" letter-spacing="1">SUZUKI</text></svg>',
  };

  String get _cleanTicker {
    return ticker.replaceAll('.NS', '').replaceAll('.BO', '').toUpperCase().trim();
  }

  String get _initials {
    if (_cleanTicker.length <= 3) return _cleanTicker;
    return _cleanTicker.substring(0, 3);
  }

  /// Extract main website domain from stock logoUrl or websiteUrl
  String get _domain {
    if (logoUrl.contains('clearbit.com/')) {
      return logoUrl.split('clearbit.com/').last;
    }
    if (logoUrl.contains('favicons?domain=')) {
      return logoUrl.split('favicons?domain=').last.split('&').first;
    }
    return logoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.35;
    final svgString = _vectorSvgStrings[_cleanTicker];
    final bool hasSvg = svgString != null;

    Widget content;

    // 1. Primary: Official Inlined Vector Brand SVG
    if (hasSvg) {
      content = SvgPicture.string(
        svgString,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    // 2. Secondary: Network Brand Logo with CORS-safe fallback
    else if (logoUrl.isNotEmpty && (logoUrl.startsWith('http') || logoUrl.startsWith('https'))) {
      final primaryLogoUrl = _domain.contains('http')
          ? _domain
          : 'https://www.google.com/s2/favicons?domain=$_domain&sz=128';

      content = Image.network(
        primaryLogoUrl,
        width: size * 0.75,
        height: size * 0.75,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          final secondaryLogoUrl = 'https://logo.clearbit.com/$_domain';
          return Image.network(
            secondaryLogoUrl,
            width: size * 0.75,
            height: size * 0.75,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildInitialsFallback(fontSize),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitialsFallback(fontSize);
        },
      );
    }
    // 3. Fallback: Branded Initials
    else {
      content = _buildInitialsFallback(fontSize);
    }

    final effectiveRadius = borderRadius ?? (size * 0.25);

    final logoContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasSvg ? Colors.transparent : logoColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: hasSvg ? Colors.white.withValues(alpha: 0.15) : logoColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: content),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          return Material(
            color: Colors.transparent,
            child: toHeroContext.widget,
          );
        },
        child: logoContainer,
      );
    }

    return logoContainer;
  }

  Widget _buildInitialsFallback(double fontSize) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: logoColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
