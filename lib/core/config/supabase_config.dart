/// Supabase project connection details. Never hardcode these — they come
/// from `--dart-define` at build/run time so no key sits in the repository:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
/// ```
///
/// Only the publishable (anon) key belongs here. The secret/service-role key
/// bypasses Row Level Security and must never ship inside the app — it only
/// belongs in a server-side Edge Function's own environment.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
