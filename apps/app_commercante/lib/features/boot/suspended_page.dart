import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routing/app_pages.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_controller.dart';
import 'boot_controller.dart';

/// Information claire à l'expiration de l'abonnement ; la consultation reste possible (lecture seule).
class SuspendedPage extends StatelessWidget {
  const SuspendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_clock, size: 72, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(l10n.suspendedTitle, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.suspendedText, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Get.find<BootController>().acknowledgeSuspension();
                  Get.offAllNamed(Routes.home);
                },
                child: Text(l10n.continueReadOnly),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: Get.find<AuthController>().signOut, child: Text(l10n.logout)),
            ]),
          ),
        ),
      ),
    );
  }
}
