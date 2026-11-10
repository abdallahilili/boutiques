/// Configuration injectée à la compilation : `flutter run --dart-define-from-file=.env`.
/// Seule la clé publique (publishable/anon) est utilisée ici, jamais la clé service_role.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Firebase (push) : identifiants publics du projet, fournis à la compilation. Sans eux, le push est désactivé.
  static const fcmApiKey = String.fromEnvironment('FCM_API_KEY');
  static const fcmAppId = String.fromEnvironment('FCM_APP_ID');
  static const fcmSenderId = String.fromEnvironment('FCM_SENDER_ID');
  static const fcmProjectId = String.fromEnvironment('FCM_PROJECT_ID');

  static bool get pushConfigured => fcmApiKey.isNotEmpty && fcmAppId.isNotEmpty && fcmSenderId.isNotEmpty && fcmProjectId.isNotEmpty;

  static void verify() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY sont requis : '
        'lancez l\'app avec --dart-define-from-file=.env (voir .env.example).',
      );
    }
  }
}
