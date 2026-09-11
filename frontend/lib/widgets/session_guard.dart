import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/security_service.dart';
import '../services/storage_service.dart';
import '../core/providers/auth_provider.dart';

class SessionGuard extends ConsumerStatefulWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});

  @override
  ConsumerState<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends ConsumerState<SessionGuard>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Check session when app comes back from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (SecurityService.isSessionExpired) {
        _forceLogout();
      }
    }
    if (state == AppLifecycleState.paused) {
      SecurityService.recordActivity();
    }
  }

  void _forceLogout() async {
    await StorageService.clearSession();
    ref.read(isLoggedInProvider.notifier).state = false;
    if (mounted) {
      context.go('/auth');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You were logged out after 15 minutes of inactivity. Please log in again.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFFF8C00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Record user activity on any interaction
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: SecurityService.recordActivity,
      onPanDown: (_) => SecurityService.recordActivity(),
      child: widget.child,
    );
  }
}
