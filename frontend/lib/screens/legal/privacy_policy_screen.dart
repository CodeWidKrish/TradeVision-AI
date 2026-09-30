import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                            'Data Protection & Privacy Policy',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Effective: January 2026 • v2.4',
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

              // Compliance Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Compliant with India\'s Digital Personal Data Protection (DPDP) Act 2023, Information Technology Rules 2011, and SEBI Cybersecurity Guidelines.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textColor,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
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
                icon: Icons.shield_outlined,
                title: '1. Commitment to User Privacy',
                content:
                    'TradeVision AI ("we", "our", or "the Platform") respects your privacy and is dedicated to protecting all personal, behavioural, and financial data. We do not sell, rent, or trade your personal information with external advertisers or unverified third parties.',
              ),

              const SizedBox(height: 16),

              // Section 2
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.data_usage_rounded,
                title: '2. Information We Collect',
                content:
                    '• Account Credentials: Full name and email address when you register.\n'
                    '• Trading Activity: Watchlists, technical chart drawings, custom price alert thresholds, paper trading transactions, and virtual portfolio performance.\n'
                    '• Device & Analytics: Device identifier, operating system version, client IP address (anonymized), and crash telemetries for reliability.\n'
                    '• Security Note: We NEVER ask for, process, or store your real bank credentials, net banking passwords, or Demat account PINs.',
              ),

              const SizedBox(height: 16),

              // Section 3
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.psychology_outlined,
                title: '3. AI Models & Algorithmic Processing',
                content:
                    '• Our machine learning architectures (including FinBERT sentiment analysis and LSTM price engines) operate on publicly available exchange quotes and news feeds.\n'
                    '• Your simulated trades and portfolio decisions are not used to train global public AI models without explicit opt-in anonymization.',
              ),

              const SizedBox(height: 16),

              // Section 4
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.lock_outline_rounded,
                title: '4. Data Security & Encryption',
                content:
                    '• In-Transit Security: All communications between your device and TradeVision servers utilize Transport Layer Security (TLS 1.3) with SHA-256 certificates.\n'
                    '• Local Storage: Credentials and sensitive security configurations are encrypted on your local hardware keychain / SharedPreferences sandbox.\n'
                    '• App Lock Protection: Optional 4-digit security PIN and biometric authentication ensure only authorized users access live watchlists.',
              ),

              const SizedBox(height: 16),

              // Section 5
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.person_search_outlined,
                title: '5. Your Rights & Data Erasure',
                content:
                    'Under the DPDP Act 2023, you have the absolute right to:\n'
                    '• Request a copy of your personal data.\n'
                    '• Correct inaccurate or incomplete profile records.\n'
                    '• Request immediate and permanent deletion of your account and trading history.\n'
                    'To exercise these rights, tap Help & Support or email privacy@tradevision.ai.',
              ),

              const SizedBox(height: 16),

              // Section 6
              _buildSectionCard(
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                icon: Icons.contact_support_outlined,
                title: '6. Data Protection Officer',
                content:
                    'For inquiries, concerns, or regulatory compliance disclosures:\n'
                    'Grievance Officer: Niral Hingu\n'
                    'Email: dpo@tradevision.ai\n'
                    'TradeVision Technologies Private Limited\n'
                    'Bandra-Kurla Complex (BKC), Mumbai, Maharashtra 400051',
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
                    'I Understand & Agree',
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
