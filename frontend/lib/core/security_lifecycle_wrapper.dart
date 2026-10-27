import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'security_service.dart';

/// Wraps TradeVision with enterprise-grade application lifecycle protection.
///
/// Features:
/// 1. App Switcher Privacy Shield: When user minimizes the app or opens the OS
///    task switcher, immediately overlays a frosted privacy shield with zero
///    data leakage to prevent bystanders or background screenshots from capturing
///    sensitive portfolio numbers, P&L, or positions.
/// 2. Post-Frame Notification Engine Handshake: Safely prompts for Android 13+
///    POST_NOTIFICATIONS runtime permission *after* the foreground Activity is mounted.
/// 3. Inactivity Guard: Tracks background transitions and verifies session timestamps.
class AppLifecycleSecurityWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleSecurityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleSecurityWrapper> createState() => _AppLifecycleSecurityWrapperState();
}

class _AppLifecycleSecurityWrapperState extends State<AppLifecycleSecurityWrapper>
    with WidgetsBindingObserver {
  bool _isMasked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Safely request notification permission after UI renders first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safelyPromptNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _safelyPromptNotifications() async {
    try {
      await NotificationService.instance.requestPermission();
    } catch (e) {
      debugPrint('[SecurityWrapper] Notification permission handshake deferred: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SecurityService.recordActivity();

    // 1. Web browsers do not use OS app switcher thumbnails and tab switching
    // causes spurious inactive/paused events that would trap web users in black screens.
    if (kIsWeb) return;

    // 2. Never mask authentication, onboarding, or splash screens
    final isLoggedIn = StorageService.getIsLoggedIn();
    if (!isLoggedIn) {
      if (_isMasked) setState(() => _isMasked = false);
      return;
    }

    final privacyEnabled = StorageService.isPrivacyMaskEnabled();

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (privacyEnabled && !_isMasked) {
        setState(() => _isMasked = true);
      }
    } else if (state == AppLifecycleState.resumed || state == AppLifecycleState.detached) {
      if (_isMasked) {
        setState(() => _isMasked = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (_isMasked) {
          setState(() => _isMasked = false);
        }
      },
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          if (_isMasked && !kIsWeb && StorageService.getIsLoggedIn())
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _isMasked = false),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  builder: (context, opacity, _) {
                    return Opacity(
                      opacity: opacity,
                      child: ClipRect(
                        child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        color: const Color(0xE60A0E1A), // deep sapphire obsidian cover
                        alignment: Alignment.center,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0066CC), Color(0xFF003366)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0066CC).withValues(alpha: 0.35),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'TradeVision AI',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF00C853), // active green indicator
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Institutional Privacy Shield Active',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF8892A4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}
