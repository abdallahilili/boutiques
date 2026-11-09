import 'package:get/get.dart';

import '../data/auth_repository.dart';

/// Résultat affichable d'une tentative de connexion (traduit côté UI avec les ARB).
sealed class LoginError {
  const LoginError();
}

class InvalidCredentials extends LoginError {
  const InvalidCredentials();
}

class AccountLocked extends LoginError {
  const AccountLocked(this.minutes);
  final int minutes;
}

class NetworkProblem extends LoginError {
  const NetworkProblem();
}

class UnknownProblem extends LoginError {
  const UnknownProblem();
}

class AuthController extends GetxController {
  AuthController(this._repository, {required this.onSignedIn, required this.onSignedOut, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AuthRepository _repository;
  final void Function() onSignedIn;
  final void Function() onSignedOut;
  final DateTime Function() _clock;

  final isLoading = false.obs;
  final error = Rxn<LoginError>();

  bool get isSignedIn => _repository.isSignedIn;

  Future<void> signIn(String phone, String pin) async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = null;
    try {
      await _repository.signIn(phone: phone.trim(), pin: pin);
      onSignedIn();
    } on LoginException catch (e) {
      error.value = switch (e.failure) {
        AuthFailure.invalidCredentials => const InvalidCredentials(),
        AuthFailure.locked => AccountLocked(_minutesUntil(e.lockedUntil)),
        AuthFailure.network => const NetworkProblem(),
        AuthFailure.unknown => const UnknownProblem(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    onSignedOut();
  }

  int _minutesUntil(DateTime? until) {
    if (until == null) return 15;
    final remaining = until.difference(_clock()).inMinutes + 1;
    return remaining < 1 ? 1 : remaining;
  }
}
