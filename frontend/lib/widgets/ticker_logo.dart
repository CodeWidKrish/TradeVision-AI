import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static const Map<String, String> _vectorSvgStrings = {
    'RELIANCE':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#0A2540"/><circle cx="50" cy="38" r="22" stroke="#FFD700" stroke-width="3" fill="#0C2F52"/><path d="M50 22 C44 30 42 36 46 42 C48 46 52 46 54 42 C58 36 56 30 50 22 Z" fill="#FFC72C"/><path d="M50 27 C47 32 46 36 49 40 C50 42 52 42 53 40 C55 36 54 32 50 27 Z" fill="#FF4500"/><text x="50" y="78" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="13" font-weight="800" letter-spacing="0.5">Reliance</text></svg>',
    'TCS':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#051937"/><text x="50" y="36" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="12" font-weight="700" letter-spacing="3.5">TATA</text><text x="47" y="70" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="28" font-weight="900" letter-spacing="1">tcs</text><circle cx="75" cy="50" r="4.5" fill="#00D2FF"/><circle cx="75" cy="50" r="2" fill="#FFFFFF"/></svg>',
    'TATASTEEL':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#002D62"/><path d="M26 34 L74 34 L62 66 L38 66 Z" fill="#0072CE"/><text x="50" y="54" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="13" font-weight="800" letter-spacing="2">TATA</text><text x="50" y="82" text-anchor="middle" fill="#A4C2F4" font-family="system-ui,-apple-system,sans-serif" font-size="11" font-weight="700">STEEL</text></svg>',
    'TATAMOTORS':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#003366"/><ellipse cx="50" cy="38" rx="28" ry="18" stroke="#FFFFFF" stroke-width="3.5" fill="none"/><path d="M50 23 L50 53 M38 33 C45 28 55 28 62 33" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" fill="none"/><text x="50" y="76" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="12" font-weight="800" letter-spacing="3">TATA</text></svg>',
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
    'ITC':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#0B3C68"/><polygon points="50,20 78,72 22,72" fill="#FFC20E"/><text x="50" y="65" text-anchor="middle" fill="#0B3C68" font-family="system-ui,-apple-system,sans-serif" font-size="18" font-weight="900">ITC</text></svg>',
    'MARUTI':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#FFFFFF"/><path d="M70 24 L32 24 L30 38 L66 46 L70 58 L30 68 L30 63 L63 55 L59 45 L30 37 L30 18 L70 18 Z" fill="#E31B23"/><text x="50" y="86" text-anchor="middle" fill="#1C2D42" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="800" letter-spacing="1">SUZUKI</text></svg>',
    'BHARTIARTL':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#ED1C24"/><path d="M35 68 C35 45 42 32 54 32 C65 32 68 42 68 50 C68 62 58 68 50 68" stroke="#FFFFFF" stroke-width="6" fill="none" stroke-linecap="round"/><circle cx="50" cy="50" r="4" fill="#FFFFFF"/><text x="50" y="88" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="11" font-weight="800">airtel</text></svg>',
    'PAYTM':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#002E6E"/><text x="50" y="58" text-anchor="middle" fill="#00BAF2" font-family="system-ui,-apple-system,sans-serif" font-size="20" font-weight="900">Paytm</text></svg>',
    'KOTAKBANK':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#ED1C24"/><path d="M28 50 C28 38 38 38 45 45 C52 52 62 52 72 45 C65 38 55 38 48 45 C41 52 35 52 28 50 Z" fill="#FFFFFF"/><circle cx="36" cy="50" r="5" fill="#FFFFFF"/><circle cx="64" cy="50" r="5" fill="#FFFFFF"/><text x="50" y="80" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="11" font-weight="900" letter-spacing="1">KOTAK</text></svg>',
    'AXISBANK':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#97144D"/><polygon points="50,18 78,74 62,74 50,48 38,74 22,74" fill="#FFFFFF"/><text x="50" y="90" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="800" letter-spacing="1">AXIS BANK</text></svg>',
    'LT':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#003580"/><circle cx="50" cy="42" r="28" fill="#FFCC00"/><text x="50" y="52" text-anchor="middle" fill="#003580" font-family="system-ui,-apple-system,sans-serif" font-size="24" font-weight="900">L&amp;T</text><text x="50" y="86" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="9" font-weight="700" letter-spacing="1">LARSEN &amp; TOUBRO</text></svg>',
    'ADANIENT':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#1C3F73"/><path d="M22 62 C34 36 66 36 78 62" stroke="#4A90E2" stroke-width="7" stroke-linecap="round" fill="none"/><path d="M30 68 C40 48 60 48 70 68" stroke="#F5A623" stroke-width="5" stroke-linecap="round" fill="none"/><text x="50" y="86" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="11" font-weight="800" letter-spacing="1">ADANI</text></svg>',
    'SUNPHARMA':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#F36F21"/><circle cx="50" cy="40" r="16" fill="#FFFFFF"/><path d="M50 14 L50 20 M50 60 L50 66 M24 40 L30 40 M70 40 L76 40 M32 22 L36 26 M64 54 L68 58 M32 58 L36 54 M64 26 L68 22" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/><text x="50" y="82" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="800" letter-spacing="1">SUN PHARMA</text></svg>',
    'HINDUNILVR':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#001F60"/><path d="M34 26 C34 56 66 56 66 26" stroke="#00A3E0" stroke-width="8" stroke-linecap="round" fill="none"/><circle cx="50" cy="38" r="6" fill="#FFD700"/><text x="50" y="78" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="11" font-weight="800">HUL</text></svg>',
    'TITAN':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#111111"/><circle cx="50" cy="38" r="20" stroke="#C5A059" stroke-width="3" fill="none"/><path d="M50 24 L50 40 L60 40" stroke="#C5A059" stroke-width="2.5" stroke-linecap="round" fill="none"/><text x="50" y="78" text-anchor="middle" fill="#C5A059" font-family="system-ui,-apple-system,sans-serif" font-size="14" font-weight="900" letter-spacing="2">TITAN</text></svg>',
    'ASIANPAINT':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#E31B23"/><circle cx="42" cy="40" r="14" fill="#FFCC00"/><circle cx="58" cy="40" r="14" fill="#00A3E0" opacity="0.85"/><text x="50" y="78" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="900" letter-spacing="0.5">asianpaints</text></svg>',
    'HCLTECH':
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" rx="22" fill="#002D62"/><text x="50" y="52" text-anchor="middle" fill="#00B0FF" font-family="system-ui,-apple-system,sans-serif" font-size="22" font-weight="900">HCL</text><text x="50" y="74" text-anchor="middle" fill="#FFFFFF" font-family="system-ui,-apple-system,sans-serif" font-size="11" font-weight="700" letter-spacing="1">TECH</text></svg>',
  };

  static const Map<String, String> _domainMap = {
    'RELIANCE': 'ril.com', 'TCS': 'tcs.com', 'HDFCBANK': 'hdfcbank.com', 'INFY': 'infosys.com',
    'TATASTEEL': 'tatasteel.com', 'TATAMOTORS': 'tatamotors.com', 'TATACHEM': 'tatachemicals.com',
    'TATAPOWER': 'tatapower.com', 'TATACOMM': 'tatacommunications.com', 'TATAELXSI': 'tataelxsi.com',
    'TATACONSUM': 'tataconsumer.com', 'ITC': 'itcportal.com', 'HINDUNILVR': 'hul.co.in',
    'BHARTIARTL': 'airtel.in', 'LT': 'larsentoubro.com', 'ICICIBANK': 'icicibank.com',
    'SBIN': 'sbi.co.in', 'KOTAKBANK': 'kotak.com', 'AXISBANK': 'axisbank.com',
    'BAJFINANCE': 'bajajfinserv.in', 'BAJAJFINSV': 'bajajfinserv.in', 'BAJAJ-AUTO': 'bajajauto.com',
    'ASIANPAINT': 'asianpaints.com', 'MARUTI': 'marutisuzuki.com', 'TITAN': 'titancompany.in',
    'SUNPHARMA': 'sunpharma.com', 'ULTRACEMCO': 'ultratechcement.com', 'WIPRO': 'wipro.com',
    'HCLTECH': 'hcltech.com', 'ONGC': 'ongcindia.com', 'NTPC': 'ntpc.co.in', 'POWERGRID': 'powergrid.in',
    'COALINDIA': 'coalindia.in', 'IOC': 'iocl.com', 'BPCL': 'bharatpetroleum.in', 'JSWSTEEL': 'jsw.in',
    'HINDALCO': 'hindalco.com', 'VEDL': 'vedantalimited.com', 'ADANIENT': 'adani.com',
    'ADANIPORTS': 'adaniports.com', 'ADANIGREEN': 'adanigreenenergy.com', 'ADANIPOWER': 'adanipower.com',
    'ATGL': 'adanigas.com', 'ZOMATO': 'zomato.com', 'PAYTM': 'paytm.com', 'ONE97': 'paytm.com',
    'POLICYBZR': 'policybazaar.com', 'NYKAA': 'nykaa.com', 'SWIGGY': 'swiggy.com', 'IRCTC': 'irctc.co.in',
    'BEL': 'bel-india.in', 'HAL': 'hal-india.co.in', 'DRREDDY': 'drreddys.com', 'CIPLA': 'cipla.com',
    'DIVISLAB': 'divislabs.com', 'APOLLOHOSP': 'apollohospitals.com', 'BRITANNIA': 'britannia.co.in',
    'NESTLEIND': 'nestle.in', 'DABUR': 'dabur.com', 'GODREJCP': 'godrejcp.com', 'MARICO': 'marico.com',
    'PIDILITIND': 'pidilite.com', 'SIEMENS': 'siemens.co.in', 'EICHERMOT': 'eicher.in',
    'HEROMOTOCO': 'heromotocorp.com', 'TVSMOTOR': 'tvsmotor.com', 'DLF': 'dlf.in',
    'TRENT': 'trentlimited.com', 'LTIM': 'ltimindtree.com', 'PERSISTENT': 'persistent.com',
    'COFORGE': 'coforge.com', 'MPHASIS': 'mphasis.com', 'INDUSINDBK': 'indusind.com',
    'MUTHOOTFIN': 'muthootfinance.com', 'CHOLAFIN': 'cholamandalam.com', 'SHREECEM': 'shreecement.com',
    'AMBUJACEM': 'ambujacement.com', 'BOSCHLTD': 'bosch.in', 'HAVELLS': 'havells.com',
    'GAIL': 'gailonline.com', 'PNB': 'pnbindia.in', 'BANKBARODA': 'bankofbaroda.in',
    'VOLTAS': 'voltas.com', 'BHEL': 'bhel.com', 'NMDC': 'nmdc.co.in', 'SAIL': 'sail.co.in',
    'SUZLON': 'suzlon.com', 'IRFC': 'irfc.co.in', 'RVNL': 'rvnl.org', '3MINDIA': '3mindia.in',
  };

  String get _cleanTicker {
    return ticker.replaceAll('.NS', '').replaceAll('.BO', '').toUpperCase().trim();
  }

  String get _initials {
    if (_cleanTicker.length <= 3) return _cleanTicker;
    return _cleanTicker.substring(0, 3);
  }

  String get _domain {
    if (logoUrl.isNotEmpty) {
      if (logoUrl.contains('clearbit.com/')) {
        return logoUrl.split('clearbit.com/').last.split('?').first;
      }
      if (logoUrl.contains('favicons?domain=')) {
        return logoUrl.split('favicons?domain=').last.split('&').first;
      }
      if (logoUrl.startsWith('http')) {
        try {
          return Uri.parse(logoUrl).host;
        } catch (_) {}
      }
      return logoUrl;
    }
    return _domainMap[_cleanTicker] ?? '${_cleanTicker.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com';
  }

  Color _generateBrandColor() {
    final h = _cleanTicker.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      const Color(0xFF0066CC),
      const Color(0xFF00C853),
      const Color(0xFF7C3AED),
      const Color(0xFFEA580C),
      const Color(0xFF0284C7),
      const Color(0xFFD97706),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFF4F46E5),
      const Color(0xFF0891B2),
    ];
    return colors[h % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.36;
    final svgString = _vectorSvgStrings[_cleanTicker];
    final bool hasSvg = svgString != null;
    final brandColor = _generateBrandColor();

    Widget content;

    // 1. Primary: Inlined official vector brand SVG
    if (hasSvg) {
      content = SvgPicture.string(
        svgString,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    // 2. Secondary: Instant edge-cached favicon with zero-delay frameBuilder badge
    else {
      final domain = _domain;
      final googleIconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
      final backendLogoUrl = 'http://127.0.0.1:8000/api/live/logo/$_cleanTicker';

      content = Image.network(
        googleIconUrl,
        width: size * 0.78,
        height: size * 0.78,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildBrandedBadge(fontSize, brandColor);
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            backendLogoUrl,
            width: size * 0.78,
            height: size * 0.78,
            fit: BoxFit.contain,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return _buildBrandedBadge(fontSize, brandColor);
            },
            errorBuilder: (_, __, ___) => _buildBrandedBadge(fontSize, brandColor),
          );
        },
      );
    }

    final effectiveRadius = borderRadius ?? (size * 0.28);

    final logoContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasSvg ? Colors.transparent : brandColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: hasSvg
              ? Colors.white.withValues(alpha: 0.15)
              : brandColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _buildBrandedBadge(double fontSize, Color brandColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandColor.withValues(alpha: 0.90),
            brandColor.withValues(alpha: 0.50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.domain_rounded,
              size: size * 0.36,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 1),
            Text(
              _initials,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
