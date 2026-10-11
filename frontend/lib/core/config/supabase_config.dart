/// Supabase and OAuth Configuration for TradeVision
///
/// Enter your Supabase Project URL and Anon Key below, or pass them
/// at build/run time via:
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=your_key
class SupabaseConfig {
  /// Supabase project URL (Found in Supabase Dashboard -> Project Settings -> API)
  static const String _defaultUrl = 'https://zbxsilwxranbodignzmp.supabase.co';

  /// Supabase anon public key (Found in Supabase Dashboard -> Project Settings -> API)
  static const String _defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpieHNpbHd4cmFuYm9kaWduem1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3MTMxNDcsImV4cCI6MjEwNzI4OTE0N30.lmVA5wRFuEksoAMXTduQaAGt9WYn15y3gZ0MKqna9U8';

  /// Google OAuth Web Client ID (Optional for web OAuth redirect, required for native Google ID Token)
  static const String _defaultGoogleWebClientId = '509472566055-sieic4puq8opcp7ikloea29t5pm5on6v.apps.googleusercontent.com';

  static String get url {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return _defaultUrl;
  }

  static String get anonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) return envKey;
    return _defaultAnonKey;
  }

  static String get googleWebClientId {
    const envId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (envId.isNotEmpty) return envId;
    return _defaultGoogleWebClientId;
  }

  /// Whether Supabase credentials have been configured with real values
  static bool get isConfigured {
    final u = url.trim();
    final k = anonKey.trim();
    return u.isNotEmpty &&
        !u.contains('YOUR_PROJECT_ID') &&
        k.isNotEmpty &&
        !k.contains('YOUR_SUPABASE_ANON_KEY');
  }
}
