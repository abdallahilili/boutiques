import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routing/app_pages.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_controller.dart';
import 'boot_controller.dart';

class BootPage extends StatefulWidget {
  const BootPage({super.key});

  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  final _boot = Get.find<BootController>();
  Object? _error;
  bool _noShop = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _noShop = false;
    });
    try {
      final destination = await _boot.start();
      if (!mounted) return;
      switch (destination) {
        case BootDestination.home:
          Get.offAllNamed(Routes.home);
        case BootDestination.onboarding:
          Get.offAllNamed(Routes.onboarding);
        case BootDestination.suspended:
          Get.offAllNamed(Routes.suspended);
        case BootDestination.noShop:
          setState(() => _noShop = true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_noShop) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.noShopTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.noShopText, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: Get.find<AuthController>().signOut, child: Text(l10n.logout)),
            ]),
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(body: ErrorView(message: l10n.networkError, onRetry: _run));
    }
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.bootLoading),
        ]),
      ),
    );
  }
}
