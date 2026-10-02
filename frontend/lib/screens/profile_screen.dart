import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../core/security_service.dart';
import '../widgets/help_support_sheet.dart';
import '../widgets/app_lock_sheet.dart';
import '../widgets/account_info_sheet.dart';
import '../widgets/portfolio_settings_sheet.dart';
import '../services/app_notification_hub.dart';
import '../models/app_notification_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late bool _priceAlertsEnabled;
  late bool _marketTimingEnabled;
  late bool _highPriorityNewsEnabled;
  late bool _aiInsightsEnabled;

  @override
  void initState() {
    super.initState();
    _priceAlertsEnabled = StorageService.isPriceAlertsEnabled();
    _marketTimingEnabled = StorageService.isMarketTimingNotificationsEnabled();
    _highPriorityNewsEnabled = StorageService.isHighPriorityNewsEnabled();
    _aiInsightsEnabled = StorageService.isAiInsightsNotifEnabled();
  }

  void _confirmLogout() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Account'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              await StorageService.clearSession();
              ref.read(isLoggedInProvider.notifier).state = false;
              if (context.mounted) context.go('/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B3B),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionSheet(ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Theme Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                'Select app appearance mode',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 24),

              // Light Mode Option
              _buildThemeOptionTile(
                currentMode: currentMode,
                mode: ThemeMode.light,
                title: 'Light Mode',
                subtitle: 'Clean, high-contrast light design system',
                icon: Icons.light_mode_outlined,
              ),

              const SizedBox(height: 8),

              // Dark Mode Option
              _buildThemeOptionTile(
                currentMode: currentMode,
                mode: ThemeMode.dark,
                title: 'Dark Mode',
                subtitle: 'Sleek OLED dark mode tailored for night trading',
                icon: Icons.dark_mode_outlined,
              ),

              const SizedBox(height: 8),

              // System Theme Option
              _buildThemeOptionTile(
                currentMode: currentMode,
                mode: ThemeMode.system,
                title: 'System Default',
                subtitle: 'Automatically match device operating system theme',
                icon: Icons.settings_brightness_outlined,
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required ThemeMode currentMode,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderStrong,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          ref.read(themeProvider.notifier).setThemeMode(mode);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title activated!'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
            : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notifications & Alerts Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Divider(height: 20),
                    SwitchListTile(
                      title: const Text('Real-time Price Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Instant heads-up notification when target prices breach'),
                      value: _priceAlertsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) async {
                        await StorageService.setPriceAlertsEnabled(val);
                        setModalState(() => _priceAlertsEnabled = val);
                        setState(() => _priceAlertsEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Market Timing Announcements', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Real-time alerts for Pre-Open (9:00 AM), Market Open (9:15 AM), and Close (3:30 PM)'),
                      value: _marketTimingEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) async {
                        await StorageService.setMarketTimingNotificationsEnabled(val);
                        setModalState(() => _marketTimingEnabled = val);
                        setState(() => _marketTimingEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('High-Priority Breaking News', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Urgent market catalysts and corporate action alerts'),
                      value: _highPriorityNewsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) async {
                        await StorageService.setHighPriorityNewsEnabled(val);
                        setModalState(() => _highPriorityNewsEnabled = val);
                        setState(() => _highPriorityNewsEnabled = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('AI Insights & Momentum Triggers', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Deep learning buy/sell signals & FinBERT sentiment catalysts'),
                      value: _aiInsightsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) async {
                        await StorageService.setAiInsightsNotifEnabled(val);
                        setModalState(() => _aiInsightsEnabled = val);
                        setState(() => _aiInsightsEnabled = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Test Real-Time Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppNotificationHub.instance.triggerMarketTimingNotification(MarketTimingMilestone.marketOpen);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.notifications_active_outlined, size: 16),
                            label: const Text('Test Market Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppNotificationHub.instance.notify(
                                AppNotificationItem.breakingNews(
                                  id: 'demo_news_${DateTime.now().millisecondsSinceEpoch}',
                                  title: 'RELIANCE secures ₹12,000 Cr green energy contract',
                                  body: 'Economic Times reports significant order win. AI momentum probability shifted to 89% Strong Buy.',
                                  relatedTicker: 'RELIANCE',
                                ),
                              );
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFFF8C00)),
                            label: const Text('Test News Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return AlertDialog(
          backgroundColor: cardBg,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) => const Icon(Icons.show_chart, color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TradeVision AI',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('v2.4.0 (Build 2026.09)', style: TextStyle(fontSize: 12, color: subtextColor)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TradeVision is an advanced real-time Indian stock market analytics and algorithmic intelligence platform.',
                  style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Compliance & Regulatory Framework',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• SEBI (Research Analysts) Regulations 2014 compliant analytics engine.\n• Digital Personal Data Protection Act 2023 compliant zero-knowledge telemetry.\n• Real-time data mapped to NSE & BSE equity tickers.',
                        style: TextStyle(fontSize: 11, color: subtextColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Open-Source Licenses & Attribution:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'TradeVision uses official open-source packages licensed under MIT, Apache 2.0, and BSD licenses.',
                  style: TextStyle(fontSize: 11, color: subtextColor),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Close', style: TextStyle(color: subtextColor, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showLicensePage(
                        context: context,
                        applicationName: 'TradeVision AI',
                        applicationVersion: 'v2.4.0 (Build 2026.09)',
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/logo_icon.png',
                              width: 60,
                              height: 60,
                              errorBuilder: (_, __, ___) => const Icon(Icons.show_chart, color: AppColors.primary, size: 60),
                            ),
                          ),
                        ),
                        applicationLegalese: '© 2026 TradeVision AI Inc. All rights reserved.\nLicensed under MIT and Apache 2.0 open-source dependencies.\nMarket data and FinBERT models configured for Indian Equity markets.',
                      );
                    },
                    icon: const Icon(Icons.library_books_rounded, size: 15),
                    label: const Text('View All Licenses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final displayName = StorageService.getUserDisplayName() ?? 'Investor';
    final email = StorageService.getUserEmail() ?? 'user@example.com';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'T');
    final kycStatus = StorageService.getKycStatus();
    final isKycVerified = kycStatus.toUpperCase().contains('VERIFIED');
    final pan = StorageService.getUserPan();
    final watchlistCount = StorageService.getWatchlistSymbols().length;
    final isLockActive = StorageService.isAppLockEnabled();

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile & Settings',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDim.screenH, vertical: 16),
          child: Column(
            children: [
              // User Card Avatar & Dynamic Identity
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppDim.radiusXl),
                  border: Border.all(color: AppColors.borderStrong, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isKycVerified ? AppColors.gain : const Color(0xFFFF8C00),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isKycVerified ? Icons.check : Icons.hourglass_top,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      SecurityService.maskEmail(email),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Trading & Engine Status Bar (replaces static tier badge with utilized space)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF131B2E)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildProfileStatusItem(
                              icon: Icons.bolt_rounded,
                              iconColor: AppColors.primary,
                              title: 'AI Engine',
                              value: 'XGBoost v2',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFCBD5E1),
                          ),
                          Expanded(
                            child: _buildProfileStatusItem(
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: const Color(0xFF00C853),
                              title: 'Paper Capital',
                              value: '₹10,00,000',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFCBD5E1),
                          ),
                          Expanded(
                            child: _buildProfileStatusItem(
                              icon: Icons.sensors_rounded,
                              iconColor: const Color(0xFF00C853),
                              title: 'Live Market',
                              value: 'NSE Connected',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Beginner tip card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: Color(0xFF00C853), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New to investing? Tap Help & Support anytime -- our AI explains everything in simple language.',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF00C853), height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account & Portfolio Section - Completely Dynamic
              _buildSectionTitle('Account & Portfolio'),
              _buildSettingCard([
                _buildTile(
                  Icons.person_outline,
                  'Account Information',
                  'KYC: ${kycStatus.split(' ').first} • PAN: ${pan != null && pan.isNotEmpty ? pan : "Pending"}',
                  () => AccountInfoSheet.show(context, onUpdated: () => setState(() {})),
                ),
                _buildTile(
                  Icons.pie_chart_outline_rounded,
                  'My Holdings',
                  'View portfolio asset breakdown & equity balance',
                  () => context.push('/holdings'),
                ),
                _buildTile(
                  Icons.bookmark_border,
                  'Watchlist Management',
                  '$watchlistCount stocks tracked in active watchlist',
                  () => context.push('/watchlist'),
                ),
                _buildTile(
                  Icons.tune_rounded,
                  'Trading & Risk Preferences',
                  'Risk: ${StorageService.getRiskProfile()} • ${StorageService.getDefaultOrderType()} • SL: ${StorageService.getStopLossPct()}%',
                  () => PortfolioSettingsSheet.show(context, onUpdated: () => setState(() {})),
                ),
              ]),

              const SizedBox(height: 16),

              // Preferences & System Section with Direct Dark Theme Toggle Switch!
              _buildSectionTitle('Preferences & Appearance'),
              _buildSettingCard([
                // Dark Mode Toggle
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: AppColors.primary, size: 24),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Switch between dark and light look',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  value: isDarkMode,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val ? 'Dark Mode ON!' : 'Dark Mode OFF!'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildTile(
                  Icons.notifications_none,
                  'Notifications & Alerts',
                  '${_priceAlertsEnabled ? "Alerts Active" : "Alerts Muted"} • Market Milestones',
                  _showNotificationsSheet,
                ),
                _buildTile(
                  Icons.color_lens_outlined,
                  'App Theme',
                  themeMode == ThemeMode.dark
                      ? 'Dark Mode (OLED Active)'
                      : (themeMode == ThemeMode.light ? 'Light Mode Active' : 'System Default'),
                  () => _showThemeSelectionSheet(themeMode),
                ),
                _buildTile(
                  Icons.lock_outline,
                  'App Lock & Security',
                  isLockActive ? 'PIN Protected • Biometric Guard' : 'Disabled • Tap to configure',
                  () => AppLockSheet.show(context),
                ),
              ]),

              const SizedBox(height: 16),

              _buildSectionTitle('Support & Legal'),
              _buildSettingCard([
                _buildTile(
                  Icons.help_outline,
                  'Help & Support',
                  'Interactive FAQs, support desk & tickets',
                  () => HelpSupportSheet.show(context),
                ),
                _buildTile(
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  'DPDP Act 2023 & data encryption architecture',
                  () => context.push('/privacy-policy'),
                ),
                _buildTile(
                  Icons.description_outlined,
                  'Terms & Conditions',
                  'Service terms & mandatory SEBI risk disclaimers',
                  () => context.push('/terms-conditions'),
                ),
                _buildTile(
                  Icons.info_outline,
                  'About This App',
                  'Official licenses, version & technology stack',
                  _showAboutDialog,
                ),
              ]),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, color: AppColors.loss, size: 20),
                  label: const Text(
                    'Logout Account',
                    style: TextStyle(
                      color: AppColors.loss,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.loss, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDim.radiusLg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatusItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDim.radiusXl),
        border: Border.all(color: AppColors.borderStrong, width: 1.2),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
      onTap: onTap,
    );
  }
}
