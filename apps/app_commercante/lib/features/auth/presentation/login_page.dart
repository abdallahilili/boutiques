import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n, LoginError error) => switch (error) {
        InvalidCredentials() => l10n.invalidCredentials,
        AccountLocked(:final minutes) => l10n.accountLocked(minutes),
        NetworkProblem() => l10n.networkError,
        UnknownProblem() => l10n.genericError,
      };

  void _submit(AuthController auth) {
    if (_formKey.currentState?.validate() ?? false) {
      auth.signIn(_phone.text, _pin.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = Get.find<AuthController>();
    final locale = Get.find<LocaleController>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(
            () => TextButton(
              onPressed: () => locale.setLocale(Locale(locale.isArabic ? 'fr' : 'ar')),
              child: Text(locale.isArabic ? l10n.french : l10n.arabic),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.appTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(l10n.login, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: l10n.phone, prefixIcon: const Icon(Icons.phone_outlined)),
                      validator: (v) => (v == null || v.trim().length < 6) ? l10n.phoneRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      decoration: InputDecoration(labelText: l10n.pin, prefixIcon: const Icon(Icons.lock_outline)),
                      validator: (v) => (v == null || v.length != 4) ? l10n.pinInvalid : null,
                      onFieldSubmitted: (_) => _submit(auth),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final error = auth.error.value;
                      return error == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _message(l10n, error),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            );
                    }),
                    Obx(
                      () => FilledButton(
                        onPressed: auth.isLoading.value ? null : () => _submit(auth),
                        child: auth.isLoading.value
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Text(l10n.loginButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
