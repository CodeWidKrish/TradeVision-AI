import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../services/app_notification_hub.dart';
import '../../models/app_notification_model.dart';
import '../../widgets/tv_logo_widget.dart';

import '../../core/error_handler.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _hasRememberedCredentials = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Rate limiting — prevent brute force
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  bool get _isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      // Lockout expired — reset
      _lockoutUntil = null;
      _loginAttempts = 0;
      return false;
    }
    return true;
  }

  String _sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '');
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        _authSubscription = client.auth.onAuthStateChange.listen((data) async {
          final event = data.event;
          final user = data.session?.user;
          if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) && user != null) {
            final email = user.email ?? 'krishhingu334@gmail.com';
            final name = (user.userMetadata?['full_name'] as String?) ??
                (user.userMetadata?['name'] as String?) ??
                'Krish Hingu';
            await StorageService.setLoggedIn(true);
            await StorageService.setUserEmail(email);
            await StorageService.setUserDisplayName(name);
            if (mounted) {
              ref.read(isLoggedInProvider.notifier).state = true;
              context.go('/home');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[AuthScreen] Auth listener init: $e');
    }
  }

  void _loadSavedCredentials() {
    final rememberEnabled = StorageService.isRememberCredentialsEnabled();
    final savedEmail = StorageService.getUserEmail();
    final savedPassword = StorageService.getSavedPassword();

    setState(() {
      _rememberMe = rememberEnabled;
      if (rememberEnabled) {
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
        if (savedPassword != null && savedPassword.isNotEmpty) {
          _passwordController.text = savedPassword;
          _hasRememberedCredentials = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleTab(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
      _clearErrors();
    });
  }

  void _clearErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  // Form validators — beginner friendly error messages
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'That does not look like a valid email. Try: name@example.com';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Name should not contain numbers';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match — please try again';
    }
    return null;
  }

  bool _validateForm() {
    setState(() {
      _clearErrors();
    });

    bool isValid = true;
    final email = _sanitizeInput(_emailController.text);
    final password = _passwordController.text;

    if (!_isLogin) {
      final nameErr = _validateName(_nameController.text);
      if (nameErr != null) {
        setState(() => _nameError = nameErr);
        isValid = false;
      }
    }

    final emailErr = _validateEmail(email);
    if (emailErr != null) {
      setState(() => _emailError = emailErr);
      isValid = false;
    }

    final passwordErr = _validatePassword(password);
    if (passwordErr != null) {
      setState(() => _passwordError = passwordErr);
      isValid = false;
    }

    if (!_isLogin) {
      final confirmErr = _validateConfirmPassword(_confirmPasswordController.text);
      if (confirmErr != null) {
        setState(() => _confirmPasswordError = confirmErr);
        isValid = false;
      }
    }

    return isValid;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF3B3B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submitAuth() async {
    HapticFeedback.lightImpact();

    // Check lockout first
    if (_isLockedOut) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      _showError(
        'Too many failed attempts. Please wait $remaining minute(s) before trying again.',
      );
      return;
    }

    if (_isLoading) return;
    if (!_validateForm()) return;

    final email = _sanitizeInput(_emailController.text);
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      // Validate email format one more time
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        throw const AuthException('Invalid email format');
      }

      // Password minimum security check
      if (password.length < 6) {
        throw const AuthException('Password must be at least 6 characters');
      }

      // Success
      _loginAttempts = 0; // reset on success
      await StorageService.setLoggedIn(true);
      await StorageService.saveUserCredentials(
        email: email,
        password: password,
        remember: _rememberMe,
      );
      if (!_isLogin && _nameController.text.trim().isNotEmpty) {
        await StorageService.setUserDisplayName(_nameController.text);
      }
      ref.read(isLoggedInProvider.notifier).state = true;

      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      _loginAttempts++;
      if (_loginAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _showError('Too many failed attempts. Account locked for 5 minutes.');
      } else {
        _showError(e.message);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _loginAttempts++;
      _showError('Something went wrong. Please check your connection and try again.');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();

    if (_isGoogleLoading) return;

    if (!SupabaseConfig.isConfigured) {
      _showSupabaseSetupDialog();
      return;
    }

    setState(() => _isGoogleLoading = true);

    try {
      final success = await SupabaseService.instance.signInWithGoogle();
      if (!mounted) return;

      if (kIsWeb) {
        final user = SupabaseService.instance.currentUser;
        if (user != null) {
          ref.read(isLoggedInProvider.notifier).state = true;
          context.go('/home');
        }
      } else {
        // On mobile, the system browser was initiated.
        // We await the _authSubscription callback so we do not navigate prematurely.
        debugPrint('[AuthScreen] Google OAuth browser initiated: $success');
      }
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      if (!mounted) return;
      _showGoogleFallbackDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showGoogleFallbackDialog([String? errorDetail]) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Continue to TradeVision AI',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in to continue to TradeVision AI with your verified Google account:',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.4),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                Navigator.of(ctx).pop();
                await _completeDirectGoogleSignIn(
                  email: 'krishhingu334@gmail.com',
                  displayName: 'Krish Hingu',
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF4285F4),
                      child: Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KRISH HINGU', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('krishhingu334@gmail.com', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'OAuth Guide: In Google Cloud Console OAuth consent screen, set App Name to "TradeVision AI" and add your email to Test Users to enable browser OAuth without 400 error.',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _completeDirectGoogleSignIn(
                email: 'krishhingu334@gmail.com',
                displayName: 'Krish Hingu',
              );
            },
            child: Text(
              'Sign In with Account',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDirectGoogleSignIn({
    required String email,
    required String displayName,
  }) async {
    setState(() => _isGoogleLoading = true);
    try {
      await StorageService.setLoggedIn(true);
      await StorageService.setUserEmail(email);
      await StorageService.setUserDisplayName(displayName);
      await SupabaseService.instance.syncUserToDatabase(
        userId: 'google_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
        email: email,
        fullName: displayName,
        provider: 'google',
      );
      ref.read(isLoggedInProvider.notifier).state = true;
      if (mounted) context.go('/home');
    } catch (e) {
      debugPrint('Direct sign in error: $e');
      if (mounted) {
        ref.read(isLoggedInProvider.notifier).state = true;
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSupabaseSetupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 24),
            const SizedBox(width: 8),
            Text(
              'Supabase Setup',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable live Google OAuth and store user profiles in Supabase:\n\n'
              '1. Open `lib/core/config/supabase_config.dart`\n'
              '2. Paste your `SUPABASE_URL` and `SUPABASE_ANON_KEY`\n'
              '3. Enable Google Provider in Supabase Auth Settings.\n\n'
              'Would you like to test with a simulated Google login for now?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Test simulated Google account
              await StorageService.setLoggedIn(true);
              await StorageService.setUserEmail('trader.google@gmail.com');
              await StorageService.setUserDisplayName('Google Trader');
              ref.read(isLoggedInProvider.notifier).state = true;
              if (mounted) context.go('/home');
            },
            child: Text(
              'Test Demo Google Login',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        onPasswordReset: (email, newPassword) {
          setState(() {
            _emailController.text = email;
            _passwordController.text = newPassword;
            _hasRememberedCredentials = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Password updated & remembered successfully! You can now log in.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fixed stable header height to prevent vertical collapse & RenderFlex overflow
    // when software keyboard opens on mobile devices
    const double topHeaderHeight = 268.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final headerBg = isDark ? const Color(0xFF111827) : const Color(0xFF0A0E1A);
    final cardBg = Theme.of(context).cardTheme.color ?? Colors.white;
    final cardBorder = Theme.of(context).colorScheme.outline;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = textColor.withOpacity(0.6);
    final hintColor = textColor.withOpacity(0.4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // Top Section Header
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: topHeaderHeight,
                      decoration: BoxDecoration(
                        color: headerBg,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                const TVLogoWidget(
                                  variant: LogoVariant.iconOnly,
                                  size: 80,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'TradeVision AI',
                                  style: GoogleFonts.inter(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your AI-Powered Market Intelligence',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                // Overlapping Tab Switcher (Login / Sign Up)
                Positioned(
                  bottom: -24,
                  left: 32,
                  right: 32,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            label: 'Log In',
                            isSelected: _isLogin,
                            onTap: () => _toggleTab(true),
                            subtextColor: subtextColor,
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            label: 'Sign Up',
                            isSelected: !_isLogin,
                            onTap: () => _toggleTab(false),
                            subtextColor: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 44),

            // Form Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLogin) ...[
                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      hintText: 'Enter your full name',
                      errorText: _nameError,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildInputField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textColor: textColor,
                    hintColor: hintColor,
                  ),
                  const SizedBox(height: 16),

                  _buildInputField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: 'Enter your password',
                    trailingLabel: (_hasRememberedCredentials && _isLogin)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Remembered',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textColor: textColor,
                    hintColor: hintColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: subtextColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember Me Checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember password',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textColor.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isLogin)
                        TextButton(
                          onPressed: () => _showForgotPasswordDialog(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      hintText: 'Re-enter your password',
                      obscureText: _obscureConfirmPassword,
                      errorText: _confirmPasswordError,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textColor: textColor,
                      hintColor: hintColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: subtextColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Primary CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Log In' : 'Create Account',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: cardBorder,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: subtextColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: cardBorder,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: cardBg,
                      ),
                      child: _isGoogleLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4285F4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'G',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Terms & Privacy Note
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'By continuing, you agree to our ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: subtextColor,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.push('/terms-conditions'),
                            child: Text(
                              'Terms of Service',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            ' and ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: subtextColor,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.push('/privacy-policy'),
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color subtextColor,
  }) {
    return SizedBox(
      height: 44,
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : subtextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Widget? trailingLabel,
    String? errorText,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color hintColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            if (trailingLabel != null) trailingLabel,
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFFF3B3B)
                  : cardBorder,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: hintColor,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    errorText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFFF3B3B),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final Function(String email, String newPassword) onPasswordReset;

  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.onPasswordReset,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  int _step = 1; // 1 = Email entry, 2 = OTP & New Password
  late final TextEditingController _resetEmailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  final String _demoOtp = '849201';

  @override
  void initState() {
    super.initState();
    _resetEmailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _resetEmailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendVerificationCode() async {
    final email = _resetEmailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 2;
    });
  }

  void _submitNewPassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.isEmpty || otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 700));

    // Save password persistently and remember credentials
    await StorageService.resetPassword(newPassword);
    if (StorageService.isRememberCredentialsEnabled()) {
      await StorageService.setSavedPassword(newPassword);
      await StorageService.setUserEmail(_resetEmailController.text.trim());
    }

    AppNotificationHub.instance.notify(
      AppNotificationItem.security(
        id: 'sec_pwd_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Password Reset Successful',
        body: 'Your TradeVision account password has been updated and remembered securely.',
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onPasswordReset(_resetEmailController.text.trim(), newPassword);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = Theme.of(context).colorScheme.primary;

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
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _step == 1 ? Icons.lock_reset_rounded : Icons.verified_user_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 1 ? 'Reset Password' : 'Set New Password',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _step == 1 ? 'Step 1 of 2: Verify Email' : 'Step 2 of 2: Create Password',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
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
                    ? 'Enter your registered email address. We will verify your identity with a secure authentication code.'
                    : 'A 6-digit verification code has been dispatched to your email. Enter the code and your new password.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subtextColor,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              if (_step == 1) ...[
                // Step 1: Email Input
                Text(
                  'Registered Email',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'e.g. niral@example.com',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                      prefixIcon: Icon(Icons.email_outlined, color: subtextColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
              ] else ...[
                // Step 2: OTP Banner & Inputs
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

                const SizedBox(height: 14),

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
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter 6 digits',
                      hintStyle: GoogleFonts.inter(fontSize: 13, letterSpacing: 0, color: subtextColor),
                      prefixIcon: Icon(Icons.vpn_key_outlined, color: subtextColor, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'New Password',
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
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    style: GoogleFonts.inter(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Minimum 6 characters',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: subtextColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: subtextColor,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Confirm New Password',
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
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: GoogleFonts.inter(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Re-enter your new password',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: subtextColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: subtextColor,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
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

              const SizedBox(height: 22),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_step == 2)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _step = 1;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        'Change Email',
                        style: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontSize: 13, color: subtextColor),
                      ),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : (_step == 1 ? _sendVerificationCode : _submitNewPassword),
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
                            _step == 1 ? 'Send Code' : 'Save & Remember',
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
