// Fichier généré par scripts/gen_types.mjs à partir de supabase/migrations — ne pas modifier à la main.
// ignore_for_file: constant_identifier_names, public_member_api_docs, lines_longer_than_80_chars, prefer_if_null_operators, prefer_null_aware_operators

enum CanalVente {
  caisse('caisse'),
  siteWeb('site_web'),
  whatsapp('whatsapp'),
  instagram('instagram'),
  facebook('facebook'),
  telephone('telephone'),
  autre('autre');

  const CanalVente(this.valeur);
  final String valeur;

  static CanalVente depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum ModeLivraison {
  livraison('livraison'),
  retrait('retrait');

  const ModeLivraison(this.valeur);
  final String valeur;

  static ModeLivraison depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum ModePaiementAbonnement {
  especes('especes'),
  virement('virement'),
  mobileMoney('mobile_money');

  const ModePaiementAbonnement(this.valeur);
  final String valeur;

  static ModePaiementAbonnement depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum ModePaiementCommande {
  aLaLivraison('a_la_livraison'),
  mobileMoney('mobile_money'),
  especes('especes'),
  autre('autre');

  const ModePaiementCommande(this.valeur);
  final String valeur;

  static ModePaiementCommande depuisJson(String valeur) =>
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

enum StatutCommande {
  nouvelle('nouvelle'),
  confirmee('confirmee'),
  enPreparation('en_preparation'),
  prete('prete'),
  expediee('expediee'),
  livree('livree'),
  annulee('annulee'),
  retournee('retournee');

  const StatutCommande(this.valeur);
  final String valeur;

  static StatutCommande depuisJson(String valeur) =>
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

enum StatutDocumentVente {
  brouillon('brouillon'),
  envoye('envoye'),
  accepte('accepte'),
  refuse('refuse'),
  expire('expire'),
  valide('valide'),
  livre('livre'),
  facture('facture'),
  emise('emise'),
  partiellementPayee('partiellement_payee'),
  payee('payee'),
  annulee('annulee');

  const StatutDocumentVente(this.valeur);
  final String valeur;

  static StatutDocumentVente depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum StatutDomaine {
  nonConfigure('non_configure'),
  enAttente('en_attente'),
  verifie('verifie'),
  erreur('erreur');

  const StatutDomaine(this.valeur);
  final String valeur;

  static StatutDomaine depuisJson(String valeur) =>
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

enum StatutPaiementCommande {
  nonPaye('non_paye'),
  partiel('partiel'),
  paye('paye');

  const StatutPaiementCommande(this.valeur);
  final String valeur;

  static StatutPaiementCommande depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum StatutProduit {
  actif('actif'),
  inactif('inactif');

  const StatutProduit(this.valeur);
  final String valeur;

  static StatutProduit depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum TypeAjustementStock {
  sortieManuelle('sortie_manuelle'),
  inventaire('inventaire'),
  retourFournisseur('retour_fournisseur');

  const TypeAjustementStock(this.valeur);
  final String valeur;

  static TypeAjustementStock depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum TypeDocumentVente {
  devis('devis'),
  bonLivraison('bon_livraison'),
  facture('facture'),
  avoir('avoir'),
  ticket('ticket');

  const TypeDocumentVente(this.valeur);
  final String valeur;

  static TypeDocumentVente depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum TypeModePaiement {
  especes('especes'),
  mobileMoney('mobile_money'),
  banque('banque'),
  carte('carte'),
  credit('credit');

  const TypeModePaiement(this.valeur);
  final String valeur;

  static TypeModePaiement depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

enum TypeMouvementStock {
  entree('entree'),
  sortieVente('sortie_vente'),
  sortieManuelle('sortie_manuelle'),
  retourClient('retour_client'),
  retourFournisseur('retour_fournisseur'),
  ajustement('ajustement'),
  reservation('reservation'),
  liberation('liberation'),
  transfertSortie('transfert_sortie'),
  transfertEntree('transfert_entree');

  const TypeMouvementStock(this.valeur);
  final String valeur;

  static TypeMouvementStock depuisJson(String valeur) =>
      values.firstWhere((e) => e.valeur == valeur);
}

/// Noms des tables et vues.
abstract final class Tables {
  static const abonnements = 'abonnements';
  static const ajustementsStock = 'ajustements_stock';
  static const appareils = 'appareils';
  static const bannieresSite = 'bannieres_site';
  static const bannieresSitePubliques = 'bannieres_site_publiques';
  static const boutiques = 'boutiques';
  static const categories = 'categories';
  static const categoriesDepenses = 'categories_depenses';
  static const categoriesPubliques = 'categories_publiques';
  static const clients = 'clients';
  static const commandes = 'commandes';
  static const commercantes = 'commercantes';
  static const comptesClientesSite = 'comptes_clientes_site';
  static const couleurs = 'couleurs';
  static const couleursPubliques = 'couleurs_publiques';
  static const depenses = 'depenses';
  static const documentsVente = 'documents_vente';
  static const domainesBoutique = 'domaines_boutique';
  static const fournisseurs = 'fournisseurs';
  static const historiqueStatutsCommande = 'historique_statuts_commande';
  static const imagesProduit = 'images_produit';
  static const imagesPubliques = 'images_publiques';
  static const journalAudit = 'journal_audit';
  static const lignesAjustementStock = 'lignes_ajustement_stock';
  static const lignesCommande = 'lignes_commande';
  static const lignesDocumentVente = 'lignes_document_vente';
  static const lignesDocumentVenteVue = 'lignes_document_vente_vue';
  static const lignesReceptionStock = 'lignes_reception_stock';
  static const lignesReceptionStockVue = 'lignes_reception_stock_vue';
  static const limitesDebit = 'limites_debit';
  static const lotsStock = 'lots_stock';
  static const lotsStockVue = 'lots_stock_vue';
  static const marques = 'marques';
  static const membresBoutique = 'membres_boutique';
  static const modeles = 'modeles';
  static const modelesPublics = 'modeles_publics';
  static const modesPaiement = 'modes_paiement';
  static const motifsMouvement = 'motifs_mouvement';
  static const mouvementsStock = 'mouvements_stock';
  static const mouvementsStockVue = 'mouvements_stock_vue';
  static const notifications = 'notifications';
  static const pagesSite = 'pages_site';
  static const pagesSitePubliques = 'pages_site_publiques';
  static const paiements = 'paiements';
  static const paiementsAbonnement = 'paiements_abonnement';
  static const parametresBoutiquePublics = 'parametres_boutique_publics';
  static const parametresSite = 'parametres_site';
  static const permissions = 'permissions';
  static const permissionsRole = 'permissions_role';
  static const plagesNumeros = 'plages_numeros';
  static const plans = 'plans';
  static const produits = 'produits';
  static const produitsPublics = 'produits_publics';
  static const profils = 'profils';
  static const receptionsStock = 'receptions_stock';
  static const receptionsStockVue = 'receptions_stock_vue';
  static const roles = 'roles';
  static const sectionsSite = 'sections_site';
  static const sectionsSitePubliques = 'sections_site_publiques';
  static const sequencesDocuments = 'sequences_documents';
  static const sessionsCaisse = 'sessions_caisse';
  static const stockVariante = 'stock_variante';
  static const tailles = 'tailles';
  static const tentativesConnexion = 'tentatives_connexion';
  static const themesSite = 'themes_site';
  static const unites = 'unites';
  static const variantesProduit = 'variantes_produit';
  static const variantesPubliques = 'variantes_publiques';
  static const zonesLivraison = 'zones_livraison';
  static const zonesLivraisonPubliques = 'zones_livraison_publiques';
}

/// Noms des fonctions SQL (RPC).
abstract final class Rpc {
  static const adminStatistiques = 'admin_statistiques';
  static const ajusterStock = 'ajuster_stock';
  static const attribuerNumeroDocument = 'attribuer_numero_document';
  static const boutiqueEstActive = 'boutique_est_active';
  static const changerStatutCommande = 'changer_statut_commande';
  static const creerBoutiqueAvecDefauts = 'creer_boutique_avec_defauts';
  static const creerCommercanteAvecBoutique = 'creer_commercante_avec_boutique';
  static const enregistrerEchecConnexion = 'enregistrer_echec_connexion';
  static const enregistrerPaiement = 'enregistrer_paiement';
  static const enregistrerPaiementAbonnement =
      'enregistrer_paiement_abonnement';
  static const enregistrerVente = 'enregistrer_vente';
  static const fermerSessionCaisse = 'fermer_session_caisse';
  static const genererDocumentCommande = 'generer_document_commande';
  static const inviterMembre = 'inviter_membre';
  static const joindreJustificatifCommande = 'joindre_justificatif_commande';
  static const limiterRequete = 'limiter_requete';
  static const mesPermissions = 'mes_permissions';
  static const ouvrirSessionCaisse = 'ouvrir_session_caisse';
  static const passerCommandeEnLigne = 'passer_commande_en_ligne';
  static const recevoirStock = 'recevoir_stock';
  static const reinitialiserTentativesConnexion =
      'reinitialiser_tentatives_connexion';
  static const reserverPlageNumeros = 'reserver_plage_numeros';
  static const resoudreBoutique = 'resoudre_boutique';
  static const suivreCommande = 'suivre_commande';
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

/// Table `ajustements_stock`.
class AjustementsStockRow {
  const AjustementsStockRow({
    required this.id,
    required this.boutiqueId,
    required this.type_,
    this.motifId,
    this.note,
    this.utilisateurId,
    required this.creeLe,
  });

  final String id;
  final String boutiqueId;
  final TypeAjustementStock type_;
  final String? motifId;
  final String? note;
  final String? utilisateurId;
  final DateTime creeLe;

  factory AjustementsStockRow.depuisJson(Map<String, dynamic> json) =>
      AjustementsStockRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        type_: TypeAjustementStock.depuisJson(json['type'] as String),
        motifId: json['motif_id'] == null ? null : json['motif_id'] as String,
        note: json['note'] == null ? null : json['note'] as String,
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'type': type_.valeur,
    'motif_id': motifId,
    'note': note,
    'utilisateur_id': utilisateurId,
    'cree_le': creeLe.toIso8601String(),
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

/// Table `bannieres_site`.
class BannieresSiteRow {
  const BannieresSiteRow({
    required this.id,
    required this.boutiqueId,
    required this.imageUrl,
    this.titreAr,
    this.titreFr,
    this.lien,
    required this.ordre,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String imageUrl;
  final String? titreAr;
  final String? titreFr;
  final String? lien;
  final int ordre;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory BannieresSiteRow.depuisJson(Map<String, dynamic> json) =>
      BannieresSiteRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        imageUrl: json['image_url'] as String,
        titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
        titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
        lien: json['lien'] == null ? null : json['lien'] as String,
        ordre: json['ordre'] as int,
        actif: json['actif'] as bool,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'image_url': imageUrl,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'lien': lien,
    'ordre': ordre,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `bannieres_site_publiques`.
class BannieresSitePubliquesRow {
  const BannieresSitePubliquesRow({
    this.id,
    this.boutiqueId,
    this.imageUrl,
    this.titreAr,
    this.titreFr,
    this.lien,
    this.ordre,
  });

  final String? id;
  final String? boutiqueId;
  final String? imageUrl;
  final String? titreAr;
  final String? titreFr;
  final String? lien;
  final int? ordre;

  factory BannieresSitePubliquesRow.depuisJson(Map<String, dynamic> json) =>
      BannieresSitePubliquesRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        imageUrl: json['image_url'] == null
            ? null
            : json['image_url'] as String,
        titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
        titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
        lien: json['lien'] == null ? null : json['lien'] as String,
        ordre: json['ordre'] == null ? null : json['ordre'] as int,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'image_url': imageUrl,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'lien': lien,
    'ordre': ordre,
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

/// Table `categories`.
class CategoriesRow {
  const CategoriesRow({
    required this.id,
    required this.boutiqueId,
    this.parentId,
    this.nomAr,
    this.nomFr,
    this.imageUrl,
    required this.ordre,
    required this.visibleEnLigne,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? parentId;
  final String? nomAr;
  final String? nomFr;
  final String? imageUrl;
  final int ordre;
  final bool visibleEnLigne;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory CategoriesRow.depuisJson(Map<String, dynamic> json) => CategoriesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    parentId: json['parent_id'] == null ? null : json['parent_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    imageUrl: json['image_url'] == null ? null : json['image_url'] as String,
    ordre: json['ordre'] as int,
    visibleEnLigne: json['visible_en_ligne'] as bool,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'parent_id': parentId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'image_url': imageUrl,
    'ordre': ordre,
    'visible_en_ligne': visibleEnLigne,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `categories_depenses`.
class CategoriesDepensesRow {
  const CategoriesDepensesRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory CategoriesDepensesRow.depuisJson(Map<String, dynamic> json) =>
      CategoriesDepensesRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        actif: json['actif'] as bool,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `categories_publiques`.
class CategoriesPubliquesRow {
  const CategoriesPubliquesRow({
    this.id,
    this.boutiqueId,
    this.parentId,
    this.nomAr,
    this.nomFr,
    this.imageUrl,
    this.ordre,
  });

  final String? id;
  final String? boutiqueId;
  final String? parentId;
  final String? nomAr;
  final String? nomFr;
  final String? imageUrl;
  final int? ordre;

  factory CategoriesPubliquesRow.depuisJson(
    Map<String, dynamic> json,
  ) => CategoriesPubliquesRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    parentId: json['parent_id'] == null ? null : json['parent_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    imageUrl: json['image_url'] == null ? null : json['image_url'] as String,
    ordre: json['ordre'] == null ? null : json['ordre'] as int,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'parent_id': parentId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'image_url': imageUrl,
    'ordre': ordre,
  };
}

/// Table `clients`.
class ClientsRow {
  const ClientsRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    this.telephone,
    this.whatsapp,
    this.adresse,
    this.ville,
    this.plafondCredit,
    required this.solde,
    this.notes,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
    this.supprimeLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String? telephone;
  final String? whatsapp;
  final String? adresse;
  final String? ville;
  final double? plafondCredit;
  final double solde;
  final String? notes;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;
  final DateTime? supprimeLe;

  factory ClientsRow.depuisJson(Map<String, dynamic> json) => ClientsRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    telephone: json['telephone'] == null ? null : json['telephone'] as String,
    whatsapp: json['whatsapp'] == null ? null : json['whatsapp'] as String,
    adresse: json['adresse'] == null ? null : json['adresse'] as String,
    ville: json['ville'] == null ? null : json['ville'] as String,
    plafondCredit: json['plafond_credit'] == null
        ? null
        : (json['plafond_credit'] as num).toDouble(),
    solde: (json['solde'] as num).toDouble(),
    notes: json['notes'] == null ? null : json['notes'] as String,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
    supprimeLe: json['supprime_le'] == null
        ? null
        : DateTime.parse(json['supprime_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'telephone': telephone,
    'whatsapp': whatsapp,
    'adresse': adresse,
    'ville': ville,
    'plafond_credit': plafondCredit,
    'solde': solde,
    'notes': notes,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
    'supprime_le': supprimeLe?.toIso8601String(),
  };
}

/// Table `commandes`.
class CommandesRow {
  const CommandesRow({
    required this.id,
    required this.boutiqueId,
    required this.numero,
    required this.canal,
    this.clientId,
    this.compteClientId,
    required this.nomClient,
    required this.telephone,
    this.adresse,
    this.ville,
    this.zoneId,
    required this.modeLivraison,
    required this.fraisLivraison,
    required this.statut,
    required this.statutPaiement,
    required this.modePaiement,
    required this.sousTotal,
    required this.total,
    required this.montantPaye,
    this.notes,
    this.justificatifUrl,
    this.documentId,
    this.livreurNom,
    this.livreurTelephone,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String numero;
  final CanalVente canal;
  final String? clientId;
  final String? compteClientId;
  final String nomClient;
  final String telephone;
  final String? adresse;
  final String? ville;
  final String? zoneId;
  final ModeLivraison modeLivraison;
  final double fraisLivraison;
  final StatutCommande statut;
  final StatutPaiementCommande statutPaiement;
  final ModePaiementCommande modePaiement;
  final double sousTotal;
  final double total;
  final double montantPaye;
  final String? notes;
  final String? justificatifUrl;
  final String? documentId;
  final String? livreurNom;
  final String? livreurTelephone;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory CommandesRow.depuisJson(Map<String, dynamic> json) => CommandesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    numero: json['numero'] as String,
    canal: CanalVente.depuisJson(json['canal'] as String),
    clientId: json['client_id'] == null ? null : json['client_id'] as String,
    compteClientId: json['compte_client_id'] == null
        ? null
        : json['compte_client_id'] as String,
    nomClient: json['nom_client'] as String,
    telephone: json['telephone'] as String,
    adresse: json['adresse'] == null ? null : json['adresse'] as String,
    ville: json['ville'] == null ? null : json['ville'] as String,
    zoneId: json['zone_id'] == null ? null : json['zone_id'] as String,
    modeLivraison: ModeLivraison.depuisJson(json['mode_livraison'] as String),
    fraisLivraison: (json['frais_livraison'] as num).toDouble(),
    statut: StatutCommande.depuisJson(json['statut'] as String),
    statutPaiement: StatutPaiementCommande.depuisJson(
      json['statut_paiement'] as String,
    ),
    modePaiement: ModePaiementCommande.depuisJson(
      json['mode_paiement'] as String,
    ),
    sousTotal: (json['sous_total'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    montantPaye: (json['montant_paye'] as num).toDouble(),
    notes: json['notes'] == null ? null : json['notes'] as String,
    justificatifUrl: json['justificatif_url'] == null
        ? null
        : json['justificatif_url'] as String,
    documentId: json['document_id'] == null
        ? null
        : json['document_id'] as String,
    livreurNom: json['livreur_nom'] == null
        ? null
        : json['livreur_nom'] as String,
    livreurTelephone: json['livreur_telephone'] == null
        ? null
        : json['livreur_telephone'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'numero': numero,
    'canal': canal.valeur,
    'client_id': clientId,
    'compte_client_id': compteClientId,
    'nom_client': nomClient,
    'telephone': telephone,
    'adresse': adresse,
    'ville': ville,
    'zone_id': zoneId,
    'mode_livraison': modeLivraison.valeur,
    'frais_livraison': fraisLivraison,
    'statut': statut.valeur,
    'statut_paiement': statutPaiement.valeur,
    'mode_paiement': modePaiement.valeur,
    'sous_total': sousTotal,
    'total': total,
    'montant_paye': montantPaye,
    'notes': notes,
    'justificatif_url': justificatifUrl,
    'document_id': documentId,
    'livreur_nom': livreurNom,
    'livreur_telephone': livreurTelephone,
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

/// Table `comptes_clientes_site`.
class ComptesClientesSiteRow {
  const ComptesClientesSiteRow({
    required this.id,
    required this.boutiqueId,
    required this.utilisateurId,
    required this.nom,
    required this.telephone,
    required this.adresses,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String utilisateurId;
  final String nom;
  final String telephone;
  final dynamic adresses;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ComptesClientesSiteRow.depuisJson(Map<String, dynamic> json) =>
      ComptesClientesSiteRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        utilisateurId: json['utilisateur_id'] as String,
        nom: json['nom'] as String,
        telephone: json['telephone'] as String,
        adresses: json['adresses'],
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'utilisateur_id': utilisateurId,
    'nom': nom,
    'telephone': telephone,
    'adresses': adresses,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `couleurs`.
class CouleursRow {
  const CouleursRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    required this.codeHex,
    required this.ordre,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String codeHex;
  final int ordre;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory CouleursRow.depuisJson(Map<String, dynamic> json) => CouleursRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    codeHex: json['code_hex'] as String,
    ordre: json['ordre'] as int,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'code_hex': codeHex,
    'ordre': ordre,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `couleurs_publiques`.
class CouleursPubliquesRow {
  const CouleursPubliquesRow({
    this.id,
    this.boutiqueId,
    this.nomAr,
    this.nomFr,
    this.codeHex,
    this.ordre,
  });

  final String? id;
  final String? boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String? codeHex;
  final int? ordre;

  factory CouleursPubliquesRow.depuisJson(Map<String, dynamic> json) =>
      CouleursPubliquesRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        codeHex: json['code_hex'] == null ? null : json['code_hex'] as String,
        ordre: json['ordre'] == null ? null : json['ordre'] as int,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'code_hex': codeHex,
    'ordre': ordre,
  };
}

/// Table `depenses`.
class DepensesRow {
  const DepensesRow({
    required this.id,
    required this.boutiqueId,
    this.categorieId,
    required this.montant,
    required this.dateDepense,
    this.motif,
    this.modePaiementId,
    this.utilisateurId,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? categorieId;
  final double montant;
  final DateTime dateDepense;
  final String? motif;
  final String? modePaiementId;
  final String? utilisateurId;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory DepensesRow.depuisJson(Map<String, dynamic> json) => DepensesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    categorieId: json['categorie_id'] == null
        ? null
        : json['categorie_id'] as String,
    montant: (json['montant'] as num).toDouble(),
    dateDepense: DateTime.parse(json['date_depense'] as String),
    motif: json['motif'] == null ? null : json['motif'] as String,
    modePaiementId: json['mode_paiement_id'] == null
        ? null
        : json['mode_paiement_id'] as String,
    utilisateurId: json['utilisateur_id'] == null
        ? null
        : json['utilisateur_id'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'categorie_id': categorieId,
    'montant': montant,
    'date_depense': dateDepense.toIso8601String(),
    'motif': motif,
    'mode_paiement_id': modePaiementId,
    'utilisateur_id': utilisateurId,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `documents_vente`.
class DocumentsVenteRow {
  const DocumentsVenteRow({
    required this.id,
    required this.boutiqueId,
    required this.type_,
    required this.numero,
    required this.statut,
    this.clientId,
    this.documentSourceId,
    this.sessionCaisseId,
    required this.canal,
    required this.dateEmission,
    this.dateEcheance,
    required this.sousTotal,
    required this.remise,
    required this.total,
    required this.paye,
    this.reste,
    this.notes,
    required this.entete,
    this.utilisateurId,
    this.annuleLe,
    this.motifAnnulation,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final TypeDocumentVente type_;
  final String numero;
  final StatutDocumentVente statut;
  final String? clientId;
  final String? documentSourceId;
  final String? sessionCaisseId;
  final CanalVente canal;
  final DateTime dateEmission;
  final DateTime? dateEcheance;
  final double sousTotal;
  final double remise;
  final double total;
  final double paye;
  final double? reste;
  final String? notes;
  final dynamic entete;
  final String? utilisateurId;
  final DateTime? annuleLe;
  final String? motifAnnulation;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory DocumentsVenteRow.depuisJson(Map<String, dynamic> json) =>
      DocumentsVenteRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        type_: TypeDocumentVente.depuisJson(json['type'] as String),
        numero: json['numero'] as String,
        statut: StatutDocumentVente.depuisJson(json['statut'] as String),
        clientId: json['client_id'] == null
            ? null
            : json['client_id'] as String,
        documentSourceId: json['document_source_id'] == null
            ? null
            : json['document_source_id'] as String,
        sessionCaisseId: json['session_caisse_id'] == null
            ? null
            : json['session_caisse_id'] as String,
        canal: CanalVente.depuisJson(json['canal'] as String),
        dateEmission: DateTime.parse(json['date_emission'] as String),
        dateEcheance: json['date_echeance'] == null
            ? null
            : DateTime.parse(json['date_echeance'] as String),
        sousTotal: (json['sous_total'] as num).toDouble(),
        remise: (json['remise'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        paye: (json['paye'] as num).toDouble(),
        reste: json['reste'] == null ? null : (json['reste'] as num).toDouble(),
        notes: json['notes'] == null ? null : json['notes'] as String,
        entete: json['entete'],
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        annuleLe: json['annule_le'] == null
            ? null
            : DateTime.parse(json['annule_le'] as String),
        motifAnnulation: json['motif_annulation'] == null
            ? null
            : json['motif_annulation'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'type': type_.valeur,
    'numero': numero,
    'statut': statut.valeur,
    'client_id': clientId,
    'document_source_id': documentSourceId,
    'session_caisse_id': sessionCaisseId,
    'canal': canal.valeur,
    'date_emission': dateEmission.toIso8601String(),
    'date_echeance': dateEcheance?.toIso8601String(),
    'sous_total': sousTotal,
    'remise': remise,
    'total': total,
    'paye': paye,
    'reste': reste,
    'notes': notes,
    'entete': entete,
    'utilisateur_id': utilisateurId,
    'annule_le': annuleLe?.toIso8601String(),
    'motif_annulation': motifAnnulation,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `domaines_boutique`.
class DomainesBoutiqueRow {
  const DomainesBoutiqueRow({
    required this.id,
    required this.boutiqueId,
    required this.sousDomaine,
    this.domainePersonnalise,
    required this.statutDns,
    required this.statutSsl,
    required this.principal,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String sousDomaine;
  final String? domainePersonnalise;
  final StatutDomaine statutDns;
  final StatutDomaine statutSsl;
  final bool principal;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory DomainesBoutiqueRow.depuisJson(Map<String, dynamic> json) =>
      DomainesBoutiqueRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        sousDomaine: json['sous_domaine'] as String,
        domainePersonnalise: json['domaine_personnalise'] == null
            ? null
            : json['domaine_personnalise'] as String,
        statutDns: StatutDomaine.depuisJson(json['statut_dns'] as String),
        statutSsl: StatutDomaine.depuisJson(json['statut_ssl'] as String),
        principal: json['principal'] as bool,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'sous_domaine': sousDomaine,
    'domaine_personnalise': domainePersonnalise,
    'statut_dns': statutDns.valeur,
    'statut_ssl': statutSsl.valeur,
    'principal': principal,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `fournisseurs`.
class FournisseursRow {
  const FournisseursRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    this.telephone,
    this.adresse,
    required this.solde,
    this.notes,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
    this.supprimeLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String? telephone;
  final String? adresse;
  final double solde;
  final String? notes;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;
  final DateTime? supprimeLe;

  factory FournisseursRow.depuisJson(Map<String, dynamic> json) =>
      FournisseursRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        telephone: json['telephone'] == null
            ? null
            : json['telephone'] as String,
        adresse: json['adresse'] == null ? null : json['adresse'] as String,
        solde: (json['solde'] as num).toDouble(),
        notes: json['notes'] == null ? null : json['notes'] as String,
        creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
        supprimeLe: json['supprime_le'] == null
            ? null
            : DateTime.parse(json['supprime_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'telephone': telephone,
    'adresse': adresse,
    'solde': solde,
    'notes': notes,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
    'supprime_le': supprimeLe?.toIso8601String(),
  };
}

/// Table `historique_statuts_commande`.
class HistoriqueStatutsCommandeRow {
  const HistoriqueStatutsCommandeRow({
    required this.id,
    required this.boutiqueId,
    required this.commandeId,
    required this.statut,
    this.utilisateurId,
    required this.dateStatut,
    this.note,
  });

  final String id;
  final String boutiqueId;
  final String commandeId;
  final StatutCommande statut;
  final String? utilisateurId;
  final DateTime dateStatut;
  final String? note;

  factory HistoriqueStatutsCommandeRow.depuisJson(Map<String, dynamic> json) =>
      HistoriqueStatutsCommandeRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        commandeId: json['commande_id'] as String,
        statut: StatutCommande.depuisJson(json['statut'] as String),
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        dateStatut: DateTime.parse(json['date_statut'] as String),
        note: json['note'] == null ? null : json['note'] as String,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'commande_id': commandeId,
    'statut': statut.valeur,
    'utilisateur_id': utilisateurId,
    'date_statut': dateStatut.toIso8601String(),
    'note': note,
  };
}

/// Table `images_produit`.
class ImagesProduitRow {
  const ImagesProduitRow({
    required this.id,
    required this.boutiqueId,
    required this.produitId,
    this.varianteId,
    required this.url,
    required this.principale,
    required this.ordre,
    required this.creeLe,
  });

  final String id;
  final String boutiqueId;
  final String produitId;
  final String? varianteId;
  final String url;
  final bool principale;
  final int ordre;
  final DateTime creeLe;

  factory ImagesProduitRow.depuisJson(Map<String, dynamic> json) =>
      ImagesProduitRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        produitId: json['produit_id'] as String,
        varianteId: json['variante_id'] == null
            ? null
            : json['variante_id'] as String,
        url: json['url'] as String,
        principale: json['principale'] as bool,
        ordre: json['ordre'] as int,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'produit_id': produitId,
    'variante_id': varianteId,
    'url': url,
    'principale': principale,
    'ordre': ordre,
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Vue `images_publiques`.
class ImagesPubliquesRow {
  const ImagesPubliquesRow({
    this.id,
    this.boutiqueId,
    this.produitId,
    this.varianteId,
    this.url,
    this.principale,
    this.ordre,
  });

  final String? id;
  final String? boutiqueId;
  final String? produitId;
  final String? varianteId;
  final String? url;
  final bool? principale;
  final int? ordre;

  factory ImagesPubliquesRow.depuisJson(
    Map<String, dynamic> json,
  ) => ImagesPubliquesRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    produitId: json['produit_id'] == null ? null : json['produit_id'] as String,
    varianteId: json['variante_id'] == null
        ? null
        : json['variante_id'] as String,
    url: json['url'] == null ? null : json['url'] as String,
    principale: json['principale'] == null ? null : json['principale'] as bool,
    ordre: json['ordre'] == null ? null : json['ordre'] as int,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'produit_id': produitId,
    'variante_id': varianteId,
    'url': url,
    'principale': principale,
    'ordre': ordre,
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

/// Table `lignes_ajustement_stock`.
class LignesAjustementStockRow {
  const LignesAjustementStockRow({
    required this.id,
    required this.boutiqueId,
    required this.ajustementId,
    required this.varianteId,
    required this.quantiteSysteme,
    this.quantiteComptee,
    required this.ecart,
  });

  final String id;
  final String boutiqueId;
  final String ajustementId;
  final String varianteId;
  final double quantiteSysteme;
  final double? quantiteComptee;
  final double ecart;

  factory LignesAjustementStockRow.depuisJson(Map<String, dynamic> json) =>
      LignesAjustementStockRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        ajustementId: json['ajustement_id'] as String,
        varianteId: json['variante_id'] as String,
        quantiteSysteme: (json['quantite_systeme'] as num).toDouble(),
        quantiteComptee: json['quantite_comptee'] == null
            ? null
            : (json['quantite_comptee'] as num).toDouble(),
        ecart: (json['ecart'] as num).toDouble(),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'ajustement_id': ajustementId,
    'variante_id': varianteId,
    'quantite_systeme': quantiteSysteme,
    'quantite_comptee': quantiteComptee,
    'ecart': ecart,
  };
}

/// Table `lignes_commande`.
class LignesCommandeRow {
  const LignesCommandeRow({
    required this.id,
    required this.boutiqueId,
    required this.commandeId,
    required this.varianteId,
    required this.quantite,
    required this.prixUnitaire,
    this.libelleAr,
    this.libelleFr,
    required this.total,
  });

  final String id;
  final String boutiqueId;
  final String commandeId;
  final String varianteId;
  final double quantite;
  final double prixUnitaire;
  final String? libelleAr;
  final String? libelleFr;
  final double total;

  factory LignesCommandeRow.depuisJson(
    Map<String, dynamic> json,
  ) => LignesCommandeRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    commandeId: json['commande_id'] as String,
    varianteId: json['variante_id'] as String,
    quantite: (json['quantite'] as num).toDouble(),
    prixUnitaire: (json['prix_unitaire'] as num).toDouble(),
    libelleAr: json['libelle_ar'] == null ? null : json['libelle_ar'] as String,
    libelleFr: json['libelle_fr'] == null ? null : json['libelle_fr'] as String,
    total: (json['total'] as num).toDouble(),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'commande_id': commandeId,
    'variante_id': varianteId,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'libelle_ar': libelleAr,
    'libelle_fr': libelleFr,
    'total': total,
  };
}

/// Table `lignes_document_vente`.
class LignesDocumentVenteRow {
  const LignesDocumentVenteRow({
    required this.id,
    required this.boutiqueId,
    required this.documentId,
    this.varianteId,
    this.libelleAr,
    this.libelleFr,
    required this.quantite,
    required this.prixUnitaire,
    required this.remise,
    required this.coutUnitaire,
    required this.total,
    required this.ordre,
  });

  final String id;
  final String boutiqueId;
  final String documentId;
  final String? varianteId;
  final String? libelleAr;
  final String? libelleFr;
  final double quantite;
  final double prixUnitaire;
  final double remise;
  final double coutUnitaire;
  final double total;
  final int ordre;

  factory LignesDocumentVenteRow.depuisJson(
    Map<String, dynamic> json,
  ) => LignesDocumentVenteRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    documentId: json['document_id'] as String,
    varianteId: json['variante_id'] == null
        ? null
        : json['variante_id'] as String,
    libelleAr: json['libelle_ar'] == null ? null : json['libelle_ar'] as String,
    libelleFr: json['libelle_fr'] == null ? null : json['libelle_fr'] as String,
    quantite: (json['quantite'] as num).toDouble(),
    prixUnitaire: (json['prix_unitaire'] as num).toDouble(),
    remise: (json['remise'] as num).toDouble(),
    coutUnitaire: (json['cout_unitaire'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    ordre: json['ordre'] as int,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'document_id': documentId,
    'variante_id': varianteId,
    'libelle_ar': libelleAr,
    'libelle_fr': libelleFr,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'remise': remise,
    'cout_unitaire': coutUnitaire,
    'total': total,
    'ordre': ordre,
  };
}

/// Vue `lignes_document_vente_vue`.
class LignesDocumentVenteVueRow {
  const LignesDocumentVenteVueRow({
    this.id,
    this.boutiqueId,
    this.documentId,
    this.varianteId,
    this.libelleAr,
    this.libelleFr,
    this.quantite,
    this.prixUnitaire,
    this.remise,
    this.total,
    this.ordre,
    this.coutUnitaire,
  });

  final String? id;
  final String? boutiqueId;
  final String? documentId;
  final String? varianteId;
  final String? libelleAr;
  final String? libelleFr;
  final double? quantite;
  final double? prixUnitaire;
  final double? remise;
  final double? total;
  final int? ordre;
  final double? coutUnitaire;

  factory LignesDocumentVenteVueRow.depuisJson(
    Map<String, dynamic> json,
  ) => LignesDocumentVenteVueRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    documentId: json['document_id'] == null
        ? null
        : json['document_id'] as String,
    varianteId: json['variante_id'] == null
        ? null
        : json['variante_id'] as String,
    libelleAr: json['libelle_ar'] == null ? null : json['libelle_ar'] as String,
    libelleFr: json['libelle_fr'] == null ? null : json['libelle_fr'] as String,
    quantite: json['quantite'] == null
        ? null
        : (json['quantite'] as num).toDouble(),
    prixUnitaire: json['prix_unitaire'] == null
        ? null
        : (json['prix_unitaire'] as num).toDouble(),
    remise: json['remise'] == null ? null : (json['remise'] as num).toDouble(),
    total: json['total'] == null ? null : (json['total'] as num).toDouble(),
    ordre: json['ordre'] == null ? null : json['ordre'] as int,
    coutUnitaire: json['cout_unitaire'] == null
        ? null
        : (json['cout_unitaire'] as num).toDouble(),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'document_id': documentId,
    'variante_id': varianteId,
    'libelle_ar': libelleAr,
    'libelle_fr': libelleFr,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'remise': remise,
    'total': total,
    'ordre': ordre,
    'cout_unitaire': coutUnitaire,
  };
}

/// Table `lignes_reception_stock`.
class LignesReceptionStockRow {
  const LignesReceptionStockRow({
    required this.id,
    required this.boutiqueId,
    required this.receptionId,
    required this.varianteId,
    required this.quantite,
    required this.coutUnitaire,
    this.dateExpiration,
    this.prixVente,
  });

  final String id;
  final String boutiqueId;
  final String receptionId;
  final String varianteId;
  final double quantite;
  final double coutUnitaire;
  final DateTime? dateExpiration;
  final double? prixVente;

  factory LignesReceptionStockRow.depuisJson(Map<String, dynamic> json) =>
      LignesReceptionStockRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        receptionId: json['reception_id'] as String,
        varianteId: json['variante_id'] as String,
        quantite: (json['quantite'] as num).toDouble(),
        coutUnitaire: (json['cout_unitaire'] as num).toDouble(),
        dateExpiration: json['date_expiration'] == null
            ? null
            : DateTime.parse(json['date_expiration'] as String),
        prixVente: json['prix_vente'] == null
            ? null
            : (json['prix_vente'] as num).toDouble(),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'reception_id': receptionId,
    'variante_id': varianteId,
    'quantite': quantite,
    'cout_unitaire': coutUnitaire,
    'date_expiration': dateExpiration?.toIso8601String(),
    'prix_vente': prixVente,
  };
}

/// Vue `lignes_reception_stock_vue`.
class LignesReceptionStockVueRow {
  const LignesReceptionStockVueRow({
    this.id,
    this.boutiqueId,
    this.receptionId,
    this.varianteId,
    this.quantite,
    this.dateExpiration,
    this.prixVente,
    this.coutUnitaire,
  });

  final String? id;
  final String? boutiqueId;
  final String? receptionId;
  final String? varianteId;
  final double? quantite;
  final DateTime? dateExpiration;
  final double? prixVente;
  final double? coutUnitaire;

  factory LignesReceptionStockVueRow.depuisJson(Map<String, dynamic> json) =>
      LignesReceptionStockVueRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        receptionId: json['reception_id'] == null
            ? null
            : json['reception_id'] as String,
        varianteId: json['variante_id'] == null
            ? null
            : json['variante_id'] as String,
        quantite: json['quantite'] == null
            ? null
            : (json['quantite'] as num).toDouble(),
        dateExpiration: json['date_expiration'] == null
            ? null
            : DateTime.parse(json['date_expiration'] as String),
        prixVente: json['prix_vente'] == null
            ? null
            : (json['prix_vente'] as num).toDouble(),
        coutUnitaire: json['cout_unitaire'] == null
            ? null
            : (json['cout_unitaire'] as num).toDouble(),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'reception_id': receptionId,
    'variante_id': varianteId,
    'quantite': quantite,
    'date_expiration': dateExpiration?.toIso8601String(),
    'prix_vente': prixVente,
    'cout_unitaire': coutUnitaire,
  };
}

/// Table `limites_debit`.
class LimitesDebitRow {
  const LimitesDebitRow({
    required this.cle,
    required this.compteur,
    required this.fenetreDebut,
  });

  final String cle;
  final int compteur;
  final DateTime fenetreDebut;

  factory LimitesDebitRow.depuisJson(Map<String, dynamic> json) =>
      LimitesDebitRow(
        cle: json['cle'] as String,
        compteur: json['compteur'] as int,
        fenetreDebut: DateTime.parse(json['fenetre_debut'] as String),
      );

  Map<String, dynamic> versJson() => {
    'cle': cle,
    'compteur': compteur,
    'fenetre_debut': fenetreDebut.toIso8601String(),
  };
}

/// Table `lots_stock`.
class LotsStockRow {
  const LotsStockRow({
    required this.id,
    required this.boutiqueId,
    required this.varianteId,
    required this.numeroLot,
    required this.recuLe,
    required this.quantiteInitiale,
    required this.quantiteRestante,
    required this.coutUnitaire,
    this.dateExpiration,
    this.ligneReceptionId,
    this.fournisseurId,
    required this.decouvert,
  });

  final String id;
  final String boutiqueId;
  final String varianteId;
  final String numeroLot;
  final DateTime recuLe;
  final double quantiteInitiale;
  final double quantiteRestante;
  final double coutUnitaire;
  final DateTime? dateExpiration;
  final String? ligneReceptionId;
  final String? fournisseurId;
  final bool decouvert;

  factory LotsStockRow.depuisJson(Map<String, dynamic> json) => LotsStockRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    varianteId: json['variante_id'] as String,
    numeroLot: json['numero_lot'] as String,
    recuLe: DateTime.parse(json['recu_le'] as String),
    quantiteInitiale: (json['quantite_initiale'] as num).toDouble(),
    quantiteRestante: (json['quantite_restante'] as num).toDouble(),
    coutUnitaire: (json['cout_unitaire'] as num).toDouble(),
    dateExpiration: json['date_expiration'] == null
        ? null
        : DateTime.parse(json['date_expiration'] as String),
    ligneReceptionId: json['ligne_reception_id'] == null
        ? null
        : json['ligne_reception_id'] as String,
    fournisseurId: json['fournisseur_id'] == null
        ? null
        : json['fournisseur_id'] as String,
    decouvert: json['decouvert'] as bool,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'variante_id': varianteId,
    'numero_lot': numeroLot,
    'recu_le': recuLe.toIso8601String(),
    'quantite_initiale': quantiteInitiale,
    'quantite_restante': quantiteRestante,
    'cout_unitaire': coutUnitaire,
    'date_expiration': dateExpiration?.toIso8601String(),
    'ligne_reception_id': ligneReceptionId,
    'fournisseur_id': fournisseurId,
    'decouvert': decouvert,
  };
}

/// Vue `lots_stock_vue`.
class LotsStockVueRow {
  const LotsStockVueRow({
    this.id,
    this.boutiqueId,
    this.varianteId,
    this.numeroLot,
    this.recuLe,
    this.quantiteInitiale,
    this.quantiteRestante,
    this.coutUnitaire,
    this.dateExpiration,
    this.ligneReceptionId,
    this.fournisseurId,
    this.decouvert,
  });

  final String? id;
  final String? boutiqueId;
  final String? varianteId;
  final String? numeroLot;
  final DateTime? recuLe;
  final double? quantiteInitiale;
  final double? quantiteRestante;
  final double? coutUnitaire;
  final DateTime? dateExpiration;
  final String? ligneReceptionId;
  final String? fournisseurId;
  final bool? decouvert;

  factory LotsStockVueRow.depuisJson(Map<String, dynamic> json) =>
      LotsStockVueRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        varianteId: json['variante_id'] == null
            ? null
            : json['variante_id'] as String,
        numeroLot: json['numero_lot'] == null
            ? null
            : json['numero_lot'] as String,
        recuLe: json['recu_le'] == null
            ? null
            : DateTime.parse(json['recu_le'] as String),
        quantiteInitiale: json['quantite_initiale'] == null
            ? null
            : (json['quantite_initiale'] as num).toDouble(),
        quantiteRestante: json['quantite_restante'] == null
            ? null
            : (json['quantite_restante'] as num).toDouble(),
        coutUnitaire: json['cout_unitaire'] == null
            ? null
            : (json['cout_unitaire'] as num).toDouble(),
        dateExpiration: json['date_expiration'] == null
            ? null
            : DateTime.parse(json['date_expiration'] as String),
        ligneReceptionId: json['ligne_reception_id'] == null
            ? null
            : json['ligne_reception_id'] as String,
        fournisseurId: json['fournisseur_id'] == null
            ? null
            : json['fournisseur_id'] as String,
        decouvert: json['decouvert'] == null ? null : json['decouvert'] as bool,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'variante_id': varianteId,
    'numero_lot': numeroLot,
    'recu_le': recuLe?.toIso8601String(),
    'quantite_initiale': quantiteInitiale,
    'quantite_restante': quantiteRestante,
    'cout_unitaire': coutUnitaire,
    'date_expiration': dateExpiration?.toIso8601String(),
    'ligne_reception_id': ligneReceptionId,
    'fournisseur_id': fournisseurId,
    'decouvert': decouvert,
  };
}

/// Table `marques`.
class MarquesRow {
  const MarquesRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    this.logoUrl,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String? logoUrl;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory MarquesRow.depuisJson(Map<String, dynamic> json) => MarquesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    logoUrl: json['logo_url'] == null ? null : json['logo_url'] as String,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'logo_url': logoUrl,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
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

/// Table `modeles`.
class ModelesRow {
  const ModelesRow({
    required this.id,
    required this.boutiqueId,
    this.categorieId,
    this.nomAr,
    this.nomFr,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? categorieId;
  final String? nomAr;
  final String? nomFr;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ModelesRow.depuisJson(Map<String, dynamic> json) => ModelesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    categorieId: json['categorie_id'] == null
        ? null
        : json['categorie_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'categorie_id': categorieId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `modeles_publics`.
class ModelesPublicsRow {
  const ModelesPublicsRow({
    this.id,
    this.boutiqueId,
    this.categorieId,
    this.nomAr,
    this.nomFr,
  });

  final String? id;
  final String? boutiqueId;
  final String? categorieId;
  final String? nomAr;
  final String? nomFr;

  factory ModelesPublicsRow.depuisJson(Map<String, dynamic> json) =>
      ModelesPublicsRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        categorieId: json['categorie_id'] == null
            ? null
            : json['categorie_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'categorie_id': categorieId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
  };
}

/// Table `modes_paiement`.
class ModesPaiementRow {
  const ModesPaiementRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    required this.type_,
    this.icone,
    required this.parDefaut,
    required this.actif,
    required this.ordre,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final TypeModePaiement type_;
  final String? icone;
  final bool parDefaut;
  final bool actif;
  final int ordre;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ModesPaiementRow.depuisJson(Map<String, dynamic> json) =>
      ModesPaiementRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        type_: TypeModePaiement.depuisJson(json['type'] as String),
        icone: json['icone'] == null ? null : json['icone'] as String,
        parDefaut: json['par_defaut'] as bool,
        actif: json['actif'] as bool,
        ordre: json['ordre'] as int,
        creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'type': type_.valeur,
    'icone': icone,
    'par_defaut': parDefaut,
    'actif': actif,
    'ordre': ordre,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `motifs_mouvement`.
class MotifsMouvementRow {
  const MotifsMouvementRow({
    required this.id,
    required this.boutiqueId,
    this.code,
    this.nomAr,
    this.nomFr,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? code;
  final String? nomAr;
  final String? nomFr;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory MotifsMouvementRow.depuisJson(Map<String, dynamic> json) =>
      MotifsMouvementRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        code: json['code'] == null ? null : json['code'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        actif: json['actif'] as bool,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'code': code,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `mouvements_stock`.
class MouvementsStockRow {
  const MouvementsStockRow({
    required this.id,
    required this.boutiqueId,
    required this.varianteId,
    this.lotId,
    required this.type_,
    required this.quantite,
    this.coutUnitaire,
    this.sourceType,
    this.sourceId,
    this.motifId,
    this.note,
    this.utilisateurId,
    required this.creeLe,
  });

  final String id;
  final String boutiqueId;
  final String varianteId;
  final String? lotId;
  final TypeMouvementStock type_;
  final double quantite;
  final double? coutUnitaire;
  final String? sourceType;
  final String? sourceId;
  final String? motifId;
  final String? note;
  final String? utilisateurId;
  final DateTime creeLe;

  factory MouvementsStockRow.depuisJson(Map<String, dynamic> json) =>
      MouvementsStockRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        varianteId: json['variante_id'] as String,
        lotId: json['lot_id'] == null ? null : json['lot_id'] as String,
        type_: TypeMouvementStock.depuisJson(json['type'] as String),
        quantite: (json['quantite'] as num).toDouble(),
        coutUnitaire: json['cout_unitaire'] == null
            ? null
            : (json['cout_unitaire'] as num).toDouble(),
        sourceType: json['source_type'] == null
            ? null
            : json['source_type'] as String,
        sourceId: json['source_id'] == null
            ? null
            : json['source_id'] as String,
        motifId: json['motif_id'] == null ? null : json['motif_id'] as String,
        note: json['note'] == null ? null : json['note'] as String,
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'variante_id': varianteId,
    'lot_id': lotId,
    'type': type_.valeur,
    'quantite': quantite,
    'cout_unitaire': coutUnitaire,
    'source_type': sourceType,
    'source_id': sourceId,
    'motif_id': motifId,
    'note': note,
    'utilisateur_id': utilisateurId,
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Vue `mouvements_stock_vue`.
class MouvementsStockVueRow {
  const MouvementsStockVueRow({
    this.id,
    this.boutiqueId,
    this.varianteId,
    this.lotId,
    this.type_,
    this.quantite,
    this.coutUnitaire,
    this.sourceType,
    this.sourceId,
    this.motifId,
    this.note,
    this.utilisateurId,
    this.creeLe,
  });

  final String? id;
  final String? boutiqueId;
  final String? varianteId;
  final String? lotId;
  final TypeMouvementStock? type_;
  final double? quantite;
  final double? coutUnitaire;
  final String? sourceType;
  final String? sourceId;
  final String? motifId;
  final String? note;
  final String? utilisateurId;
  final DateTime? creeLe;

  factory MouvementsStockVueRow.depuisJson(Map<String, dynamic> json) =>
      MouvementsStockVueRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        varianteId: json['variante_id'] == null
            ? null
            : json['variante_id'] as String,
        lotId: json['lot_id'] == null ? null : json['lot_id'] as String,
        type_: json['type'] == null
            ? null
            : TypeMouvementStock.depuisJson(json['type'] as String),
        quantite: json['quantite'] == null
            ? null
            : (json['quantite'] as num).toDouble(),
        coutUnitaire: json['cout_unitaire'] == null
            ? null
            : (json['cout_unitaire'] as num).toDouble(),
        sourceType: json['source_type'] == null
            ? null
            : json['source_type'] as String,
        sourceId: json['source_id'] == null
            ? null
            : json['source_id'] as String,
        motifId: json['motif_id'] == null ? null : json['motif_id'] as String,
        note: json['note'] == null ? null : json['note'] as String,
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        creeLe: json['cree_le'] == null
            ? null
            : DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'variante_id': varianteId,
    'lot_id': lotId,
    'type': type_?.valeur,
    'quantite': quantite,
    'cout_unitaire': coutUnitaire,
    'source_type': sourceType,
    'source_id': sourceId,
    'motif_id': motifId,
    'note': note,
    'utilisateur_id': utilisateurId,
    'cree_le': creeLe?.toIso8601String(),
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

/// Table `pages_site`.
class PagesSiteRow {
  const PagesSiteRow({
    required this.id,
    required this.boutiqueId,
    required this.slug,
    this.titreAr,
    this.titreFr,
    this.contenuAr,
    this.contenuFr,
    required this.ordre,
    required this.visible,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String slug;
  final String? titreAr;
  final String? titreFr;
  final String? contenuAr;
  final String? contenuFr;
  final int ordre;
  final bool visible;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory PagesSiteRow.depuisJson(Map<String, dynamic> json) => PagesSiteRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    slug: json['slug'] as String,
    titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
    titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
    contenuAr: json['contenu_ar'] == null ? null : json['contenu_ar'] as String,
    contenuFr: json['contenu_fr'] == null ? null : json['contenu_fr'] as String,
    ordre: json['ordre'] as int,
    visible: json['visible'] as bool,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'slug': slug,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'contenu_ar': contenuAr,
    'contenu_fr': contenuFr,
    'ordre': ordre,
    'visible': visible,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `pages_site_publiques`.
class PagesSitePubliquesRow {
  const PagesSitePubliquesRow({
    this.id,
    this.boutiqueId,
    this.slug,
    this.titreAr,
    this.titreFr,
    this.contenuAr,
    this.contenuFr,
    this.ordre,
  });

  final String? id;
  final String? boutiqueId;
  final String? slug;
  final String? titreAr;
  final String? titreFr;
  final String? contenuAr;
  final String? contenuFr;
  final int? ordre;

  factory PagesSitePubliquesRow.depuisJson(
    Map<String, dynamic> json,
  ) => PagesSitePubliquesRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    slug: json['slug'] == null ? null : json['slug'] as String,
    titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
    titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
    contenuAr: json['contenu_ar'] == null ? null : json['contenu_ar'] as String,
    contenuFr: json['contenu_fr'] == null ? null : json['contenu_fr'] as String,
    ordre: json['ordre'] == null ? null : json['ordre'] as int,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'slug': slug,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'contenu_ar': contenuAr,
    'contenu_fr': contenuFr,
    'ordre': ordre,
  };
}

/// Table `paiements`.
class PaiementsRow {
  const PaiementsRow({
    required this.id,
    required this.boutiqueId,
    this.documentId,
    this.clientId,
    required this.modePaiementId,
    required this.montant,
    required this.payeLe,
    this.sessionCaisseId,
    this.reference,
    this.justificatifUrl,
    this.utilisateurId,
    required this.creeLe,
  });

  final String id;
  final String boutiqueId;
  final String? documentId;
  final String? clientId;
  final String modePaiementId;
  final double montant;
  final DateTime payeLe;
  final String? sessionCaisseId;
  final String? reference;
  final String? justificatifUrl;
  final String? utilisateurId;
  final DateTime creeLe;

  factory PaiementsRow.depuisJson(Map<String, dynamic> json) => PaiementsRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    documentId: json['document_id'] == null
        ? null
        : json['document_id'] as String,
    clientId: json['client_id'] == null ? null : json['client_id'] as String,
    modePaiementId: json['mode_paiement_id'] as String,
    montant: (json['montant'] as num).toDouble(),
    payeLe: DateTime.parse(json['paye_le'] as String),
    sessionCaisseId: json['session_caisse_id'] == null
        ? null
        : json['session_caisse_id'] as String,
    reference: json['reference'] == null ? null : json['reference'] as String,
    justificatifUrl: json['justificatif_url'] == null
        ? null
        : json['justificatif_url'] as String,
    utilisateurId: json['utilisateur_id'] == null
        ? null
        : json['utilisateur_id'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'document_id': documentId,
    'client_id': clientId,
    'mode_paiement_id': modePaiementId,
    'montant': montant,
    'paye_le': payeLe.toIso8601String(),
    'session_caisse_id': sessionCaisseId,
    'reference': reference,
    'justificatif_url': justificatifUrl,
    'utilisateur_id': utilisateurId,
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

/// Vue `parametres_boutique_publics`.
class ParametresBoutiquePublicsRow {
  const ParametresBoutiquePublicsRow({
    this.boutiqueId,
    this.slug,
    this.nomAr,
    this.nomFr,
    this.logoUrl,
    this.devise,
    this.langueParDefaut,
    this.telephone,
    this.whatsapp,
    this.adresse,
    this.ville,
    this.themeId,
    this.themeCode,
    this.configTheme,
    this.faviconUrl,
    this.liensSociaux,
    this.referencement,
    this.infosPaiement,
    this.horaires,
    this.commandeMinimale,
    this.livraisonActive,
    this.retraitBoutiqueActif,
    this.paiementLivraisonActif,
    this.mobileMoneyActif,
    this.afficherStock,
    this.masquerEpuises,
    this.messageConfirmationAr,
    this.messageConfirmationFr,
    this.languesActivees,
  });

  final String? boutiqueId;
  final String? slug;
  final String? nomAr;
  final String? nomFr;
  final String? logoUrl;
  final String? devise;
  final String? langueParDefaut;
  final String? telephone;
  final String? whatsapp;
  final String? adresse;
  final String? ville;
  final String? themeId;
  final String? themeCode;
  final dynamic configTheme;
  final String? faviconUrl;
  final dynamic liensSociaux;
  final dynamic referencement;
  final dynamic infosPaiement;
  final dynamic horaires;
  final double? commandeMinimale;
  final bool? livraisonActive;
  final bool? retraitBoutiqueActif;
  final bool? paiementLivraisonActif;
  final bool? mobileMoneyActif;
  final bool? afficherStock;
  final bool? masquerEpuises;
  final String? messageConfirmationAr;
  final String? messageConfirmationFr;
  final List<String>? languesActivees;

  factory ParametresBoutiquePublicsRow.depuisJson(
    Map<String, dynamic> json,
  ) => ParametresBoutiquePublicsRow(
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    slug: json['slug'] == null ? null : json['slug'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    logoUrl: json['logo_url'] == null ? null : json['logo_url'] as String,
    devise: json['devise'] == null ? null : json['devise'] as String,
    langueParDefaut: json['langue_par_defaut'] == null
        ? null
        : json['langue_par_defaut'] as String,
    telephone: json['telephone'] == null ? null : json['telephone'] as String,
    whatsapp: json['whatsapp'] == null ? null : json['whatsapp'] as String,
    adresse: json['adresse'] == null ? null : json['adresse'] as String,
    ville: json['ville'] == null ? null : json['ville'] as String,
    themeId: json['theme_id'] == null ? null : json['theme_id'] as String,
    themeCode: json['theme_code'] == null ? null : json['theme_code'] as String,
    configTheme: json['config_theme'] == null ? null : json['config_theme'],
    faviconUrl: json['favicon_url'] == null
        ? null
        : json['favicon_url'] as String,
    liensSociaux: json['liens_sociaux'] == null ? null : json['liens_sociaux'],
    referencement: json['referencement'] == null ? null : json['referencement'],
    infosPaiement: json['infos_paiement'] == null
        ? null
        : json['infos_paiement'],
    horaires: json['horaires'] == null ? null : json['horaires'],
    commandeMinimale: json['commande_minimale'] == null
        ? null
        : (json['commande_minimale'] as num).toDouble(),
    livraisonActive: json['livraison_active'] == null
        ? null
        : json['livraison_active'] as bool,
    retraitBoutiqueActif: json['retrait_boutique_actif'] == null
        ? null
        : json['retrait_boutique_actif'] as bool,
    paiementLivraisonActif: json['paiement_livraison_actif'] == null
        ? null
        : json['paiement_livraison_actif'] as bool,
    mobileMoneyActif: json['mobile_money_actif'] == null
        ? null
        : json['mobile_money_actif'] as bool,
    afficherStock: json['afficher_stock'] == null
        ? null
        : json['afficher_stock'] as bool,
    masquerEpuises: json['masquer_epuises'] == null
        ? null
        : json['masquer_epuises'] as bool,
    messageConfirmationAr: json['message_confirmation_ar'] == null
        ? null
        : json['message_confirmation_ar'] as String,
    messageConfirmationFr: json['message_confirmation_fr'] == null
        ? null
        : json['message_confirmation_fr'] as String,
    languesActivees: json['langues_activees'] == null
        ? null
        : (json['langues_activees'] as List).map((e) => e as String).toList(),
  );

  Map<String, dynamic> versJson() => {
    'boutique_id': boutiqueId,
    'slug': slug,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'logo_url': logoUrl,
    'devise': devise,
    'langue_par_defaut': langueParDefaut,
    'telephone': telephone,
    'whatsapp': whatsapp,
    'adresse': adresse,
    'ville': ville,
    'theme_id': themeId,
    'theme_code': themeCode,
    'config_theme': configTheme,
    'favicon_url': faviconUrl,
    'liens_sociaux': liensSociaux,
    'referencement': referencement,
    'infos_paiement': infosPaiement,
    'horaires': horaires,
    'commande_minimale': commandeMinimale,
    'livraison_active': livraisonActive,
    'retrait_boutique_actif': retraitBoutiqueActif,
    'paiement_livraison_actif': paiementLivraisonActif,
    'mobile_money_actif': mobileMoneyActif,
    'afficher_stock': afficherStock,
    'masquer_epuises': masquerEpuises,
    'message_confirmation_ar': messageConfirmationAr,
    'message_confirmation_fr': messageConfirmationFr,
    'langues_activees': languesActivees?.map((e) => e).toList(),
  };
}

/// Table `parametres_site`.
class ParametresSiteRow {
  const ParametresSiteRow({
    required this.boutiqueId,
    this.themeId,
    required this.configTheme,
    this.configBrouillon,
    this.logoUrl,
    this.faviconUrl,
    required this.liensSociaux,
    required this.referencement,
    required this.infosPaiement,
    required this.horaires,
    required this.commandeMinimale,
    required this.livraisonActive,
    required this.retraitBoutiqueActif,
    required this.paiementLivraisonActif,
    required this.mobileMoneyActif,
    required this.afficherStock,
    required this.masquerEpuises,
    this.messageConfirmationAr,
    this.messageConfirmationFr,
    required this.languesActivees,
    required this.publie,
    required this.creeLe,
    required this.modifieLe,
  });

  final String boutiqueId;
  final String? themeId;
  final dynamic configTheme;
  final dynamic configBrouillon;
  final String? logoUrl;
  final String? faviconUrl;
  final dynamic liensSociaux;
  final dynamic referencement;
  final dynamic infosPaiement;
  final dynamic horaires;
  final double commandeMinimale;
  final bool livraisonActive;
  final bool retraitBoutiqueActif;
  final bool paiementLivraisonActif;
  final bool mobileMoneyActif;
  final bool afficherStock;
  final bool masquerEpuises;
  final String? messageConfirmationAr;
  final String? messageConfirmationFr;
  final List<String> languesActivees;
  final bool publie;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ParametresSiteRow.depuisJson(Map<String, dynamic> json) =>
      ParametresSiteRow(
        boutiqueId: json['boutique_id'] as String,
        themeId: json['theme_id'] == null ? null : json['theme_id'] as String,
        configTheme: json['config_theme'],
        configBrouillon: json['config_brouillon'] == null
            ? null
            : json['config_brouillon'],
        logoUrl: json['logo_url'] == null ? null : json['logo_url'] as String,
        faviconUrl: json['favicon_url'] == null
            ? null
            : json['favicon_url'] as String,
        liensSociaux: json['liens_sociaux'],
        referencement: json['referencement'],
        infosPaiement: json['infos_paiement'],
        horaires: json['horaires'],
        commandeMinimale: (json['commande_minimale'] as num).toDouble(),
        livraisonActive: json['livraison_active'] as bool,
        retraitBoutiqueActif: json['retrait_boutique_actif'] as bool,
        paiementLivraisonActif: json['paiement_livraison_actif'] as bool,
        mobileMoneyActif: json['mobile_money_actif'] as bool,
        afficherStock: json['afficher_stock'] as bool,
        masquerEpuises: json['masquer_epuises'] as bool,
        messageConfirmationAr: json['message_confirmation_ar'] == null
            ? null
            : json['message_confirmation_ar'] as String,
        messageConfirmationFr: json['message_confirmation_fr'] == null
            ? null
            : json['message_confirmation_fr'] as String,
        languesActivees: (json['langues_activees'] as List)
            .map((e) => e as String)
            .toList(),
        publie: json['publie'] as bool,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'boutique_id': boutiqueId,
    'theme_id': themeId,
    'config_theme': configTheme,
    'config_brouillon': configBrouillon,
    'logo_url': logoUrl,
    'favicon_url': faviconUrl,
    'liens_sociaux': liensSociaux,
    'referencement': referencement,
    'infos_paiement': infosPaiement,
    'horaires': horaires,
    'commande_minimale': commandeMinimale,
    'livraison_active': livraisonActive,
    'retrait_boutique_actif': retraitBoutiqueActif,
    'paiement_livraison_actif': paiementLivraisonActif,
    'mobile_money_actif': mobileMoneyActif,
    'afficher_stock': afficherStock,
    'masquer_epuises': masquerEpuises,
    'message_confirmation_ar': messageConfirmationAr,
    'message_confirmation_fr': messageConfirmationFr,
    'langues_activees': languesActivees.map((e) => e).toList(),
    'publie': publie,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
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

/// Table `plages_numeros`.
class PlagesNumerosRow {
  const PlagesNumerosRow({
    required this.id,
    required this.boutiqueId,
    required this.typeDocument,
    required this.annee,
    required this.appareilId,
    required this.debut,
    required this.fin,
    required this.creeLe,
  });

  final String id;
  final String boutiqueId;
  final String typeDocument;
  final int annee;
  final String appareilId;
  final int debut;
  final int fin;
  final DateTime creeLe;

  factory PlagesNumerosRow.depuisJson(Map<String, dynamic> json) =>
      PlagesNumerosRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        typeDocument: json['type_document'] as String,
        annee: json['annee'] as int,
        appareilId: json['appareil_id'] as String,
        debut: json['debut'] as int,
        fin: json['fin'] as int,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'type_document': typeDocument,
    'annee': annee,
    'appareil_id': appareilId,
    'debut': debut,
    'fin': fin,
    'cree_le': creeLe.toIso8601String(),
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

/// Table `produits`.
class ProduitsRow {
  const ProduitsRow({
    required this.id,
    required this.boutiqueId,
    this.categorieId,
    this.marqueId,
    this.uniteId,
    this.nomAr,
    this.nomFr,
    this.descriptionAr,
    this.descriptionFr,
    this.slug,
    required this.statut,
    required this.visibleEnLigne,
    required this.epingle,
    this.ordreEpinglage,
    required this.ordre,
    required this.etiquettes,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
    this.supprimeLe,
  });

  final String id;
  final String boutiqueId;
  final String? categorieId;
  final String? marqueId;
  final String? uniteId;
  final String? nomAr;
  final String? nomFr;
  final String? descriptionAr;
  final String? descriptionFr;
  final String? slug;
  final StatutProduit statut;
  final bool visibleEnLigne;
  final bool epingle;
  final int? ordreEpinglage;
  final int ordre;
  final List<String> etiquettes;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;
  final DateTime? supprimeLe;

  factory ProduitsRow.depuisJson(Map<String, dynamic> json) => ProduitsRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    categorieId: json['categorie_id'] == null
        ? null
        : json['categorie_id'] as String,
    marqueId: json['marque_id'] == null ? null : json['marque_id'] as String,
    uniteId: json['unite_id'] == null ? null : json['unite_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    descriptionAr: json['description_ar'] == null
        ? null
        : json['description_ar'] as String,
    descriptionFr: json['description_fr'] == null
        ? null
        : json['description_fr'] as String,
    slug: json['slug'] == null ? null : json['slug'] as String,
    statut: StatutProduit.depuisJson(json['statut'] as String),
    visibleEnLigne: json['visible_en_ligne'] as bool,
    epingle: json['epingle'] as bool,
    ordreEpinglage: json['ordre_epinglage'] == null
        ? null
        : json['ordre_epinglage'] as int,
    ordre: json['ordre'] as int,
    etiquettes: (json['etiquettes'] as List).map((e) => e as String).toList(),
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
    supprimeLe: json['supprime_le'] == null
        ? null
        : DateTime.parse(json['supprime_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'categorie_id': categorieId,
    'marque_id': marqueId,
    'unite_id': uniteId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'description_ar': descriptionAr,
    'description_fr': descriptionFr,
    'slug': slug,
    'statut': statut.valeur,
    'visible_en_ligne': visibleEnLigne,
    'epingle': epingle,
    'ordre_epinglage': ordreEpinglage,
    'ordre': ordre,
    'etiquettes': etiquettes.map((e) => e).toList(),
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
    'supprime_le': supprimeLe?.toIso8601String(),
  };
}

/// Vue `produits_publics`.
class ProduitsPublicsRow {
  const ProduitsPublicsRow({
    this.id,
    this.boutiqueId,
    this.slug,
    this.nomAr,
    this.nomFr,
    this.descriptionAr,
    this.descriptionFr,
    this.categorieId,
    this.categorieOrdre,
    this.marqueId,
    this.epingle,
    this.ordreEpinglage,
    this.ordre,
    this.etiquettes,
    this.creeLe,
    this.prixMin,
    this.prixNormalMin,
    this.enPromo,
    this.epuise,
    this.imageUrl,
  });

  final String? id;
  final String? boutiqueId;
  final String? slug;
  final String? nomAr;
  final String? nomFr;
  final String? descriptionAr;
  final String? descriptionFr;
  final String? categorieId;
  final int? categorieOrdre;
  final String? marqueId;
  final bool? epingle;
  final int? ordreEpinglage;
  final int? ordre;
  final List<String>? etiquettes;
  final DateTime? creeLe;
  final double? prixMin;
  final double? prixNormalMin;
  final bool? enPromo;
  final bool? epuise;
  final String? imageUrl;

  factory ProduitsPublicsRow.depuisJson(
    Map<String, dynamic> json,
  ) => ProduitsPublicsRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    slug: json['slug'] == null ? null : json['slug'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    descriptionAr: json['description_ar'] == null
        ? null
        : json['description_ar'] as String,
    descriptionFr: json['description_fr'] == null
        ? null
        : json['description_fr'] as String,
    categorieId: json['categorie_id'] == null
        ? null
        : json['categorie_id'] as String,
    categorieOrdre: json['categorie_ordre'] == null
        ? null
        : json['categorie_ordre'] as int,
    marqueId: json['marque_id'] == null ? null : json['marque_id'] as String,
    epingle: json['epingle'] == null ? null : json['epingle'] as bool,
    ordreEpinglage: json['ordre_epinglage'] == null
        ? null
        : json['ordre_epinglage'] as int,
    ordre: json['ordre'] == null ? null : json['ordre'] as int,
    etiquettes: json['etiquettes'] == null
        ? null
        : (json['etiquettes'] as List).map((e) => e as String).toList(),
    creeLe: json['cree_le'] == null
        ? null
        : DateTime.parse(json['cree_le'] as String),
    prixMin: json['prix_min'] == null
        ? null
        : (json['prix_min'] as num).toDouble(),
    prixNormalMin: json['prix_normal_min'] == null
        ? null
        : (json['prix_normal_min'] as num).toDouble(),
    enPromo: json['en_promo'] == null ? null : json['en_promo'] as bool,
    epuise: json['epuise'] == null ? null : json['epuise'] as bool,
    imageUrl: json['image_url'] == null ? null : json['image_url'] as String,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'slug': slug,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'description_ar': descriptionAr,
    'description_fr': descriptionFr,
    'categorie_id': categorieId,
    'categorie_ordre': categorieOrdre,
    'marque_id': marqueId,
    'epingle': epingle,
    'ordre_epinglage': ordreEpinglage,
    'ordre': ordre,
    'etiquettes': etiquettes?.map((e) => e).toList(),
    'cree_le': creeLe?.toIso8601String(),
    'prix_min': prixMin,
    'prix_normal_min': prixNormalMin,
    'en_promo': enPromo,
    'epuise': epuise,
    'image_url': imageUrl,
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

/// Table `receptions_stock`.
class ReceptionsStockRow {
  const ReceptionsStockRow({
    required this.id,
    required this.boutiqueId,
    this.fournisseurId,
    this.transfertId,
    required this.dateReception,
    this.reference,
    required this.total,
    required this.montantPaye,
    this.notes,
    this.utilisateurId,
    required this.creeLe,
  });

  final String id;
  final String boutiqueId;
  final String? fournisseurId;
  final String? transfertId;
  final DateTime dateReception;
  final String? reference;
  final double total;
  final double montantPaye;
  final String? notes;
  final String? utilisateurId;
  final DateTime creeLe;

  factory ReceptionsStockRow.depuisJson(Map<String, dynamic> json) =>
      ReceptionsStockRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        fournisseurId: json['fournisseur_id'] == null
            ? null
            : json['fournisseur_id'] as String,
        transfertId: json['transfert_id'] == null
            ? null
            : json['transfert_id'] as String,
        dateReception: DateTime.parse(json['date_reception'] as String),
        reference: json['reference'] == null
            ? null
            : json['reference'] as String,
        total: (json['total'] as num).toDouble(),
        montantPaye: (json['montant_paye'] as num).toDouble(),
        notes: json['notes'] == null ? null : json['notes'] as String,
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        creeLe: DateTime.parse(json['cree_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'fournisseur_id': fournisseurId,
    'transfert_id': transfertId,
    'date_reception': dateReception.toIso8601String(),
    'reference': reference,
    'total': total,
    'montant_paye': montantPaye,
    'notes': notes,
    'utilisateur_id': utilisateurId,
    'cree_le': creeLe.toIso8601String(),
  };
}

/// Vue `receptions_stock_vue`.
class ReceptionsStockVueRow {
  const ReceptionsStockVueRow({
    this.id,
    this.boutiqueId,
    this.fournisseurId,
    this.transfertId,
    this.dateReception,
    this.reference,
    this.notes,
    this.utilisateurId,
    this.creeLe,
    this.total,
    this.montantPaye,
  });

  final String? id;
  final String? boutiqueId;
  final String? fournisseurId;
  final String? transfertId;
  final DateTime? dateReception;
  final String? reference;
  final String? notes;
  final String? utilisateurId;
  final DateTime? creeLe;
  final double? total;
  final double? montantPaye;

  factory ReceptionsStockVueRow.depuisJson(Map<String, dynamic> json) =>
      ReceptionsStockVueRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        fournisseurId: json['fournisseur_id'] == null
            ? null
            : json['fournisseur_id'] as String,
        transfertId: json['transfert_id'] == null
            ? null
            : json['transfert_id'] as String,
        dateReception: json['date_reception'] == null
            ? null
            : DateTime.parse(json['date_reception'] as String),
        reference: json['reference'] == null
            ? null
            : json['reference'] as String,
        notes: json['notes'] == null ? null : json['notes'] as String,
        utilisateurId: json['utilisateur_id'] == null
            ? null
            : json['utilisateur_id'] as String,
        creeLe: json['cree_le'] == null
            ? null
            : DateTime.parse(json['cree_le'] as String),
        total: json['total'] == null ? null : (json['total'] as num).toDouble(),
        montantPaye: json['montant_paye'] == null
            ? null
            : (json['montant_paye'] as num).toDouble(),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'fournisseur_id': fournisseurId,
    'transfert_id': transfertId,
    'date_reception': dateReception?.toIso8601String(),
    'reference': reference,
    'notes': notes,
    'utilisateur_id': utilisateurId,
    'cree_le': creeLe?.toIso8601String(),
    'total': total,
    'montant_paye': montantPaye,
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

/// Table `sections_site`.
class SectionsSiteRow {
  const SectionsSiteRow({
    required this.id,
    required this.boutiqueId,
    required this.type_,
    this.titreAr,
    this.titreFr,
    this.contenuAr,
    this.contenuFr,
    required this.config,
    required this.ordre,
    required this.visible,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String type_;
  final String? titreAr;
  final String? titreFr;
  final String? contenuAr;
  final String? contenuFr;
  final dynamic config;
  final int ordre;
  final bool visible;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory SectionsSiteRow.depuisJson(
    Map<String, dynamic> json,
  ) => SectionsSiteRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    type_: json['type'] as String,
    titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
    titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
    contenuAr: json['contenu_ar'] == null ? null : json['contenu_ar'] as String,
    contenuFr: json['contenu_fr'] == null ? null : json['contenu_fr'] as String,
    config: json['config'],
    ordre: json['ordre'] as int,
    visible: json['visible'] as bool,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'type': type_,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'contenu_ar': contenuAr,
    'contenu_fr': contenuFr,
    'config': config,
    'ordre': ordre,
    'visible': visible,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `sections_site_publiques`.
class SectionsSitePubliquesRow {
  const SectionsSitePubliquesRow({
    this.id,
    this.boutiqueId,
    this.type_,
    this.titreAr,
    this.titreFr,
    this.contenuAr,
    this.contenuFr,
    this.config,
    this.ordre,
  });

  final String? id;
  final String? boutiqueId;
  final String? type_;
  final String? titreAr;
  final String? titreFr;
  final String? contenuAr;
  final String? contenuFr;
  final dynamic config;
  final int? ordre;

  factory SectionsSitePubliquesRow.depuisJson(
    Map<String, dynamic> json,
  ) => SectionsSitePubliquesRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    type_: json['type'] == null ? null : json['type'] as String,
    titreAr: json['titre_ar'] == null ? null : json['titre_ar'] as String,
    titreFr: json['titre_fr'] == null ? null : json['titre_fr'] as String,
    contenuAr: json['contenu_ar'] == null ? null : json['contenu_ar'] as String,
    contenuFr: json['contenu_fr'] == null ? null : json['contenu_fr'] as String,
    config: json['config'] == null ? null : json['config'],
    ordre: json['ordre'] == null ? null : json['ordre'] as int,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'type': type_,
    'titre_ar': titreAr,
    'titre_fr': titreFr,
    'contenu_ar': contenuAr,
    'contenu_fr': contenuFr,
    'config': config,
    'ordre': ordre,
  };
}

/// Table `sequences_documents`.
class SequencesDocumentsRow {
  const SequencesDocumentsRow({
    required this.boutiqueId,
    required this.typeDocument,
    required this.annee,
    required this.prochainNumero,
    this.prefixe,
  });

  final String boutiqueId;
  final String typeDocument;
  final int annee;
  final int prochainNumero;
  final String? prefixe;

  factory SequencesDocumentsRow.depuisJson(Map<String, dynamic> json) =>
      SequencesDocumentsRow(
        boutiqueId: json['boutique_id'] as String,
        typeDocument: json['type_document'] as String,
        annee: json['annee'] as int,
        prochainNumero: json['prochain_numero'] as int,
        prefixe: json['prefixe'] == null ? null : json['prefixe'] as String,
      );

  Map<String, dynamic> versJson() => {
    'boutique_id': boutiqueId,
    'type_document': typeDocument,
    'annee': annee,
    'prochain_numero': prochainNumero,
    'prefixe': prefixe,
  };
}

/// Table `sessions_caisse`.
class SessionsCaisseRow {
  const SessionsCaisseRow({
    required this.id,
    required this.boutiqueId,
    required this.utilisateurId,
    this.appareilId,
    required this.ouverteLe,
    this.fermeeLe,
    required this.fondInitial,
    this.attendu,
    this.compte,
    this.ecart,
    this.notes,
  });

  final String id;
  final String boutiqueId;
  final String utilisateurId;
  final String? appareilId;
  final DateTime ouverteLe;
  final DateTime? fermeeLe;
  final double fondInitial;
  final double? attendu;
  final double? compte;
  final double? ecart;
  final String? notes;

  factory SessionsCaisseRow.depuisJson(Map<String, dynamic> json) =>
      SessionsCaisseRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        utilisateurId: json['utilisateur_id'] as String,
        appareilId: json['appareil_id'] == null
            ? null
            : json['appareil_id'] as String,
        ouverteLe: DateTime.parse(json['ouverte_le'] as String),
        fermeeLe: json['fermee_le'] == null
            ? null
            : DateTime.parse(json['fermee_le'] as String),
        fondInitial: (json['fond_initial'] as num).toDouble(),
        attendu: json['attendu'] == null
            ? null
            : (json['attendu'] as num).toDouble(),
        compte: json['compte'] == null
            ? null
            : (json['compte'] as num).toDouble(),
        ecart: json['ecart'] == null ? null : (json['ecart'] as num).toDouble(),
        notes: json['notes'] == null ? null : json['notes'] as String,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'utilisateur_id': utilisateurId,
    'appareil_id': appareilId,
    'ouverte_le': ouverteLe.toIso8601String(),
    'fermee_le': fermeeLe?.toIso8601String(),
    'fond_initial': fondInitial,
    'attendu': attendu,
    'compte': compte,
    'ecart': ecart,
    'notes': notes,
  };
}

/// Vue `stock_variante`.
class StockVarianteRow {
  const StockVarianteRow({
    this.varianteId,
    this.boutiqueId,
    this.enStock,
    this.reserve,
    this.disponible,
  });

  final String? varianteId;
  final String? boutiqueId;
  final double? enStock;
  final double? reserve;
  final double? disponible;

  factory StockVarianteRow.depuisJson(Map<String, dynamic> json) =>
      StockVarianteRow(
        varianteId: json['variante_id'] == null
            ? null
            : json['variante_id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        enStock: json['en_stock'] == null
            ? null
            : (json['en_stock'] as num).toDouble(),
        reserve: json['reserve'] == null
            ? null
            : (json['reserve'] as num).toDouble(),
        disponible: json['disponible'] == null
            ? null
            : (json['disponible'] as num).toDouble(),
      );

  Map<String, dynamic> versJson() => {
    'variante_id': varianteId,
    'boutique_id': boutiqueId,
    'en_stock': enStock,
    'reserve': reserve,
    'disponible': disponible,
  };
}

/// Table `tailles`.
class TaillesRow {
  const TaillesRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    required this.type_,
    required this.ordre,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String type_;
  final int ordre;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory TaillesRow.depuisJson(Map<String, dynamic> json) => TaillesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    type_: json['type'] as String,
    ordre: json['ordre'] as int,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'type': type_,
    'ordre': ordre,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
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

/// Table `themes_site`.
class ThemesSiteRow {
  const ThemesSiteRow({
    required this.id,
    required this.code,
    required this.nomAr,
    required this.nomFr,
    this.apercuUrl,
    required this.schemaConfig,
    required this.planMinimum,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String code;
  final String nomAr;
  final String nomFr;
  final String? apercuUrl;
  final dynamic schemaConfig;
  final int planMinimum;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ThemesSiteRow.depuisJson(Map<String, dynamic> json) => ThemesSiteRow(
    id: json['id'] as String,
    code: json['code'] as String,
    nomAr: json['nom_ar'] as String,
    nomFr: json['nom_fr'] as String,
    apercuUrl: json['apercu_url'] == null ? null : json['apercu_url'] as String,
    schemaConfig: json['schema_config'],
    planMinimum: json['plan_minimum'] as int,
    actif: json['actif'] as bool,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'code': code,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'apercu_url': apercuUrl,
    'schema_config': schemaConfig,
    'plan_minimum': planMinimum,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `unites`.
class UnitesRow {
  const UnitesRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    this.abreviation,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final String? abreviation;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory UnitesRow.depuisJson(Map<String, dynamic> json) => UnitesRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
    nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
    abreviation: json['abreviation'] == null
        ? null
        : json['abreviation'] as String,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'abreviation': abreviation,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Table `variantes_produit`.
class VariantesProduitRow {
  const VariantesProduitRow({
    required this.id,
    required this.boutiqueId,
    required this.produitId,
    this.modeleId,
    this.couleurId,
    this.tailleId,
    this.sku,
    this.codeBarres,
    required this.prixVente,
    this.prixGros,
    this.prixPromo,
    this.promoDebut,
    this.promoFin,
    required this.stockMinimum,
    this.imageUrl,
    required this.actif,
    this.creePar,
    required this.creeLe,
    required this.modifieLe,
    this.supprimeLe,
  });

  final String id;
  final String boutiqueId;
  final String produitId;
  final String? modeleId;
  final String? couleurId;
  final String? tailleId;
  final String? sku;
  final String? codeBarres;
  final double prixVente;
  final double? prixGros;
  final double? prixPromo;
  final DateTime? promoDebut;
  final DateTime? promoFin;
  final double stockMinimum;
  final String? imageUrl;
  final bool actif;
  final String? creePar;
  final DateTime creeLe;
  final DateTime modifieLe;
  final DateTime? supprimeLe;

  factory VariantesProduitRow.depuisJson(
    Map<String, dynamic> json,
  ) => VariantesProduitRow(
    id: json['id'] as String,
    boutiqueId: json['boutique_id'] as String,
    produitId: json['produit_id'] as String,
    modeleId: json['modele_id'] == null ? null : json['modele_id'] as String,
    couleurId: json['couleur_id'] == null ? null : json['couleur_id'] as String,
    tailleId: json['taille_id'] == null ? null : json['taille_id'] as String,
    sku: json['sku'] == null ? null : json['sku'] as String,
    codeBarres: json['code_barres'] == null
        ? null
        : json['code_barres'] as String,
    prixVente: (json['prix_vente'] as num).toDouble(),
    prixGros: json['prix_gros'] == null
        ? null
        : (json['prix_gros'] as num).toDouble(),
    prixPromo: json['prix_promo'] == null
        ? null
        : (json['prix_promo'] as num).toDouble(),
    promoDebut: json['promo_debut'] == null
        ? null
        : DateTime.parse(json['promo_debut'] as String),
    promoFin: json['promo_fin'] == null
        ? null
        : DateTime.parse(json['promo_fin'] as String),
    stockMinimum: (json['stock_minimum'] as num).toDouble(),
    imageUrl: json['image_url'] == null ? null : json['image_url'] as String,
    actif: json['actif'] as bool,
    creePar: json['cree_par'] == null ? null : json['cree_par'] as String,
    creeLe: DateTime.parse(json['cree_le'] as String),
    modifieLe: DateTime.parse(json['modifie_le'] as String),
    supprimeLe: json['supprime_le'] == null
        ? null
        : DateTime.parse(json['supprime_le'] as String),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'produit_id': produitId,
    'modele_id': modeleId,
    'couleur_id': couleurId,
    'taille_id': tailleId,
    'sku': sku,
    'code_barres': codeBarres,
    'prix_vente': prixVente,
    'prix_gros': prixGros,
    'prix_promo': prixPromo,
    'promo_debut': promoDebut?.toIso8601String(),
    'promo_fin': promoFin?.toIso8601String(),
    'stock_minimum': stockMinimum,
    'image_url': imageUrl,
    'actif': actif,
    'cree_par': creePar,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
    'supprime_le': supprimeLe?.toIso8601String(),
  };
}

/// Vue `variantes_publiques`.
class VariantesPubliquesRow {
  const VariantesPubliquesRow({
    this.id,
    this.boutiqueId,
    this.produitId,
    this.modeleId,
    this.couleurId,
    this.tailleId,
    this.prix,
    this.prixNormal,
    this.enPromo,
    this.imageUrl,
    this.modeleNomAr,
    this.modeleNomFr,
    this.couleurNomAr,
    this.couleurNomFr,
    this.couleurHex,
    this.tailleNomAr,
    this.tailleNomFr,
    this.epuisee,
    this.stockVisible,
  });

  final String? id;
  final String? boutiqueId;
  final String? produitId;
  final String? modeleId;
  final String? couleurId;
  final String? tailleId;
  final double? prix;
  final double? prixNormal;
  final bool? enPromo;
  final String? imageUrl;
  final String? modeleNomAr;
  final String? modeleNomFr;
  final String? couleurNomAr;
  final String? couleurNomFr;
  final String? couleurHex;
  final String? tailleNomAr;
  final String? tailleNomFr;
  final bool? epuisee;
  final double? stockVisible;

  factory VariantesPubliquesRow.depuisJson(
    Map<String, dynamic> json,
  ) => VariantesPubliquesRow(
    id: json['id'] == null ? null : json['id'] as String,
    boutiqueId: json['boutique_id'] == null
        ? null
        : json['boutique_id'] as String,
    produitId: json['produit_id'] == null ? null : json['produit_id'] as String,
    modeleId: json['modele_id'] == null ? null : json['modele_id'] as String,
    couleurId: json['couleur_id'] == null ? null : json['couleur_id'] as String,
    tailleId: json['taille_id'] == null ? null : json['taille_id'] as String,
    prix: json['prix'] == null ? null : (json['prix'] as num).toDouble(),
    prixNormal: json['prix_normal'] == null
        ? null
        : (json['prix_normal'] as num).toDouble(),
    enPromo: json['en_promo'] == null ? null : json['en_promo'] as bool,
    imageUrl: json['image_url'] == null ? null : json['image_url'] as String,
    modeleNomAr: json['modele_nom_ar'] == null
        ? null
        : json['modele_nom_ar'] as String,
    modeleNomFr: json['modele_nom_fr'] == null
        ? null
        : json['modele_nom_fr'] as String,
    couleurNomAr: json['couleur_nom_ar'] == null
        ? null
        : json['couleur_nom_ar'] as String,
    couleurNomFr: json['couleur_nom_fr'] == null
        ? null
        : json['couleur_nom_fr'] as String,
    couleurHex: json['couleur_hex'] == null
        ? null
        : json['couleur_hex'] as String,
    tailleNomAr: json['taille_nom_ar'] == null
        ? null
        : json['taille_nom_ar'] as String,
    tailleNomFr: json['taille_nom_fr'] == null
        ? null
        : json['taille_nom_fr'] as String,
    epuisee: json['epuisee'] == null ? null : json['epuisee'] as bool,
    stockVisible: json['stock_visible'] == null
        ? null
        : (json['stock_visible'] as num).toDouble(),
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'produit_id': produitId,
    'modele_id': modeleId,
    'couleur_id': couleurId,
    'taille_id': tailleId,
    'prix': prix,
    'prix_normal': prixNormal,
    'en_promo': enPromo,
    'image_url': imageUrl,
    'modele_nom_ar': modeleNomAr,
    'modele_nom_fr': modeleNomFr,
    'couleur_nom_ar': couleurNomAr,
    'couleur_nom_fr': couleurNomFr,
    'couleur_hex': couleurHex,
    'taille_nom_ar': tailleNomAr,
    'taille_nom_fr': tailleNomFr,
    'epuisee': epuisee,
    'stock_visible': stockVisible,
  };
}

/// Table `zones_livraison`.
class ZonesLivraisonRow {
  const ZonesLivraisonRow({
    required this.id,
    required this.boutiqueId,
    this.nomAr,
    this.nomFr,
    required this.frais,
    this.delaiJours,
    required this.ordre,
    required this.actif,
    required this.creeLe,
    required this.modifieLe,
  });

  final String id;
  final String boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final double frais;
  final int? delaiJours;
  final int ordre;
  final bool actif;
  final DateTime creeLe;
  final DateTime modifieLe;

  factory ZonesLivraisonRow.depuisJson(Map<String, dynamic> json) =>
      ZonesLivraisonRow(
        id: json['id'] as String,
        boutiqueId: json['boutique_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        frais: (json['frais'] as num).toDouble(),
        delaiJours: json['delai_jours'] == null
            ? null
            : json['delai_jours'] as int,
        ordre: json['ordre'] as int,
        actif: json['actif'] as bool,
        creeLe: DateTime.parse(json['cree_le'] as String),
        modifieLe: DateTime.parse(json['modifie_le'] as String),
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'frais': frais,
    'delai_jours': delaiJours,
    'ordre': ordre,
    'actif': actif,
    'cree_le': creeLe.toIso8601String(),
    'modifie_le': modifieLe.toIso8601String(),
  };
}

/// Vue `zones_livraison_publiques`.
class ZonesLivraisonPubliquesRow {
  const ZonesLivraisonPubliquesRow({
    this.id,
    this.boutiqueId,
    this.nomAr,
    this.nomFr,
    this.frais,
    this.delaiJours,
  });

  final String? id;
  final String? boutiqueId;
  final String? nomAr;
  final String? nomFr;
  final double? frais;
  final int? delaiJours;

  factory ZonesLivraisonPubliquesRow.depuisJson(Map<String, dynamic> json) =>
      ZonesLivraisonPubliquesRow(
        id: json['id'] == null ? null : json['id'] as String,
        boutiqueId: json['boutique_id'] == null
            ? null
            : json['boutique_id'] as String,
        nomAr: json['nom_ar'] == null ? null : json['nom_ar'] as String,
        nomFr: json['nom_fr'] == null ? null : json['nom_fr'] as String,
        frais: json['frais'] == null ? null : (json['frais'] as num).toDouble(),
        delaiJours: json['delai_jours'] == null
            ? null
            : json['delai_jours'] as int,
      );

  Map<String, dynamic> versJson() => {
    'id': id,
    'boutique_id': boutiqueId,
    'nom_ar': nomAr,
    'nom_fr': nomFr,
    'frais': frais,
    'delai_jours': delaiJours,
  };
}
