import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthFailure { invalidCredentials, locked, network, unknown }

class LoginException implements Exception {
  const LoginException(this.failure, {this.lockedUntil});

  final AuthFailure failure;
  final DateTime? lockedUntil;

  @override
  String toString() => 'LoginException($failure)';
}

abstract interface class AuthRepository {
  bool get isSignedIn;

  /// Connexion par téléphone + code à 4 chiffres (convertis en secret côté serveur).
  Future<void> signIn({required String phone, required String pin});

  Future<void> signOut();
}

/// Passe par l'Edge Function `connexion_telephone_pin` : le code n'est jamais envoyé à Auth tel quel
/// et les tentatives sont limitées (5 échecs = verrouillage temporaire).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  Future<void> signIn({required String phone, required String pin}) async {
    try {
      final response = await _client.functions.invoke(
        'connexion_telephone_pin',
        body: {'telephone': phone, 'code': pin, 'contexte': 'commercante'},
      );
      final session = (response.data as Map<String, dynamic>)['session'] as Map<String, dynamic>;
      await _client.auth.setSession(session['refresh_token'] as String);
    } on FunctionException catch (e) {
      throw _map(e);
    } on LoginException {
      rethrow;
    } catch (_) {
      throw const LoginException(AuthFailure.network);
    }
  }

  LoginException _map(FunctionException e) {
    switch (e.status) {
      case 400:
      case 401:
        return const LoginException(AuthFailure.invalidCredentials);
      case 429:
        final details = e.details;
        final until = details is Map ? DateTime.tryParse('${details['verrouille_jusqu_au']}') : null;
        return LoginException(AuthFailure.locked, lockedUntil: until);
      default:
        return const LoginException(AuthFailure.unknown);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
