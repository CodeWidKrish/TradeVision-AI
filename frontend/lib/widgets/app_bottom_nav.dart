// lib/widgets/app_bottom_nav.dart
// Complete rewrite — handles all insets correctly like Instagram

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Nav bar background — matches app theme
      // IMPORTANT: extends DOWN into system nav bar area with padding
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E2733)
                : const Color(0xFFE2E6EA),
            width: 1,
          ),
        ),
        // Subtle shadow to separate from content
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: SafeArea(
        // SafeArea handles the system nav bar padding automatically
        top: false,
        child: SizedBox(
          height: 64, // Taller nav bar — matches Instagram size
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onTabSelected != null) {
                    onTabSelected!(0);
                  } else {
                    context.go('/home');
                  }
                },
              ),
              _NavItem(
                icon: Icons.candlestick_chart_outlined,
                activeIcon: Icons.candlestick_chart_rounded,
                label: 'Market',
                isSelected: currentIndex == 1,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onTabSelected != null) {
                    onTabSelected!(1);
                  } else {
                    context.go('/market');
                  }
                },
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Analytics',
                isSelected: currentIndex == 2,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onTabSelected != null) {
                    onTabSelected!(2);
                  } else {
                    context.go('/analytics');
                  }
                },
              ),
              _NavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'AI',
                isSelected: currentIndex == 3,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onTabSelected != null) {
                    onTabSelected!(3);
                  } else {
                    context.go('/ai-copilot');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator pill — like Instagram
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 44 : 0,
              height: isSelected ? 3 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon — larger size
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 26, // bigger icon
                color: isSelected
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF8892A4),
              ),
            ),

            const SizedBox(height: 4),

            // Label
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF8892A4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
