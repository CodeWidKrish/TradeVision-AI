import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/storage_service.dart';
import 'onboarding_page_1.dart';
import 'onboarding_page_2.dart';
import 'onboarding_page_3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    await StorageService.setOnboarded();
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Stack(
          children: [
            // PageView Container
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                OnboardingPage1(onContinue: _nextPage),
                OnboardingPage2(onContinue: _nextPage),
                OnboardingPage3(onGetStarted: _skip),
              ],
            ),

            // Top-Right Skip Button (Hidden on page 0, visible on page 1+)
            Positioned(
              top: statusBarHeight + 8,
              right: 16,
              child: AnimatedOpacity(
                opacity: _currentPage > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _currentPage > 0
                    ? SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(60, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8892A4),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Bottom Fixed Controls Section (Dots + CTA Button)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
                color: const Color(0xFF0A0E1A),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Dot Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0066CC)
                                : const Color(0xFF2A3244),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Dynamic CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getButtonColor(_currentPage),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _buildButtonContent(_currentPage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor(int page) {
    switch (page) {
      case 0:
        return const Color(0xFF0066CC);
      case 1:
        return const Color(0xFF00C853);
      case 2:
      default:
        return const Color(0xFFFF8C00);
    }
  }

  Widget _buildButtonContent(int page) {
    if (page == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.white,
          ),
        ],
      );
    }

    return Text(
      'Continue',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
