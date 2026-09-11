import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/security_service.dart';

// Safe image loader — never crashes if image fails
class SafeNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width = 40,
    this.height = 40,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A3A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image_outlined,
            size: 16, color: Color(0xFF8892A4)),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF0066CC),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Safe price display — never shows null or NaN
class SafePriceText extends StatelessWidget {
  final dynamic value;
  final String prefix;
  final TextStyle? style;

  const SafePriceText({
    super.key,
    required this.value,
    this.prefix = '₹',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = SecurityService.safeParseDouble(value);
    final formatted = NumberFormat('#,##,##0.00', 'en_IN').format(parsed);
    return Text(
      '$prefix$formatted',
      style: style ?? GoogleFonts.robotoMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE8ECF0),
      ),
    );
  }
}

// Safe async builder — shows loading/error states cleanly
class SafeAsyncWidget<T> extends StatelessWidget {
  final Future<T?> future;
  final Widget Function(T data) builder;
  final String loadingMessage;
  final String errorMessage;

  const SafeAsyncWidget({
    super.key,
    required this.future,
    required this.builder,
    this.loadingMessage = 'Loading...',
    this.errorMessage = 'Something went wrong. Please try again.',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF0066CC), strokeWidth: 2),
                const SizedBox(height: 12),
                Text(loadingMessage,
                  style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF8892A4))),
              ],
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: Color(0xFF8892A4), size: 36),
                const SizedBox(height: 12),
                Text(errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF8892A4))),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => (context as Element).markNeedsBuild(),
                  child: Text('Tap to retry',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0066CC))),
                ),
              ],
            ),
          );
        }
        return builder(snapshot.data as T);
      },
    );
  }
}
