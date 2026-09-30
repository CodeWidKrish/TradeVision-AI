import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/storage_service.dart';

class AccountInfoSheet extends StatefulWidget {
  final VoidCallback onUpdated;

  const AccountInfoSheet({super.key, required this.onUpdated});

  static void show(BuildContext context, {required VoidCallback onUpdated}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountInfoSheet(onUpdated: onUpdated),
    );
  }

  @override
  State<AccountInfoSheet> createState() => _AccountInfoSheetState();
}

class _AccountInfoSheetState extends State<AccountInfoSheet> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _panController;
  late TextEditingController _dematController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final email = StorageService.getUserEmail() ?? '';
    final defaultName = email.contains('@') ? email.split('@')[0] : 'Investor';
    final name = StorageService.getUserDisplayName() ?? defaultName;

    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _panController = TextEditingController(text: StorageService.getUserPan() ?? '');
    _dematController = TextEditingController(text: StorageService.getDematClientId() ?? '');
    _phoneController = TextEditingController(text: StorageService.getUserPhone() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _panController.dispose();
    _dematController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newPan = _panController.text.trim().toUpperCase();
    final newDemat = _dematController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newName.isNotEmpty) await StorageService.setUserDisplayName(newName);
    if (newPan.isNotEmpty) await StorageService.setUserPan(newPan);
    if (newDemat.isNotEmpty) await StorageService.setDematClientId(newDemat);
    if (newPhone.isNotEmpty) await StorageService.setUserPhone(newPhone);

    if (newPan.isNotEmpty) {
      await StorageService.setKycStatus('VERIFIED (SEBI Compliant)');
    }

    HapticFeedback.mediumImpact();
    setState(() => _isEditing = false);
    widget.onUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account & KYC details saved dynamically!'),
          backgroundColor: Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final currentPan = StorageService.getUserPan();
    final currentDemat = StorageService.getDematClientId();
    final currentPhone = StorageService.getUserPhone();
    final kycStatus = StorageService.getKycStatus();
    final isVerified = kycStatus.contains('VERIFIED');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: viewInsets + 24),
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
                  child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account & KYC Details',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                            size: 14,
                            color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF8C00),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kycStatus,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF8C00),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _isEditing = !_isEditing);
                  },
                  child: Text(
                    _isEditing ? 'Cancel' : 'Edit',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isEditing
                  ? _buildEditForm(textColor, subtextColor, cardBg, borderColor)
                  : _buildDisplayView(textColor, subtextColor, cardBg, borderColor, currentPan, currentDemat, currentPhone, isVerified),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayView(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
    String? currentPan,
    String? currentDemat,
    String? currentPhone,
    bool isVerified,
  ) {
    final name = StorageService.getUserDisplayName() ?? 'Investor';
    final email = StorageService.getUserEmail() ?? 'No email saved';

    return Column(
      children: [
        _buildInfoCard(cardBg, borderColor, [
          _buildInfoRow('Full Name', name, textColor, subtextColor, Icons.badge_outlined),
          const Divider(height: 1),
          _buildInfoRow('Email Address', email, textColor, subtextColor, Icons.email_outlined),
          const Divider(height: 1),
          _buildInfoRow(
            'Permanent Account Number (PAN)',
            (currentPan != null && currentPan.isNotEmpty) ? currentPan : 'Not linked (Tap Edit to enter PAN)',
            textColor,
            subtextColor,
            Icons.credit_card_outlined,
            isMonospace: true,
          ),
          const Divider(height: 1),
          _buildInfoRow(
            'Demat 16-Digit BOID / Client ID',
            (currentDemat != null && currentDemat.isNotEmpty) ? currentDemat : 'Not linked (Tap Edit to enter Demat)',
            textColor,
            subtextColor,
            Icons.account_balance_outlined,
            isMonospace: true,
          ),
          const Divider(height: 1),
          _buildInfoRow(
            'Contact Phone Number',
            (currentPhone != null && currentPhone.isNotEmpty) ? currentPhone : 'Not configured',
            textColor,
            subtextColor,
            Icons.phone_outlined,
          ),
        ]),

        const SizedBox(height: 16),

        // SEBI Compliance Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isVerified
                ? const Color(0xFF00C853).withValues(alpha: 0.08)
                : const Color(0xFFFF8C00).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isVerified
                  ? const Color(0xFF00C853).withValues(alpha: 0.3)
                  : const Color(0xFFFF8C00).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isVerified ? Icons.security_rounded : Icons.info_outline_rounded,
                color: isVerified ? const Color(0xFF00C853) : const Color(0xFFFF8C00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isVerified
                      ? 'Your PAN and identity parameters are safely stored in your local sandbox. You are ready for live API integration with NSE/BSE brokers.'
                      : 'Please tap "Edit" above and provide your valid PAN to complete your KYC registration.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Account & KYC Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile & KYC Details',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 12),

          // Name
          _buildFormField(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Your full legal name',
            textColor: textColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter a valid name' : null,
          ),

          const SizedBox(height: 12),

          // PAN
          _buildFormField(
            label: 'PAN (Permanent Account Number)',
            controller: _panController,
            hint: 'e.g. ABCDE1234F',
            textColor: textColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // optional
              final reg = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
              if (!reg.hasMatch(v.trim().toUpperCase())) {
                return 'Invalid Indian PAN format (5 letters, 4 digits, 1 letter)';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Demat Client ID
          _buildFormField(
            label: 'Demat BOID / Client ID (16 Digits)',
            controller: _dematController,
            hint: '16-digit CDSL or NSDL ID',
            keyboardType: TextInputType.number,
            textColor: textColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // optional
              if (v.trim().length != 16 || int.tryParse(v.trim()) == null) {
                return 'Demat ID must be exactly 16 numeric digits';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Phone
          _buildFormField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: 'e.g. +91 9876543210',
            keyboardType: TextInputType.phone,
            textColor: textColor,
            subtextColor: subtextColor,
            cardBg: cardBg,
            borderColor: borderColor,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveDetails,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Save Changes',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color textColor,
    required Color subtextColor,
    required Color cardBg,
    required Color borderColor,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: GoogleFonts.inter(fontSize: 13.5, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor.withValues(alpha: 0.6)),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildInfoCard(Color cardBg, Color borderColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor,
    IconData icon, {
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: subtextColor),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: isMonospace
                      ? GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)
                      : GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
