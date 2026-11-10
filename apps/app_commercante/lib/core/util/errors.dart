import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Message lisible pour une erreur serveur : les fonctions SQL préfixent leurs messages d'un code
/// (`stock_insuffisant: …`) traduit ici ; sinon le détail brut est affiché.
String friendlyError(AppLocalizations l10n, Object error) {
  final message = error is PostgrestException ? error.message : '$error';
  final code = RegExp(r'^[a-z_]+').firstMatch(message)?.group(0) ?? '';
  return switch (code) {
    'stock_insuffisant' => l10n.serverError_stock_insuffisant,
    'client_requis' => l10n.serverError_client_requis,
    'plafond_credit_depasse' => l10n.serverError_plafond_credit_depasse,
    'acces_refuse' => message.contains('pos.modifier_prix') ? l10n.serverError_prix_non_autorise : l10n.permissionDenied,
    'boutique_inactive' => l10n.serverError_boutique_inactive,
    'quota_depasse' => l10n.serverError_quota_depasse,
    'motif_obligatoire' => l10n.serverError_motif_obligatoire,
    _ => l10n.unknownError(message),
  };
}
