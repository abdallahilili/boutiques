import 'package:app_commercante/features/auth/data/auth_repository.dart';
import 'package:app_commercante/features/auth/presentation/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  LoginException? toThrow;
  String? lastPhone;
  String? lastPin;
  bool signedIn = false;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> signIn({required String phone, required String pin}) async {
    lastPhone = phone;
    lastPin = pin;
    final error = toThrow;
    if (error != null) throw error;
    signedIn = true;
  }

  @override
  Future<void> signOut() async => signedIn = false;
}

void main() {
  late FakeAuthRepository repo;
  late int signedInCalls;
  late int signedOutCalls;
  late AuthController controller;
  final now = DateTime(2026, 1, 1, 12);

  setUp(() {
    repo = FakeAuthRepository();
    signedInCalls = 0;
    signedOutCalls = 0;
    controller = AuthController(
      repo,
      onSignedIn: () => signedInCalls++,
      onSignedOut: () => signedOutCalls++,
      clock: () => now,
    );
  });

  test('connexion réussie : navigation déclenchée, aucune erreur', () async {
    await controller.signIn(' 36000001 ', '1234');
    expect(repo.lastPhone, '36000001');
    expect(repo.lastPin, '1234');
    expect(signedInCalls, 1);
    expect(controller.error.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test('identifiants invalides : erreur exposée, pas de navigation', () async {
    repo.toThrow = const LoginException(AuthFailure.invalidCredentials);
    await controller.signIn('36000001', '0000');
    expect(controller.error.value, isA<InvalidCredentials>());
    expect(signedInCalls, 0);
    expect(controller.isLoading.value, isFalse);
  });

  test('verrouillage : minutes restantes arrondies au supérieur', () async {
    repo.toThrow = LoginException(AuthFailure.locked, lockedUntil: now.add(const Duration(minutes: 14, seconds: 30)));
    await controller.signIn('36000001', '0000');
    expect(controller.error.value, isA<AccountLocked>().having((e) => e.minutes, 'minutes', 15));
  });

  test('verrouillage sans date : 15 minutes par défaut', () async {
    repo.toThrow = const LoginException(AuthFailure.locked);
    await controller.signIn('36000001', '0000');
    expect(controller.error.value, isA<AccountLocked>().having((e) => e.minutes, 'minutes', 15));
  });

  test('erreurs réseau et inconnues sont distinguées', () async {
    repo.toThrow = const LoginException(AuthFailure.network);
    await controller.signIn('36000001', '1234');
    expect(controller.error.value, isA<NetworkProblem>());
    repo.toThrow = const LoginException(AuthFailure.unknown);
    await controller.signIn('36000001', '1234');
    expect(controller.error.value, isA<UnknownProblem>());
  });

  test('une nouvelle tentative réinitialise l\'erreur précédente', () async {
    repo.toThrow = const LoginException(AuthFailure.invalidCredentials);
    await controller.signIn('36000001', '0000');
    repo.toThrow = null;
    await controller.signIn('36000001', '1234');
    expect(controller.error.value, isNull);
    expect(signedInCalls, 1);
  });

  test('déconnexion : session fermée et navigation vers la connexion', () async {
    repo.signedIn = true;
    await controller.signOut();
    expect(repo.signedIn, isFalse);
    expect(signedOutCalls, 1);
  });
}
