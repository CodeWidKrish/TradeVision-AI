import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class HelpSupportSheet extends StatefulWidget {
  const HelpSupportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HelpSupportSheet(),
    );
  }

  @override
  State<HelpSupportSheet> createState() => _HelpSupportSheetState();
}

class _HelpSupportSheetState extends State<HelpSupportSheet> {
  int _selectedTab = 0; // 0: FAQs, 1: Contact, 2: Submit Ticket
  String? _expandedFaqId;

  // Ticket Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'AI & Signal Accuracy';
  String _selectedPriority = 'Normal';
  bool _isSubmitting = false;
  String? _submittedTicketId;

  final List<Map<String, String>> _faqs = [
    {
      'id': 'faq_1',
      'q': 'How do TradeVision AI signals and confidence scores work?',
      'a': 'Our signals combine natural language processing (FinBERT) analyzing Indian financial headlines with an LSTM neural network and technical momentum (RSI, Moving Averages). Confidence percentages (e.g., 88% Strong Buy) reflect indicator alignment across multiple timeframes.',
    },
    {
      'id': 'faq_2',
      'q': 'Is Paper Trading using real money?',
      'a': 'No. Paper Trading provides a virtual ₹10,00,000 cash balance for risk-free simulation. You can practice execution, place Limit and Market orders, and test strategies without risking real capital.',
    },
    {
      'id': 'faq_3',
      'q': 'When do Indian stock markets open and close?',
      'a': 'National Stock Exchange (NSE) and Bombay Stock Exchange (BSE) trade Monday through Friday:\n• 9:00 AM - 9:08 AM IST: Pre-Open order matching\n• 9:15 AM - 3:30 PM IST: Regular live trading\n• 3:40 PM - 4:00 PM IST: Post-market settlement',
    },
    {
      'id': 'faq_4',
      'q': 'How does App Lock & Security protect my data?',
      'a': 'App Lock lets you set a 4-digit master security PIN and enable biometric verification. Whenever you return to the app or switch windows, TradeVision requires PIN verification before revealing your private portfolio and holdings.',
    },
    {
      'id': 'faq_5',
      'q': 'How do real-time Price and Market Alerts work?',
      'a': 'You can configure target price triggers, percentage spikes, and AI signal shift alerts for any stock. Alerts trigger in-app banners with the official TradeVision logo as well as heads-up device push notifications.',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 650));
    final randId = 'TV-${10000 + Random().nextInt(89999)}';

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submittedTicketId = randId;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: viewInsets),
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
          // Drag Handle
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/images/logo_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help & Support Center',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Support Systems Active • 24/7 Desk',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF00C853),
                            ),
                          ),
                        ],
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

          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _buildTab(0, 'FAQs', isDark),
                  _buildTab(1, 'Channels', isDark),
                  _buildTab(2, 'Submit Ticket', isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _selectedTab == 0
                  ? _buildFaqList(textColor, subtextColor, cardBg, borderColor)
                  : _selectedTab == 1
                      ? _buildContactChannels(textColor, subtextColor, cardBg, borderColor, isDark)
                      : _buildTicketForm(textColor, subtextColor, cardBg, borderColor, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, bool isDark) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        ..._faqs.map((faq) {
          final isExpanded = _expandedFaqId == faq['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExpanded ? AppColors.primary.withValues(alpha: 0.6) : borderColor,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    faq['q']!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? AppColors.primary : subtextColor,
                    size: 20,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedFaqId = isExpanded ? null : faq['id'];
                    });
                  },
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                    child: Text(
                      faq['a']!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: subtextColor,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactChannels(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Official Support Channels',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Email Support Tile
        _buildChannelCard(
          icon: Icons.email_outlined,
          title: 'Direct Email Support',
          subtitle: 'support@tradevision.ai',
          actionText: 'COPY EMAIL',
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
          subtextColor: subtextColor,
          onTap: () {
            Clipboard.setData(const ClipboardData(text: 'support@tradevision.ai'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Support email copied to clipboard!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Telegram Community Tile
        _buildChannelCard(
          icon: Icons.send_rounded,
          title: 'Official Community Telegram',
          subtitle: '@TradeVisionAI_Official',
          actionText: 'COPY HANDLE',
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
          subtextColor: subtextColor,
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '@TradeVisionAI_Official'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Telegram handle copied!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Technical Desk Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFF8C00), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Market Session Rapid Response',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'During active Indian market trading hours (9:15 AM - 3:30 PM IST), critical execution and feed queries receive priority queueing within 15 minutes.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: subtextColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              actionText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketForm(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    if (_submittedTicketId != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 44),
            ),
            const SizedBox(height: 16),
            Text(
              'Support Ticket Created',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reference: $_submittedTicketId',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your request has been logged in our engineering desk. A specialist will review your issue and email you back within 2-4 business hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: subtextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _submittedTicketId = null;
                  _subjectController.clear();
                  _descController.clear();
                  _selectedTab = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done & Return to FAQs'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe Your Question or Issue',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // Category Dropdown
          Text(
            'Issue Category',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: [
                  'AI & Signal Accuracy',
                  'Paper Trading Order Issue',
                  'Watchlist & Price Alerts',
                  'App Lock & Security PIN',
                  'Market Timings & Feeds',
                  'General Feedback',
                ].map((val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Text(
                      val,
                      style: GoogleFonts.inter(fontSize: 13, color: textColor),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Subject
          Text(
            'Subject',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _subjectController,
            style: GoogleFonts.inter(fontSize: 13, color: textColor),
            decoration: InputDecoration(
              hintText: 'Brief summary of the issue',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor.withValues(alpha: 0.6)),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            validator: (val) => (val == null || val.trim().length < 4) ? 'Please enter a valid subject' : null,
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            'Detailed Description',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 13, color: textColor),
            decoration: InputDecoration(
              hintText: 'Please share details, stock symbol, or steps to reproduce...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor.withValues(alpha: 0.6)),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            validator: (val) => (val == null || val.trim().length < 10) ? 'Please provide more details (min 10 chars)' : null,
          ),

          const SizedBox(height: 16),

          // Priority Row
          Row(
            children: [
              Text(
                'Priority:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
              ),
              const SizedBox(width: 12),
              ...['Low', 'Normal', 'Urgent'].map((p) {
                final isSelected = _selectedPriority == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    side: BorderSide(color: isSelected ? AppColors.primary : borderColor),
                    onSelected: (val) {
                      if (val) setState(() => _selectedPriority = p);
                    },
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitTicket,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSubmitting ? 'Submitting Ticket...' : 'Submit Support Ticket',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
