import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../widgets/ticker_tape.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _tickerController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Text fade
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Ticker scroll
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Start sequence
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // Navigate after 2.8s
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      final bool isLoggedIn = StorageService.getIsLoggedIn();
      final bool hasOnboarded = StorageService.hasOnboarded();
      if (isLoggedIn) {
        context.go('/home');
      } else {
        context.go(hasOnboarded ? '/auth' : '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [Color(0x1A0066CC), Color(0x000A0E1A)],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo + wordmark
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        // App Brand Icon
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066CC), Color(0xFF0044AA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066CC).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.show_chart_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Wordmark
                        FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Trade',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Vision',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0066CC),
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'MARKET INTELLIGENCE PLATFORM',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8892A4),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Ticker tape at bottom
                const SizedBox(
                  height: 36,
                  child: TickerTapeWidget(),
                ),

                const SizedBox(height: 40),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: const Color(0xFF1E2733),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0066CC),
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Loading market data...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8892A4),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
