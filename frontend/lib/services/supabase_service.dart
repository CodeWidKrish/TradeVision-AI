import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'storage_service.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient? get client => _initialized ? Supabase.instance.client : null;

  /// Initialize Supabase client if configured
  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] Supabase credentials not set. Running in offline/local fallback mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Supabase initialized successfully.');

      // Setup auth state change listener
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        final User? user = session?.user;

        if (event == AuthChangeEvent.signedIn && user != null) {
          debugPrint('[SupabaseService] User signed in: ${user.email}');
          await _onUserSignedIn(user);
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('[SupabaseService] User signed out');
        }
      });
    } catch (e) {
      debugPrint('[SupabaseService] Initialization error: $e');
    }
  }

  /// Handles saving user to Supabase Database and local preferences upon sign in
  Future<void> _onUserSignedIn(User user) async {
    try {
      final email = user.email ?? '';
      final name = (user.userMetadata?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          email.split('@').first;
      final avatarUrl = user.userMetadata?['avatar_url'] as String? ?? '';

      // 1. Sync to Supabase `users` database table
      await syncUserToDatabase(
        userId: user.id,
        email: email,
        fullName: name,
        avatarUrl: avatarUrl,
        provider: 'google',
      );

      // 2. Persist to local StorageService
      await StorageService.setLoggedIn(true);
      await StorageService.setUserEmail(email);
      await StorageService.setUserDisplayName(name);
    } catch (e) {
      debugPrint('[SupabaseService] Error syncing user on sign-in: $e');
    }
  }

  /// Store or update user credentials/profile in Supabase Database ('users' table)
  Future<void> syncUserToDatabase({
    required String userId,
    required String email,
    required String fullName,
    String? avatarUrl,
    String provider = 'google',
  }) async {
    if (!_initialized || client == null) return;

    try {
      final userRecord = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl ?? '',
        'provider': provider,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await client!.from('users').upsert(userRecord);
      debugPrint('[SupabaseService] Synced user record to Supabase "users" table.');
    } catch (e) {
      debugPrint('[SupabaseService] syncUserToDatabase error: $e');
      // If table does not exist or has RLS issue, print clear guidance
      rethrow;
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception(
        'Supabase is not configured yet. Please enter your Supabase URL & Anon Key in lib/core/config/supabase_config.dart',
      );
    }

    if (!_initialized || client == null) {
      await init();
    }

    try {
      if (kIsWeb) {
        // Web OAuth flow
        final success = await client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin, // redirects back to this web app
        );
        return success;
      } else {
        // Mobile / Desktop redirect flow
        final success = await client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.tradevision://login-callback/',
        );
        return success;
      }
    } catch (e) {
      debugPrint('[SupabaseService] signInWithGoogle failed: $e');
      rethrow;
    }
  }

  /// Sign out from Supabase Auth
  Future<void> signOut() async {
    try {
      if (_initialized && client != null) {
        await client!.auth.signOut();
      }
    } catch (e) {
      debugPrint('[SupabaseService] signOut error: $e');
    } finally {
      await StorageService.clearSession();
    }
  }

  /// Get current Supabase user
  User? get currentUser => client?.auth.currentUser;
}
