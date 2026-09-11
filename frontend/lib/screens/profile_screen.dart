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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _priceAlertsEnabled = true;
  bool _aiInsightsEnabled = true;

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

  void _showAccountInfoDialog() {
    final name = StorageService.getUserDisplayName() ?? 'Investor';
    final email = StorageService.getUserEmail() ?? 'user@example.com';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Account Details & KYC', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: $name', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Email: $email'),
              SizedBox(height: 4),
              Text('PAN: ABCDE1234F'),
              SizedBox(height: 4),
              Text('Demat Client ID: 1208160001234567'),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified, color: AppColors.gain, size: 18),
                  SizedBox(width: 6),
                  Text('KYC Status: VERIFIED (SEBI Compliant)', style: TextStyle(color: AppColors.gain, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  void _showDematLinkageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Linked Demat & Trading Brokers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Divider(height: 20),
              _buildBrokerTile('Zerodha Kite', 'ID: AB1234 • Connected', Icons.check_circle, AppColors.gain),
              const SizedBox(height: 8),
              _buildBrokerTile('Groww', 'ID: GW9876 • Connected', Icons.check_circle, AppColors.gain),
              const SizedBox(height: 8),
              _buildBrokerTile('Angel One', 'Tap to Connect', Icons.add_circle_outline, AppColors.primary),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrokerTile(String name, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications & Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Divider(height: 20),
                  SwitchListTile(
                    title: const Text('Real-time Price Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Get instant alerts when stock hits support/resistance'),
                    value: _priceAlertsEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => _priceAlertsEnabled = val);
                      setState(() => _priceAlertsEnabled = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('AI Trading Signals', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Push alerts for high-probability AI catalysts'),
                    value: _aiInsightsEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => _aiInsightsEnabled = val);
                      setState(() => _aiInsightsEnabled = val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile',
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
              // User Card Avatar & Identity
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
                              (StorageService.getUserDisplayName() ?? 'K')[0].toUpperCase(),
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
                          decoration: const BoxDecoration(
                            color: AppColors.gain,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      StorageService.getUserDisplayName() ?? 'Investor',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      SecurityService.maskEmail(
                          StorageService.getUserEmail() ?? 'user@example.com'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TradeVision Member',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
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

              // Account & Portfolio Section
              _buildSectionTitle('Account & Portfolio'),
              _buildSettingCard([
                _buildTile(Icons.person_outline, 'Account Information', 'Personal details & KYC status', _showAccountInfoDialog),
                _buildTile(Icons.pie_chart_outline_rounded, 'My Holdings', 'View portfolio asset breakdown', () => context.push('/holdings')),
                _buildTile(Icons.bookmark_border, 'Watchlist Management', 'Manage custom saved stocks', () => context.push('/watchlist')),
                _buildTile(Icons.account_balance_wallet_outlined, 'Portfolio Settings', 'Link Demat & Trading Account', _showDematLinkageSheet),
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
                _buildTile(Icons.notifications_none, 'Price Alerts', 'Get notified when stock prices change', _showNotificationsSheet),
                _buildTile(Icons.color_lens_outlined, 'App Theme', 'Change how the app looks', () => _showThemeSelectionSheet(themeMode)),
                _buildTile(Icons.lock_outline, 'App Lock & Security', 'Use fingerprint or PIN to lock the app', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App Lock Enabled'), behavior: SnackBarBehavior.floating),
                  );
                }),
              ]),

              const SizedBox(height: 16),

              _buildSectionTitle('Support & Legal'),
              _buildSettingCard([
                _buildTile(Icons.help_outline, 'Help & Support', 'Ask a question or report a problem', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connecting to Help & Support...'), behavior: SnackBarBehavior.floating),
                  );
                }),
                _buildTile(Icons.info_outline, 'About This App', 'Version 2.4.0', () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'TradeVision AI',
                    applicationVersion: '2.4.0',
                    applicationLegalese: '© 2026 TradeVision AI Inc. All rights reserved.',
                  );
                }),
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
