/// Configuration injectée à la compilation : `flutter run --dart-define-from-file=.env`.
/// Seule la clé publique (publishable/anon) est utilisée ici, jamais la clé service_role.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static void verify() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY sont requis : '
        'lancez l\'app avec --dart-define-from-file=.env (voir .env.example).',
      );
    }
  }
}
