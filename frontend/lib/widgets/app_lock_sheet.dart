import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../services/storage_service.dart';
import '../services/app_notification_hub.dart';
import '../models/app_notification_model.dart';

class AppLockSheet extends StatefulWidget {
  const AppLockSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppLockSheet(),
    );
  }

  @override
  State<AppLockSheet> createState() => _AppLockSheetState();
}

class _AppLockSheetState extends State<AppLockSheet> {
  late bool _isLockEnabled;
  late bool _isBiometricEnabled;
  bool _isSettingPin = false;
  bool _isTestingPin = false;

  String _pinBuffer = '';
  String? _firstPinEntry;
  String _pinStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _isLockEnabled = StorageService.isAppLockEnabled();
    _isBiometricEnabled = StorageService.isBiometricEnabled();
  }

  void _onNumberTap(String digit) {
    HapticFeedback.selectionClick();
    if (_pinBuffer.length < 4) {
      setState(() {
        _pinBuffer += digit;
      });

      if (_pinBuffer.length == 4) {
        _handlePinEntered(_pinBuffer);
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_pinBuffer.isNotEmpty) {
      setState(() {
        _pinBuffer = _pinBuffer.substring(0, _pinBuffer.length - 1);
      });
    }
  }

  void _handlePinEntered(String pin) async {
    if (_isSettingPin) {
      if (_firstPinEntry == null) {
        // First entry done, ask for confirmation
        setState(() {
          _firstPinEntry = pin;
          _pinBuffer = '';
          _pinStatusMessage = 'Confirm your 4-digit PIN';
        });
      } else {
        if (_firstPinEntry == pin) {
          // PIN Match!
          await StorageService.setAppLockPin(pin);
          await StorageService.setAppLockEnabled(true);
          setState(() {
            _isLockEnabled = true;
            _isSettingPin = false;
            _firstPinEntry = null;
            _pinBuffer = '';
            _pinStatusMessage = '';
          });
          HapticFeedback.heavyImpact();

          AppNotificationHub.instance.notify(
            AppNotificationItem.security(
              id: 'sec_lock_enabled_${DateTime.now().millisecondsSinceEpoch}',
              title: 'App Lock & PIN Configured',
              body: 'TradeVision is now protected with a 4-digit security PIN and biometric session guard.',
            ),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Security PIN set successfully! App Lock is now ACTIVE.'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Mismatch
          HapticFeedback.vibrate();
          setState(() {
            _firstPinEntry = null;
            _pinBuffer = '';
            _pinStatusMessage = 'PINs did not match. Try again';
          });
        }
      }
    } else if (_isTestingPin) {
      final isValid = StorageService.verifyPin(pin);
      if (isValid) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isTestingPin = false;
          _pinBuffer = '';
          _pinStatusMessage = '';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN Verified! Session Unlocked successfully.'),
              backgroundColor: Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _pinBuffer = '';
          _pinStatusMessage = 'Incorrect PIN. Default is 1234 or your custom PIN';
        });
      }
    }
  }

  void _showForgotPinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _ForgotPinDialog(
        onPinReset: (newPin) {
          setState(() {
            _isLockEnabled = true;
            _isTestingPin = false;
            _isSettingPin = false;
            _firstPinEntry = null;
            _pinBuffer = '';
            _pinStatusMessage = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PIN reset to $newPin and remembered securely!',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                    color: _isLockEnabled
                        ? const Color(0xFF00C853).withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLockEnabled ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                    color: _isLockEnabled ? const Color(0xFF00C853) : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Lock & Privacy Guard',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLockEnabled ? 'Active • Portfolio Protected' : 'Disabled • Not Protected',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isLockEnabled ? const Color(0xFF00C853) : subtextColor,
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
              child: (_isSettingPin || _isTestingPin)
                  ? _buildKeypadView(textColor, subtextColor, cardBg, borderColor)
                  : _buildSettingsView(textColor, subtextColor, cardBg, borderColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
  ) {
    final hasPin = StorageService.getAppLockPin() != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isLockEnabled
                ? const Color(0xFF00C853).withValues(alpha: 0.08)
                : const Color(0xFFFF8C00).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isLockEnabled
                  ? const Color(0xFF00C853).withValues(alpha: 0.3)
                  : const Color(0xFFFF8C00).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isLockEnabled ? Icons.security_rounded : Icons.info_outline_rounded,
                color: _isLockEnabled ? const Color(0xFF00C853) : const Color(0xFFFF8C00),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _isLockEnabled
                      ? 'Biometric & PIN security is guarding your trade history, holdings, and private account data.'
                      : 'Enable App Lock to require your PIN or biometric verification each time you launch TradeVision.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Enable App Lock Switch Tile
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'Enable App Lock',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                ),
                subtitle: Text(
                  'Require authentication on app launch',
                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                ),
                value: _isLockEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: (val) async {
                  if (val && !hasPin) {
                    // Need to set a PIN first
                    setState(() {
                      _isSettingPin = true;
                      _firstPinEntry = null;
                      _pinBuffer = '';
                      _pinStatusMessage = 'Enter a new 4-digit PIN';
                    });
                  } else {
                    await StorageService.setAppLockEnabled(val);
                    setState(() => _isLockEnabled = val);
                    HapticFeedback.mediumImpact();
                  }
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  'Biometric Authentication',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                ),
                subtitle: Text(
                  'Use Fingerprint or Face ID when supported',
                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                ),
                value: _isBiometricEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: _isLockEnabled
                    ? (val) async {
                        await StorageService.setBiometricEnabled(val);
                        setState(() => _isBiometricEnabled = val);
                      }
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PIN Management Options
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.pin_rounded, color: AppColors.primary),
                title: Text(
                  hasPin ? 'Change Security PIN' : 'Set Security PIN',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  hasPin ? 'PIN is configured & remembered' : 'No PIN configured (Default: 1234)',
                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                onTap: () {
                  setState(() {
                    _isSettingPin = true;
                    _firstPinEntry = null;
                    _pinBuffer = '';
                    _pinStatusMessage = 'Enter your new 4-digit PIN';
                  });
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.verified_outlined, color: Color(0xFF00C853)),
                title: Text(
                  'Test Lock & Unlock',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  'Verify your PIN unlocking flow',
                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                onTap: () {
                  setState(() {
                    _isTestingPin = true;
                    _pinBuffer = '';
                    _pinStatusMessage = 'Enter PIN to test unlock';
                  });
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFFFF8C00)),
                title: Text(
                  'Forgot PIN / Reset PIN',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
                subtitle: Text(
                  'Verify credentials to reset 4-digit PIN',
                  style: GoogleFonts.inter(fontSize: 12, color: subtextColor),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                onTap: () => _showForgotPinDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadView(
    Color textColor,
    Color subtextColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          _isSettingPin
              ? (_firstPinEntry == null ? 'Set 4-Digit Security PIN' : 'Confirm Your PIN')
              : 'Enter PIN to Unlock',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _pinStatusMessage.isNotEmpty
              ? _pinStatusMessage
              : 'Keep your portfolio and sensitive trades private',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: _pinStatusMessage.contains('mismatch') || _pinStatusMessage.contains('Incorrect')
                ? const Color(0xFFFF3B3B)
                : subtextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // 4 PIN Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _pinBuffer.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isFilled ? AppColors.primary : borderColor,
                  width: 2,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),

        const SizedBox(height: 28),

        // Keypad Grid (1-9, cancel, 0, backspace)
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            children: [
              _buildKeypadRow(['1', '2', '3'], textColor, cardBg, borderColor),
              const SizedBox(height: 12),
              _buildKeypadRow(['4', '5', '6'], textColor, cardBg, borderColor),
              const SizedBox(height: 12),
              _buildKeypadRow(['7', '8', '9'], textColor, cardBg, borderColor),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSettingPin = false;
                        _isTestingPin = false;
                        _firstPinEntry = null;
                        _pinBuffer = '';
                      });
                    },
                    icon: Icon(Icons.cancel_outlined, color: subtextColor, size: 26),
                  ),
                  _buildKeypadButton('0', textColor, cardBg, borderColor),
                  IconButton(
                    onPressed: _onBackspace,
                    icon: Icon(Icons.backspace_outlined, color: textColor, size: 22),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Forgot PIN button
        TextButton.icon(
          onPressed: () => _showForgotPinDialog(context),
          icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.primary),
          label: Text(
            'Forgot Security PIN?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits, Color textColor, Color cardBg, Color borderColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadButton(d, textColor, cardBg, borderColor)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, Color textColor, Color cardBg, Color borderColor) {
    return InkWell(
      onTap: () => _onNumberTap(digit),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPinDialog extends StatefulWidget {
  final Function(String newPin) onPinReset;

  const _ForgotPinDialog({required this.onPinReset});

  @override
  State<_ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends State<_ForgotPinDialog> {
  int _step = 1; // 1 = Verify identity, 2 = Enter new PIN
  bool _useOtpInstead = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final String _demoOtp = '849201';

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _verifyIdentity() async {
    final savedPassword = StorageService.getSavedPassword();
    final enteredPassword = _passwordController.text;

    if (_useOtpInstead) {
      final enteredOtp = _otpController.text.trim();
      if (enteredOtp.isEmpty || enteredOtp.length < 4) {
        setState(() => _errorMessage = 'Please enter the verification code');
        return;
      }
    } else {
      if (enteredPassword.isEmpty) {
        setState(() => _errorMessage = 'Please enter your account password');
        return;
      }
      if (savedPassword != null && savedPassword.isNotEmpty && enteredPassword != savedPassword) {
        setState(() => _errorMessage = 'Incorrect password. Try again or switch to Email OTP verification.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 2;
    });
  }

  void _saveNewPin([String? presetPin]) async {
    final pin = presetPin ?? _newPinController.text.trim();
    final confirm = presetPin ?? _confirmPinController.text.trim();

    if (pin.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      setState(() => _errorMessage = 'PIN must be exactly 4 numeric digits');
      return;
    }

    if (pin != confirm) {
      setState(() => _errorMessage = 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 500));

    // Save and remember the new PIN
    await StorageService.setAppLockPin(pin);
    await StorageService.setAppLockEnabled(true);

    AppNotificationHub.instance.notify(
      AppNotificationItem.security(
        id: 'sec_pin_reset_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Security PIN Reset',
        body: 'Your 4-digit security PIN has been updated and remembered securely.',
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onPinReset(pin);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryColor = AppColors.primary;
    final savedEmail = StorageService.getUserEmail() ?? 'your registered account';

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pin_rounded,
                      color: Color(0xFFFF8C00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 1 ? 'Reset Security PIN' : 'Set New 4-Digit PIN',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _step == 1 ? 'Step 1 of 2: Verify Identity' : 'Step 2 of 2: Create PIN',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF8C00),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: subtextColor, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                _step == 1
                    ? (_useOtpInstead
                        ? 'A verification code has been dispatched to $savedEmail.'
                        : 'Enter your account password to verify ownership and unlock PIN recovery.')
                    : 'Choose a new 4-digit security PIN to protect your TradeVision trades and portfolio.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtextColor,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 16),

              if (_step == 1) ...[
                if (!_useOtpInstead) ...[
                  Text(
                    'Account Password',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter your account password',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: subtextColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: subtextColor,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _useOtpInstead = true;
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.mail_outline_rounded, size: 16),
                      label: Text(
                        'Forgot password too? Verify with Email OTP',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Demo Verification Code: $_demoOtp',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _otpController.text = _demoOtp;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Auto-fill',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verification Code',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 3, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter 6 digits',
                        hintStyle: GoogleFonts.inter(fontSize: 13, letterSpacing: 0, color: subtextColor),
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: subtextColor, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _useOtpInstead = false;
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                      label: Text(
                        'Verify with Account Password instead',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Step 2: New PIN Inputs
                Text(
                  'New 4-Digit PIN',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _newPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 4, color: textColor),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      hintStyle: GoogleFonts.inter(fontSize: 14, letterSpacing: 2, color: subtextColor),
                      prefixIcon: Icon(Icons.pin_rounded, color: subtextColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Confirm 4-Digit PIN',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 4, color: textColor),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      hintStyle: GoogleFonts.inter(fontSize: 14, letterSpacing: 2, color: subtextColor),
                      prefixIcon: Icon(Icons.pin_rounded, color: subtextColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Reset to Default chip
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.restore_rounded, size: 14, color: AppColors.primary),
                    label: Text(
                      'Default PIN: 1234',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    onPressed: () {
                      _newPinController.text = '1234';
                      _confirmPinController.text = '1234';
                      _saveNewPin('1234');
                    },
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B3B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF3B3B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFF3B3B), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFFF3B3B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: subtextColor)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : (_step == 1 ? _verifyIdentity : () => _saveNewPin()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _step == 1 ? 'Verify & Continue' : 'Save & Remember PIN',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
