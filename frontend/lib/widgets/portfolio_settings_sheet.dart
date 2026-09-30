import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/portfolio_provider.dart';
import '../services/storage_service.dart';

class PortfolioSettingsSheet extends StatefulWidget {
  final VoidCallback onUpdated;

  const PortfolioSettingsSheet({super.key, required this.onUpdated});

  static void show(BuildContext context, {required VoidCallback onUpdated}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortfolioSettingsSheet(onUpdated: onUpdated),
    );
  }

  @override
  State<PortfolioSettingsSheet> createState() => _PortfolioSettingsSheetState();
}

class _PortfolioSettingsSheetState extends State<PortfolioSettingsSheet> {
  late String _riskProfile;
  late String _defaultOrderType;
  late double _stopLossPct;
  late double _targetProfitPct;

  @override
  void initState() {
    super.initState();
    _riskProfile = StorageService.getRiskProfile();
    _defaultOrderType = StorageService.getDefaultOrderType();
    _stopLossPct = StorageService.getStopLossPct();
    _targetProfitPct = StorageService.getTargetProfitPct();
  }

  void _confirmResetPortfolio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Paper Trading Balance?'),
        content: const Text(
          'This will reset your virtual cash back to ₹1,00,000 and clear all simulated positions and order history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B3B)),
            child: const Text('Reset to ₹1,00,000', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      PortfolioProvider.instance?.resetPortfolio();
      HapticFeedback.heavyImpact();
      widget.onUpdated();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virtual paper trading account reset to ₹1,00,000!'),
            backgroundColor: Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final portfolio = PortfolioProvider.instance;
    final virtualCash = portfolio?.virtualCash ?? 100000.0;
    final portfolioValue = portfolio?.totalPortfolioValue ?? 100000.0;
    final holdingsCount = portfolio?.positions.length ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trading & Portfolio Settings',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Virtual Execution & Risk Model',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: subtextColor, size: 22),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Real-time Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFFEEF2F6), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Virtual Cash Available:',
                              style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                            ),
                            Text(
                              '₹${virtualCash.toStringAsFixed(2)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00C853),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Portfolio Value:',
                              style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                            ),
                            Text(
                              '₹${portfolioValue.toStringAsFixed(2)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Open Positions:',
                              style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                            ),
                            Text(
                              '$holdingsCount Stocks',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _confirmResetPortfolio,
                            icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFFF3B3B)),
                            label: const Text(
                              'Reset Virtual Balance to ₹1,00,000',
                              style: TextStyle(color: Color(0xFFFF3B3B), fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF3B3B)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Risk Tolerance Setting
                  Text(
                    'Risk Management Strategy',
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Conservative', 'Moderate', 'Aggressive'].map((level) {
                      final isSelected = _riskProfile == level;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                level,
                                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                            onSelected: (val) async {
                              if (val) {
                                await StorageService.setRiskProfile(level);
                                setState(() => _riskProfile = level);
                                widget.onUpdated();
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Default Order Type
                  Text(
                    'Default Order Type',
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['MARKET', 'LIMIT'].map((type) {
                      final isSelected = _defaultOrderType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                '$type Order',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                            onSelected: (val) async {
                              if (val) {
                                await StorageService.setDefaultOrderType(type);
                                setState(() => _defaultOrderType = type);
                                widget.onUpdated();
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Auto Stop Loss
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Stop-Loss Level:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Text(
                        '-${_stopLossPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF3B3B),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _stopLossPct,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    activeColor: const Color(0xFFFF3B3B),
                    label: '-${_stopLossPct.toStringAsFixed(1)}%',
                    onChanged: (val) {
                      setState(() => _stopLossPct = val);
                    },
                    onChangeEnd: (val) async {
                      await StorageService.setStopLossPct(val);
                      widget.onUpdated();
                    },
                  ),

                  const SizedBox(height: 10),

                  // Auto Take Profit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Take-Profit Level:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      Text(
                        '+${_targetProfitPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetProfitPct,
                    min: 2.0,
                    max: 20.0,
                    divisions: 18,
                    activeColor: const Color(0xFF00C853),
                    label: '+${_targetProfitPct.toStringAsFixed(1)}%',
                    onChanged: (val) {
                      setState(() => _targetProfitPct = val);
                    },
                    onChangeEnd: (val) async {
                      await StorageService.setTargetProfitPct(val);
                      widget.onUpdated();
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
