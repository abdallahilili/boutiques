import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../l10n/app_localizations.dart';
import '../session/shop_controller.dart';
import '../sync/sync_service.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message, this.icon = Icons.inbox_outlined});

  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message ?? AppLocalizations.of(context).emptyList, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).retry)),
            ],
          ]),
        ),
      );
}

Future<bool> confirmDialog(BuildContext context, {required String title, String? message, String? confirmLabel}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showMessage(String message, {bool error = false}) {
  Get.rawSnackbar(
    message: message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: error ? Colors.red.shade700 : Colors.black87,
    margin: const EdgeInsets.all(12),
    borderRadius: 12,
    duration: const Duration(seconds: 3),
  );
}

/// Deux champs de nom (arabe / français) : au moins un des deux est obligatoire.
class BilingualNameFields extends StatelessWidget {
  const BilingualNameFields({super.key, required this.arabic, required this.french, this.label});

  final TextEditingController arabic;
  final TextEditingController french;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? atLeastOne(String? _) => (arabic.text.trim().isEmpty && french.text.trim().isEmpty) ? l10n.nameRequired : null;
    return Column(children: [
      TextFormField(controller: arabic, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: l10n.nameAr), validator: atLeastOne),
      const SizedBox(height: 12),
      TextFormField(controller: french, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: l10n.nameFr)),
    ]);
  }
}

/// Champ numérique (montant, quantité) avec validation facultative de minimum.
class NumberField extends StatelessWidget {
  const NumberField({super.key, required this.controller, required this.label, this.required = true, this.min, this.onChanged, this.suffix});

  final TextEditingController controller;
  final String label;
  final bool required;
  final double? min;
  final ValueChanged<String>? onChanged;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return required ? l10n.requiredField : null;
        final value = double.tryParse(v.trim().replaceAll(',', '.'));
        if (value == null) return l10n.requiredField;
        if (min != null && value < min!) return l10n.requiredField;
        return null;
      },
    );
  }
}

/// Bandeaux d'état : hors ligne, opérations en attente, période de grâce, lecture seule (abonnement expiré).
class StatusBanners extends StatelessWidget {
  const StatusBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = Get.find<ShopController>();
    final sync = Get.find<SyncService>();
    final scheme = Theme.of(context).colorScheme;

    Widget banner(String text, Color color, {IconData icon = Icons.info_outline, VoidCallback? onTap}) => Material(
          color: color,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))]),
            ),
          ),
        );

    return Obx(() => Column(mainAxisSize: MainAxisSize.min, children: [
          if (shop.readOnly) banner(l10n.readOnlyBanner, scheme.errorContainer, icon: Icons.lock_outline),
          if (shop.inGrace) banner(l10n.graceBanner, scheme.tertiaryContainer, icon: Icons.warning_amber_outlined),
          if (!sync.online.value) banner(l10n.offlineBanner, scheme.secondaryContainer, icon: Icons.cloud_off_outlined),
        ]));
  }
}
