import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Official Logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2F6), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/logo_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TradeVision AI',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Terms of Service & Risk Disclaimer',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Effective: January 2026 • Mumbai, India',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Highlighted SEBI Risk Warning Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF8C00),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MANDATORY RISK DISCLAIMER',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF8C00),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trading in equities, futures, and options involves significant market risk. 9 out of 10 individual traders incur net losses in the derivatives segment according to SEBI studies. TradeVision does not guarantee trading returns.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textColor,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.assignment_outlined,
                title: '1. Agreement to Terms',
                content:
                    'By downloading, accessing, or using the TradeVision application (web or mobile), you acknowledge that you have read, understood, and agreed to be legally bound by these Terms and Conditions and our Privacy Policy. If you do not agree, discontinue use immediately.',
              ),

              const SizedBox(height: 16),

              // Section 2
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.gavel_rounded,
                title: '2. Educational Purpose & Not Investment Advice',
                content:
                    '• TradeVision is an analytical fintech platform designed strictly for educational and simulation purposes.\n'
                    '• TradeVision AI and its operators are NOT registered as Investment Advisers or Research Analysts under SEBI (Investment Advisers) Regulations, 2013.\n'
                    '• No commentary, signal, chart pattern recognition, or prediction constitutes a financial offer, solicitation, or personal investment advice.\n'
                    '• All live market quotes and news are derived from automated public APIs.',
              ),

              const SizedBox(height: 16),

              // Section 3
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.account_balance_wallet_outlined,
                title: '3. Virtual Paper Trading Rules',
                content:
                    '• Paper trading simulates order execution using fictitious demo capital (₹10,00,000 virtual balance).\n'
                    '• Virtual cash, positions, and unrealized profits have no monetary value, cannot be redeemed for real currency, and do not represent true liquidity or execution slippage found in real exchange order books.',
              ),

              const SizedBox(height: 16),

              // Section 4
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.lock_person_outlined,
                title: '4. Account Security & App Lock',
                content:
                    '• You are responsible for maintaining the confidentiality of your PIN, password, and biometric lock configurations.\n'
                    '• Any actions taken within your authenticated session are deemed your responsibility. TradeVision provides built-in biometric security and session expiration to assist in preventing unauthorized local access.',
              ),

              const SizedBox(height: 16),

              // Section 5
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.copyright_rounded,
                title: '5. Intellectual Property & License',
                content:
                    '• All visual interfaces, algorithms, FinBERT sentiment implementations, and proprietary TradeVision branding are protected under Indian and international copyright laws.\n'
                    '• Open-source components are licensed under their respective MIT/Apache 2.0 terms, viewable in the official Licenses section.',
              ),

              const SizedBox(height: 16),

              // Section 6
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.balance_rounded,
                title: '6. Governing Law & Jurisdiction',
                content:
                    'These Terms shall be governed and interpreted in accordance with the substantive laws of the Republic of India. In the event of any legal dispute, courts in Mumbai, Maharashtra shall possess exclusive jurisdiction.',
              ),

              const SizedBox(height: 32),

              // Acknowledge Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'I Accept the Terms',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: subtextColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
