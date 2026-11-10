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
    'devis_expire' => l10n.serverError_devis_expire,
    'deja_converti' => l10n.serverError_deja_converti,
    'bl_non_valide' => l10n.serverError_bl_non_valide,
    'transition_invalide' => l10n.serverError_transition_invalide,
    'annulation_impossible' => l10n.serverError_annulation_impossible,
    'quantite_avoir_excessive' => l10n.serverError_quantite_avoir_excessive,
    'avoir_excessif' => l10n.serverError_avoir_excessif,
    'remboursement_excessif' => l10n.serverError_remboursement_excessif,
    'document_non_modifiable' => l10n.serverError_document_non_modifiable,
    'clients_differents' => l10n.serverError_clients_differents,
    'motif_requis' => l10n.serverError_motif_requis,
    'destinataire_introuvable' => l10n.serverError_destinataire_introuvable,
    'transfert_deja_traite' => l10n.serverError_transfert_deja_traite,
    'correspondance_requise' => l10n.serverError_correspondance_requise,
    'trop_de_requetes' => l10n.serverError_trop_de_requetes,
    _ => l10n.unknownError(message),
  };
}
