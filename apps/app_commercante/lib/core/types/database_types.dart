// Fichier généré par scripts/gen_types.mjs à partir de supabase/migrations — ne pas modifier à la main.
// ignore_for_file: constant_identifier_names, public_member_api_docs, lines_longer_than_80_chars, prefer_if_null_operators, prefer_null_aware_operators

enum ModePaiementAbonnement {
  especes('especes'),
  virement('virement'),
  mobileMoney('mobile_money');

  const ModePaiementAbonnement(this.valeur);
  final String valeur;

  static ModePaiementAbonnement depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum PlateformeAppareil {
  android('android'),
  ios('ios'),
  web('web');

  const PlateformeAppareil(this.valeur);
  final String valeur;

  static PlateformeAppareil depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum RolePlateforme {
  superAdmin('super_admin'),
  support('support'),
  aucun('aucun');

  const RolePlateforme(this.valeur);
  final String valeur;

  static RolePlateforme depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum StatutAbonnement {
  essai('essai'),
  actif('actif'),
  grace('grace'),
  suspendu('suspendu'),
  expire('expire'),
  annule('annule');

  const StatutAbonnement(this.valeur);
  final String valeur;

  static StatutAbonnement depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum StatutBoutique {
  essai('essai'),
  actif('actif'),
  grace('grace'),
  suspendu('suspendu'),
  ferme('ferme');

  const StatutBoutique(this.valeur);
  final String valeur;

  static StatutBoutique depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum StatutCommercante {
  active('active'),
  desactivee('desactivee');

  const StatutCommercante(this.valeur);
  final String valeur;

  static StatutCommercante depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum StatutMembre {
  invite('invite'),
  actif('actif'),
  desactive('desactive');

  const StatutMembre(this.valeur);
  final String valeur;

  static StatutMembre depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

/// Noms des tables et vues.
abstract final class Tables {
  static const abonnements = 'abonnements';
  static const appareils = 'appareils';
  static const boutiques = 'boutiques';
  static const commercantes = 'commercantes';
  static const journalAudit = 'journal_audit';
  static const membresBoutique = 'membres_boutique';
  static const notifications = 'notifications';
  static const paiementsAbonnement = 'paiements_abonnement';
  static const permissions = 'permissions';
  static const permissionsRole = 'permissions_role';
  static const plans = 'plans';
  static const profils = 'profils';
  static const roles = 'roles';
  static const tentativesConnexion = 'tentatives_connexion';
}

/// Noms des fonctions SQL (RPC).
abstract final class Rpc {
  static const boutiqueEstActive = 'boutique_est_active';
  static const creerBoutiqueAvecDefauts = 'creer_boutique_avec_defauts';
  static const creerCommercanteAvecBoutique = 'creer_commercante_avec_boutique';
  static const enregistrerEchecConnexion = 'enregistrer_echec_connexion';
  static const enregistrerPaiementAbonnement =
      'enregistrer_paiement_abonnement';
  static const inviterMembre = 'inviter_membre';
  static const mesPermissions = 'mes_permissions';
  static const reinitialiserTentativesConnexion =
      'reinitialiser_tentatives_connexion';
  static const verifierVerrouConnexion = 'verifier_verrou_connexion';
}

/// Table `abonnements`.
class AbonnementsRow {
  const AbonnementsRow({
    required this.id,
    required this.boutiqueId,
    required this.planId,
    required this.statut,
    required this.debutLe,
    this.finLe,
    this.graceJusquAu,
    required this.renouvellementAuto,
    required this.remise,
    this.notes,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String planId;
  final StatutAbonnement statut;
  final DateTime debutLe;
  final DateTime? finLe;
  final DateTime? graceJusquAu;
  final bool renouvellementAuto;
  final double remise;
  final String? notes;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory AbonnementsRow.depuisJson(Map<String, dynamic> json) =>
      AbonnementsRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        planId: json['plan_id'] as String,
        statut: StatutAbonnement.depuisJson(json['statut'] as String),
        debutLe: DateTime.parse(json['debut_le'] as String),
        finLe: json['fin_le'] == null
            ? null
            : DateTime.parse(json['fin_le'] as String),
        graceJusquAu: json['grace_jusqu_au'] == null
            ? null
            : DateTime.parse(json['grace_jusqu_au'] as String),
        renouvellementAuto: json['renouvellement_auto'] as bool,
        remise: (json['remise'] as num).toDouble(),
        notes: json['notes'] == null ? null : json['notes'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'plan_id': planId,
    'statut': statut.valeur,
    'debut_le': debutLe.toIso8601String(),
    'fin_le': finLe?.toIso8601String(),
    'grace_jusqu_au': graceJusquAu?.toIso8601String(),
    'renouvellement_auto': renouvellementAuto,
    'remise': remise,
    'notes': notes,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `appareils`.
class AppareilsRow {
  const AppareilsRow({
    required this.id,
    required this.utilisateurId,
    this.boutiqueId,
    this.jetonFcm,
    required this.plateforme,
    this.nom,
    required this.derniereActivite,
    required this.creeLe,
  });

  final String id;
  final String utilisateurId;
  final String? boutiqueId;
  final String? jetonFcm;
  final PlateformeAppareil plateforme;
  final String? nom;
  final DateTime derniereActivite;
  final DateTime creeLe;

  factory AppareilsRow.depuisJson(Map<String, dynamic> json) => AppareilsRow(
    id: json['id'] as String,
    utilisateurId: json['utilisateur_id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    jetonFcm: json['jeton_fcm'] == null ? null : json['jeton_fcm'] as String,
    plateforme: PlateformeAppareil.depuisJson(json['plateforme'] as String),
    nom: json['nom'] == null ? null : json['nom'] as String,
    derniereActivite: DateTime.parse(json['derniere_activite'] as String),
    creeLe: DateTime.parse(json['cree_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'utilisateur_id': utilisateurId,
    'boutique_id': boutiqueId,
    'jeton_fcm': jetonFcm,
    'plateforme': plateforme.valeur,
    'nom': nom,
    'derniere_activite': derniereActivite.toIso8601String(),
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Table `boutiques`.
class BoutiquesRow {
  const BoutiquesRow({
    required this.id,
    required this.commercanteId,
    this.nomAr,
    this.nomFr,
    required this.slug,
    required this.codeBoutique,
    this.typeActivite,
    this.logoUrl,
    this.telephone,
    this.whatsapp,
    this.adresse,
    this.ville,
    required this.devise,
    required this.langueParDefaut,
    required this.fuseauHoraire,
    required this.statut,
    required this.parametres,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String commercanteId;
  final String? nomAr;
  final String? nomFr;
  final String slug;
  final String codeBoutique;
  final String? typeActivite;
  final String? logoUrl;
  final String? telephone;
  final String? whatsapp;
  final String? adresse;
  final String? ville;
  final String devise;
  final String langueParDefaut;
  final String fuseauHoraire;
  final StatutBoutique statut;
  final dynamic parametres;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory BoutiquesRow.depuisJson(Map<String, dynamic> json) => BoutiquesRow(
    id: json['id'] as String,
    commercanteId: json['commercante_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    slug: json['slug'] as String,
    codeBoutique: json['code_boutique'] as String,
    typeActivite: json['type_activite'] == null
        ? null
        : json['type_activite'] as String,
    logoUrl: json['logo_url'] == null ? null : json['logo_url'] as String,
    telephone: json['telephone'] == null ? null : json['telephone'] as String,
    whatsapp: json['whatsapp'] == null ? null : json['whatsapp'] as String,
    adresse: json['adresse'] == null ? null : json['adresse'] as String,
    ville: json['ville'] == null ? null : json['ville'] as String,
    devise: json['devise'] as String,
    langueParDefaut: json['langue_par_defaut'] as String,
    fuseauHoraire: json['fuseau_horaire'] as String,
    statut: StatutBoutique.depuisJson(json['statut'] as String),
    parametres: json['parametres'],
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'commercante_id': commercanteId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'slug': slug,
    'code_boutique': codeBoutique,
    'type_activite': typeActivite,
    'logo_url': logoUrl,
    'telephone': telephone,
    'whatsapp': whatsapp,
    'adresse': adresse,
    'ville': ville,
    'devise': devise,
    'langue_par_defaut': langueParDefaut,
    'fuseau_horaire': fuseauHoraire,
    'statut': statut.valeur,
    'parametres': parametres,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `commercantes`.
class CommercantesRow {
  const CommercantesRow({
    required this.id,
    required this.utilisateurId,
    this.nomAr,
    this.nomFr,
    required this.telephone,
    this.whatsapp,
    this.email,
    this.ville,
    this.notes,
    required this.statut,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String utilisateurId;
  final String? nomAr;
  final String? nomFr;
  final String telephone;
  final String? whatsapp;
  final String? email;
  final String? ville;
  final String? notes;
  final StatutCommercante statut;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory CommercantesRow.depuisJson(Map<String, dynamic> json) =>
      CommercantesRow(
        id: json['id'] as String,
        utilisateurId: json['utilisateur_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        telephone: json['telephone'] as String,
        whatsapp: json['whatsapp'] == null ? null : json['whatsapp'] as String,
        email: json['email'] == null ? null : json['email'] as String,
        ville: json['ville'] == null ? null : json['ville'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        statut: StatutCommercante.depuisJson(json['statut'] as String),
        creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'utilisateur_id': utilisateurId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'telephone': telephone,
    'whatsapp': whatsapp,
    'email': email,
    'ville': ville,
    'notes': notes,
    'statut': statut.valeur,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `journal_audit`.
class JournalAuditRow {
  const JournalAuditRow({
    required this.id,
    this.boutiqueId,
    this.utilisateurId,
    required this.action,
    required this.entite,
    this.entiteId,
    this.avant,
    this.apres,
    this.details,
    required this.dateAction,
  });

  final String id;
  final String? boutiqueId;
  final String? utilisateurId;
  final String action;
  final String entite;
  final String? entiteId;
  final dynamic avant;
  final dynamic apres;
  final dynamic details;
  final DateTime dateAction;

  factory JournalAuditRow.depuisJson(Map<String, dynamic> json) =>
      JournalAuditRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        action: json['action'] as String,
        entite: json['entite'] as String,
        entiteId: json['entite_id'] == null
            ? null
            : json['entite_id'] as String,
        avant: json['avant'] == null ? null : json['avant'],
        apres: json['apres'] == null ? null : json['apres'],
        details: json['details'] == null ? null : json['details'],
        dateAction: DateTime.parse(json['date_action'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'utilisateur_id': utilisateurId,
    'action': action,
    'entite': entite,
    'entite_id': entiteId,
    'avant': avant,
    'apres': apres,
    'details': details,
    'date_action': dateAction.toIso8601String(),
  };
}

/// Table `membres_boutique`.
class MembresBoutiqueRow {
  const MembresBoutiqueRow({
    required this.id,
    required this.boutiqueId,
    required this.utilisateurId,
    required this.roleId,
    required this.statut,
    required this.inviteLe,
    this.invitePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String utilisateurId;
  final String roleId;
  final StatutMembre statut;
  final DateTime inviteLe;
  final String? invitePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory MembresBoutiqueRow.depuisJson(Map<String, dynamic> json) =>
      MembresBoutiqueRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        utilisateurId: json['utilisateur_id'] as String,
        roleId: json['role_id'] as String,
        statut: StatutMembre.depuisJson(json['statut'] as String),
        inviteLe: DateTime.parse(json['invite_le'] as String),
        invitePar: json['invite_par'] == null
            ? null
            : json['invite_par'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'utilisateur_id': utilisateurId,
    'role_id': roleId,
    'statut': statut.valeur,
    'invite_le': inviteLe.toIso8601String(),
    'invite_par': invitePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `notifications`.
class NotificationsRow {
  const NotificationsRow({
    required this.id,
    this.boutiqueId,
    required this.utilisateurId,
    required this.type_,
    this.titreAr,
    this.titreFr,
    this.corpsAr,
    this.corpsFr,
    required this.cible,
    required this.donnees,
    this.luLe,
    this.creePar,
    required this.creeLe,
  });

  final String id;
  final String? boutiqueId;
  final String utilisateurId;
  final String type_;
  final String? titreAr;
  final String? titreFr;
  final String? corpsAr;
  final String? corpsFr;
  final String cible;
  final dynamic donnees;
  final DateTime? luLe;
  final String? creePar;
  final DateTime creeLe;

  factory NotificationsRow.depuisJson(Map<String, dynamic> json) =>
      NotificationsRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        utilisateurId: json['utilisateur_id'] as String,
        type_: json['type'] as String,
        titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
        titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
        corpsAr: json['corps_ar'] == null ? null : json['corps_ar'] as String,
        corpsFr: json['corps_fr'] == null ? null : json['corps_fr'] as String,
        cible: json['cible'] as String,
        donnees: json['donnees'],
        luLe: json['lu_le'] == null
            ? null
            : DateTime.parse(json['lu_le'] as String),
        creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'utilisateur_id': utilisateurId,
    'type': type_,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'corps_ar': corpsAr,
    'corps_fr': corpsFr,
    'cible': cible,
    'donnees': donnees,
    'lu_le': luLe?.toIso8601String(),
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Table `paiements_abonnement`.
class PaiementsAbonnementRow {
  const PaiementsAbonnementRow({
    required this.id,
    required this.abonnementId,
    required this.boutiqueId,
    required this.montant,
    required this.devise,
    required this.mode,
    this.reference,
    this.justificatifUrl,
    required this.payeLe,
    required this.periodeMois,
    this.enregistrePar,
    required this.creeLe,
  });

  final String id;
  final String abonnementId;
  final String boutiqueId;
  final double montant;
  final String devise;
  final ModePaiementAbonnement mode;
  final String? reference;
  final String? justificatifUrl;
  final DateTime payeLe;
  final int periodeMois;
  final String? enregistrePar;
  final DateTime creeLe;

  factory PaiementsAbonnementRow.depuisJson(Map<String, dynamic> json) =>
      PaiementsAbonnementRow(
        id: json['id'] as String,
        abonnementId: json['abonnement_id'] as String,
        boutiqueId: json['boutique_id'] as String,
        montant: (json['montant'] as num).toDouble(),
        devise: json['devise'] as String,
        mode: ModePaiementAbonnement.depuisJson(json['mode'] as String),
        reference: json['reference'] == null
            ? null
            : json['reference'] as String,
        justificatifUrl: json['justificatif_url'] == null
            ? null
            : json['justificatif_url'] as String,
        payeLe: DateTime.parse(json['paye_le'] as String),
        periodeMois: json['periode_mois'] as int,
        enregistrePar: json['enregistre_par'] == null
            ? null
            : json['enregistre_par'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'abonnement_id': abonnementId,
    'boutique_id': boutiqueId,
    'montant': montant,
    'devise': devise,
    'mode': mode.valeur,
    'reference': reference,
    'justificatif_url': justificatifUrl,
    'paye_le': payeLe.toIso8601String(),
    'periode_mois': periodeMois,
    'enregistre_par': enregistrePar,
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Table `permissions`.
class PermissionsRow {
  const PermissionsRow({
    required this.cle,
    required this.module,
    required this.nomAr,
    required this.nomFr,
  });

  final String cle;
  final String module;
  final String nomAr;
  final String nomFr;

  factory PermissionsRow.depuisJson(Map<String, dynamic> json) =>
      PermissionsRow(
        cle: json['cle'] as String,
        module: json['module'] as String,
        nomAr: json['nom_ar'] as String,
        nomFr: json['nom_fr'] as String,
      );

  Map<String, dynamic> versJson() => {
    'cle': cle,
    'module': module,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
  };
}

/// Table `permissions_role`.
class PermissionsRoleRow {
  const PermissionsRoleRow({
    required this.roleId,
    required this.clePermission,
    required this.autorise,
  });

  final String roleId;
  final String clePermission;
  final bool autorise;

  factory PermissionsRoleRow.depuisJson(Map<String, dynamic> json) =>
      PermissionsRoleRow(
        roleId: json['role_id'] as String,
        clePermission: json['cle_permission'] as String,
        autorise: json['autorise'] as bool,
      );

  Map<String, dynamic> versJson() => {
    'role_id': roleId,
    'cle_permission': clePermission,
    'autorise': autorise,
  };
}

/// Table `plans`.
class PlansRow {
  const PlansRow({
    required this.id,
    required this.code,
    required this.nomAr,
    required this.nomFr,
    this.descriptionAr,
    this.descriptionFr,
    required this.prixMensuel,
    required this.prixAnnuel,
    required this.devise,
    required this.limites,
    this.dureeEssaiJours,
    required this.ordre,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String code;
  final String nomAr;
  final String nomFr;
  final String? descriptionAr;
  final String? descriptionFr;
  final double prixMensuel;
  final double prixAnnuel;
  final String devise;
  final dynamic limites;
  final int? dureeEssaiJours;
  final int ordre;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory PlansRow.depuisJson(Map<String, dynamic> json) => PlansRow(
    id: json['id'] as String,
    code: json['code'] as String,
    nomAr: json['nom_ar'] as String,
    nomFr: json['nom_fr'] as String,
    descriptionAr: json['description_ar'] == null
        ? null
        : json['description_ar'] as String,
    descriptionFr: json['description_fr'] == null
        ? null
        : json['description_fr'] as String,
    prixMensuel: (json['prix_mensuel'] as num).toDouble(),
    prixAnnuel: (json['prix_annuel'] as num).toDouble(),
    devise: json['devise'] as String,
    limites: json['limites'],
    dureeEssaiJours: json['duree_essai_jours'] == null
        ? null
        : json['duree_essai_jours'] as int,
    ordre: json['ordre'] as int,
    actif: json['actif'] as bool,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'code': code,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'description_ar': descriptionAr,
    'description_fr': descriptionFr,
    'prix_mensuel': prixMensuel,
    'prix_annuel': prixAnnuel,
    'devise': devise,
    'limites': limites,
    'duree_essai_jours': dureeEssaiJours,
    'ordre': ordre,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `profils`.
class ProfilsRow {
  const ProfilsRow({
    required this.id,
    this.nomAr,
    this.nomFr,
    this.telephone,
    this.email,
    required this.rolePlateforme,
    required this.langue,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String? nomAr;
  final String? nomFr;
  final String? telephone;
  final String? email;
  final RolePlateforme rolePlateforme;
  final String langue;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ProfilsRow.depuisJson(Map<String, dynamic> json) => ProfilsRow(
    id: json['id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    telephone: json['telephone'] == null ? null : json['telephone'] as String,
    email: json['email'] == null ? null : json['email'] as String,
    rolePlateforme: RolePlateforme.depuisJson(
      json['role_plateforme'] as String,
    ),
    langue: json['langue'] as String,
    actif: json['actif'] as bool,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'telephone': telephone,
    'email': email,
    'role_plateforme': rolePlateforme.valeur,
    'langue': langue,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `roles`.
class RolesRow {
  const RolesRow({
    required this.id,
    this.boutiqueId,
    required this.cle,
    required this.nomAr,
    required this.nomFr,
    required this.systeme,
    required this.creeLe,
  });

  final String id;
  final String? boutiqueId;
  final String cle;
  final String nomAr;
  final String nomFr;
  final bool systeme;
  final DateTime creeLe;

  factory RolesRow.depuisJson(Map<String, dynamic> json) => RolesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    cle: json['cle'] as String,
    nomAr: json['nom_ar'] as String,
    nomFr: json['nom_fr'] as String,
    systeme: json['systeme'] as bool,
    creeLe: DateTime.parse(json['cree_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'cle': cle,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'systeme': systeme,
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Table `tentatives_connexion`.
class TentativesConnexionRow {
  const TentativesConnexionRow({
    required this.identifiant,
    required this.echecs,
    this.verrouilleJusquAu,
    required this.derniereTentativeLe,
  });

  final String identifiant;
  final int echecs;
  final DateTime? verrouilleJusquAu;
  final DateTime derniereTentativeLe;

  factory TentativesConnexionRow.depuisJson(Map<String, dynamic> json) =>
      TentativesConnexionRow(
        identifiant: json['identifiant'] as String,
        echecs: json['echecs'] as int,
        verrouilleJusquAu: json['verrouille_jusqu_au'] == null
            ? null
            : DateTime.parse(json['verrouille_jusqu_au'] as String),
        derniereTentativeLe: DateTime.parse(
          json['derniere_tentative_le'] as String,
        ),
      );

  Map<String, dynamic> versJson() => {
    'identifiant': identifiant,
    'echecs': echecs,
    'verrouille_jusqu_au': verrouilleJusquAu?.toIso8601String(),
    'derniere_tentative_le': derniereTentativeLe.toIso8601String(),
  };
}
