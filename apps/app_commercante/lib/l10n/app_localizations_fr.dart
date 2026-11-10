// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Ma boutique';

  @override
  String get login => 'Connexion';

  @override
  String get phone => 'Numéro de téléphone';

  @override
  String get pin => 'Code secret (4 chiffres)';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get invalidCredentials => 'Numéro ou code incorrect';

  @override
  String accountLocked(int minutes) {
    return 'Trop de tentatives. Réessayez dans $minutes min';
  }

  @override
  String get networkError =>
      'Connexion au serveur impossible, vérifiez Internet';

  @override
  String get genericError => 'Une erreur est survenue, réessayez';

  @override
  String get phoneRequired => 'Saisissez le numéro de téléphone';

  @override
  String get pinInvalid => 'Le code comporte 4 chiffres';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabSell => 'Vente';

  @override
  String get tabProducts => 'Produits';

  @override
  String get tabStock => 'Stock';

  @override
  String get tabMore => 'Plus';

  @override
  String get language => 'Langue';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'Français';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get loading => 'Chargement…';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get create => 'Créer';

  @override
  String get search => 'Rechercher';

  @override
  String get confirm => 'Confirmer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get optional => 'facultatif';

  @override
  String get requiredField => 'Ce champ est obligatoire';

  @override
  String get nameAr => 'Nom en arabe';

  @override
  String get nameFr => 'Nom en français';

  @override
  String get nameRequired => 'Saisissez le nom dans au moins une langue';

  @override
  String get amount => 'Montant';

  @override
  String get quantity => 'Quantité';

  @override
  String get price => 'Prix';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get discount => 'Remise';

  @override
  String get note => 'Note';

  @override
  String get address => 'Adresse';

  @override
  String get city => 'Ville';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get status => 'Statut';

  @override
  String get date => 'Date';

  @override
  String get actions => 'Actions';

  @override
  String get none => 'Aucun';

  @override
  String get all => 'Tous';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get scan => 'Scanner';

  @override
  String get saved => 'Enregistré';

  @override
  String get deleted => 'Supprimé';

  @override
  String get emptyList => 'Rien à afficher pour le moment';

  @override
  String get permissionDenied =>
      'Vous n\'avez pas le droit d\'effectuer cette action';

  @override
  String get connectionRequired =>
      'Cette action nécessite une connexion Internet';

  @override
  String get offlineBanner =>
      'Hors ligne — les opérations seront envoyées dès le retour du réseau';

  @override
  String syncPending(int count) {
    return '$count opération(s) en attente';
  }

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncIssuesTitle => 'Opérations à vérifier';

  @override
  String get syncIssuesHint =>
      'Le serveur a refusé ces opérations. Relancez-les ou abandonnez-les.';

  @override
  String get discard => 'Abandonner';

  @override
  String get readOnlyBanner =>
      'Abonnement expiré : application en lecture seule. Contactez l\'éditeur pour renouveler.';

  @override
  String get graceBanner =>
      'Votre abonnement a expiré — période de grâce. Renouvelez bientôt.';

  @override
  String get suspendedTitle => 'Compte suspendu';

  @override
  String get suspendedText =>
      'Cette boutique est suspendue (abonnement expiré). Vos données sont conservées et consultables.';

  @override
  String get contactPublisher => 'Contacter l\'éditeur';

  @override
  String get shop => 'Boutique';

  @override
  String get switchShop => 'Changer de boutique';

  @override
  String get synced => 'Synchronisé';

  @override
  String lastSync(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get selectOption => 'Choisir';

  @override
  String unknownError(String details) {
    return 'Opération impossible : $details';
  }

  @override
  String get stockInsufficient => 'Stock insuffisant';

  @override
  String get serverError_stock_insuffisant =>
      'Stock insuffisant pour cette opération';

  @override
  String get serverError_client_requis =>
      'Choisissez une cliente pour une vente à crédit';

  @override
  String get serverError_plafond_credit_depasse =>
      'Plafond de crédit de la cliente dépassé';

  @override
  String get serverError_prix_non_autorise =>
      'Vous n\'avez pas le droit de modifier les prix';

  @override
  String get serverError_boutique_inactive =>
      'La boutique est en lecture seule';

  @override
  String get serverError_quota_depasse => 'Limite de votre plan dépassée';

  @override
  String get serverError_motif_obligatoire =>
      'Un motif est obligatoire pour une sortie de stock';

  @override
  String get bootLoading => 'Préparation de votre boutique…';

  @override
  String get noShopTitle => 'Aucune boutique liée à votre compte';

  @override
  String get noShopText => 'Contactez l\'éditeur pour créer votre boutique.';

  @override
  String get continueReadOnly => 'Continuer en lecture seule';

  @override
  String get dashboardToday => 'Aujourd\'hui';

  @override
  String get dashboardWeek => '7 jours';

  @override
  String get dashboardMonth => 'Ce mois';

  @override
  String get revenue => 'Chiffre d\'affaires';

  @override
  String get salesCount => 'Nombre de ventes';

  @override
  String get outOfStock => 'En rupture';

  @override
  String get lowStock => 'Sous le seuil';

  @override
  String get ordersToProcess => 'Commandes à traiter';

  @override
  String get unpaidCustomers => 'Impayés clients';

  @override
  String get shortcuts => 'Raccourcis';

  @override
  String get newSale => 'Nouvelle vente';

  @override
  String get newProduct => 'Nouveau produit';

  @override
  String get stockEntry => 'Entrée de stock';

  @override
  String get menuOrders => 'Commandes en ligne';

  @override
  String get menuDocuments => 'Factures';

  @override
  String get menuCustomers => 'Clientes';

  @override
  String get menuReferentials => 'Référentiels (couleurs, catégories…)';

  @override
  String get menuSettings => 'Paramètres de la boutique';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String get menuSync => 'Synchronisation';

  @override
  String get menuSubscription => 'Abonnement';

  @override
  String get refCategories => 'Catégories';

  @override
  String get refColors => 'Couleurs';

  @override
  String get refModels => 'Modèles';

  @override
  String get refSizes => 'Tailles';

  @override
  String get refBrands => 'Marques';

  @override
  String get refUnits => 'Unités';

  @override
  String get refPaymentModes => 'Modes de paiement';

  @override
  String get refDeliveryZones => 'Zones de livraison';

  @override
  String get refSuppliers => 'Fournisseurs';

  @override
  String get colorHex => 'Code couleur (hex)';

  @override
  String get colorInvalid => 'Code couleur invalide (ex. #00FF00)';

  @override
  String get parentCategory => 'Catégorie parente';

  @override
  String get visibleOnline => 'Visible en ligne';

  @override
  String get sizeType => 'Type';

  @override
  String get sizeTypeSize => 'Taille';

  @override
  String get sizeTypeShoe => 'Pointure';

  @override
  String get sizeTypeLength => 'Longueur';

  @override
  String get paymentTypeCash => 'Espèces';

  @override
  String get paymentTypeMobile => 'Mobile money';

  @override
  String get paymentTypeBank => 'Banque';

  @override
  String get paymentTypeCard => 'Carte';

  @override
  String get paymentTypeCredit => 'Crédit';

  @override
  String get isDefault => 'Par défaut';

  @override
  String get deliveryFee => 'Frais de livraison';

  @override
  String get deliveryDays => 'Délai (jours)';

  @override
  String get abbreviation => 'Abréviation';

  @override
  String get deactivate => 'Désactiver';

  @override
  String get activate => 'Activer';

  @override
  String get usedCannotDelete =>
      'Élément utilisé : suppression impossible. Désactivez-le plutôt.';

  @override
  String get deleteConfirm => 'Supprimer cet élément ?';

  @override
  String get reorderHint => 'Glissez pour changer l\'ordre';

  @override
  String get newItem => 'Nouvel élément';

  @override
  String get addOnTheFly => '+ Ajouter';

  @override
  String get productsTitle => 'Produits';

  @override
  String get searchProducts => 'Rechercher un produit ou un code…';

  @override
  String get noProducts => 'Aucun produit. Ajoutez votre premier produit.';

  @override
  String get lowStockFilter => 'Stock bas';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get productNew => 'Nouveau produit';

  @override
  String get productEdit => 'Modifier le produit';

  @override
  String get descriptionAr => 'Description en arabe';

  @override
  String get descriptionFr => 'Description en français';

  @override
  String get category => 'Catégorie';

  @override
  String get brand => 'Marque';

  @override
  String get unit => 'Unité';

  @override
  String get tags => 'Étiquettes (séparées par des virgules)';

  @override
  String get productActive => 'Produit actif';

  @override
  String get photos => 'Photos';

  @override
  String get addPhotos => 'Ajouter des photos';

  @override
  String get photoMain => 'Principale';

  @override
  String get variants => 'Variantes (modèle, couleur, taille)';

  @override
  String get variantAdd => 'Ajouter une variante';

  @override
  String get variantEdit => 'Modifier la variante';

  @override
  String get variantsGenerate => 'Générer toutes les variantes';

  @override
  String get variantsGenerateHint =>
      'Choisissez modèles, couleurs et tailles : toutes les combinaisons sont créées.';

  @override
  String variantsToCreate(int count) {
    return '$count variante(s) à créer';
  }

  @override
  String get basePrice => 'Prix de vente';

  @override
  String get model => 'Modèle';

  @override
  String get color => 'Couleur';

  @override
  String get size => 'Taille';

  @override
  String get sku => 'SKU';

  @override
  String get barcode => 'Code-barres';

  @override
  String get barcodeAutoHint => 'Généré automatiquement si vide';

  @override
  String get promoPrice => 'Prix promotionnel';

  @override
  String get promoStart => 'Début de la promo';

  @override
  String get promoEnd => 'Fin de la promo';

  @override
  String get stockMinimum => 'Seuil d\'alerte';

  @override
  String get archiveProduct => 'Archiver le produit';

  @override
  String get archiveConfirm =>
      'Archiver ce produit ? Son historique de ventes est conservé.';

  @override
  String get duplicateProduct => 'Dupliquer le produit';

  @override
  String priceFrom(String price) {
    return 'à partir de $price';
  }

  @override
  String stockCount(String count) {
    return 'Stock : $count';
  }

  @override
  String variantCount(int count) {
    return '$count variante(s)';
  }

  @override
  String get variantExists => 'Cette combinaison existe déjà';

  @override
  String get needOnline => 'La création de produits nécessite une connexion';

  @override
  String get createQuick => 'Création rapide';

  @override
  String get priceInvalid => 'Prix invalide';

  @override
  String get deleteVariantConfirm => 'Désactiver cette variante ?';

  @override
  String get variantInactive => 'Désactivé';

  @override
  String get stockTitle => 'Stock';

  @override
  String get stockSearch => 'Rechercher par nom ou code-barres…';

  @override
  String get stockInStock => 'En stock';

  @override
  String get stockReserved => 'Réservé';

  @override
  String get stockAvailable => 'Disponible';

  @override
  String get stockEntryTitle => 'Entrée de stock';

  @override
  String get stockOutTitle => 'Sortie de stock';

  @override
  String get inventoryTitle => 'Inventaire';

  @override
  String get stockActions => 'Opérations de stock';

  @override
  String get supplier => 'Fournisseur';

  @override
  String get reference => 'Référence';

  @override
  String get unitCost => 'Coût d\'achat unitaire';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get newSalePrice => 'Nouveau prix de vente';

  @override
  String get amountPaid => 'Montant payé';

  @override
  String get addLine => 'Ajouter un article';

  @override
  String get pickVariant => 'Choisir un article';

  @override
  String get noLines => 'Ajoutez un article ou scannez son code-barres';

  @override
  String get reason => 'Motif';

  @override
  String get reasonRequired => 'Choisissez un motif';

  @override
  String get counted => 'Quantité comptée';

  @override
  String systemQty(String qty) {
    return 'Système : $qty';
  }

  @override
  String difference(String qty) {
    return 'Écart : $qty';
  }

  @override
  String get applyInventory => 'Valider l\'inventaire';

  @override
  String get stockHistory => 'Historique des mouvements';

  @override
  String get lots => 'Lots';

  @override
  String lotRemaining(String qty, String initial) {
    return 'Reste $qty sur $initial';
  }

  @override
  String expiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String costLabel(String cost) {
    return 'Achat : $cost';
  }

  @override
  String get movement_entree => 'Entrée';

  @override
  String get movement_sortie_vente => 'Vente';

  @override
  String get movement_sortie_manuelle => 'Sortie manuelle';

  @override
  String get movement_retour_client => 'Retour cliente';

  @override
  String get movement_retour_fournisseur => 'Retour fournisseur';

  @override
  String get movement_ajustement => 'Ajustement';

  @override
  String get movement_reservation => 'Réservation';

  @override
  String get movement_liberation => 'Libération';

  @override
  String get movement_transfert_sortie => 'Transfert sortant';

  @override
  String get movement_transfert_entree => 'Transfert entrant';

  @override
  String get queuedOffline => 'Enregistré : envoi dès le retour du réseau';

  @override
  String get scanNotFound => 'Aucun article ne correspond à ce code';

  @override
  String get quantityInvalid => 'Quantité invalide';

  @override
  String get stockOutQty => 'Quantité à sortir';

  @override
  String get cartTitle => 'Panier';

  @override
  String get cartEmpty => 'Le panier est vide';

  @override
  String cartItems(String count) {
    return '$count article(s)';
  }

  @override
  String get viewCart => 'Voir le panier';

  @override
  String get pay => 'Payer';

  @override
  String get editPrice => 'Modifier le prix';

  @override
  String get applyDiscount => 'Remise globale';

  @override
  String get lineDiscount => 'Remise sur la ligne';

  @override
  String get discountAmount => 'Montant';

  @override
  String get discountPercent => 'Pourcentage';

  @override
  String get walkInCustomer => 'Cliente de passage';

  @override
  String get suspendSale => 'Mettre en attente';

  @override
  String get suspendedSales => 'Ventes en attente';

  @override
  String get noSuspended => 'Aucune vente en attente';

  @override
  String get paidSoFar => 'Déjà payé';

  @override
  String get remainingDue => 'Reste dû';

  @override
  String get changeDue => 'Monnaie à rendre';

  @override
  String get receivedAmount => 'Montant reçu';

  @override
  String get addPayment => 'Ajouter';

  @override
  String get creditSale => 'Vente à crédit (reste dû)';

  @override
  String get customerRequiredForDebt =>
      'Choisissez une cliente pour enregistrer le reste en dette';

  @override
  String get confirmSale => 'Valider la vente';

  @override
  String get receiptTitle => 'Vente enregistrée';

  @override
  String get numberPending => 'Numéro en attente d\'attribution';

  @override
  String get saleQueued => 'Enregistrée — synchronisation automatique';

  @override
  String get sharePdf => 'Partager le PDF';

  @override
  String get whatsappMessage => 'Message WhatsApp';

  @override
  String get printInvoice => 'Imprimer';

  @override
  String get newSaleAction => 'Nouvelle vente';

  @override
  String get cashSession => 'Caisse';

  @override
  String get openCash => 'Ouvrir la caisse';

  @override
  String get closeCash => 'Clôturer la caisse';

  @override
  String get cashFloat => 'Fond de caisse';

  @override
  String get cashCounted => 'Montant compté';

  @override
  String get cashExpected => 'Montant attendu';

  @override
  String get cashDifference => 'Écart';

  @override
  String get zReport => 'Rapport Z';

  @override
  String get unpaidOnly => 'Impayées';

  @override
  String get searchCustomers => 'Rechercher une cliente…';

  @override
  String get noCustomers => 'Aucune cliente';

  @override
  String get newCustomer => 'Nouvelle cliente';

  @override
  String get editCustomer => 'Modifier la cliente';

  @override
  String get creditLimit => 'Plafond de crédit';

  @override
  String get balanceDue => 'Solde dû';

  @override
  String get settleDebt => 'Encaisser un règlement';

  @override
  String get callCustomer => 'Appeler';

  @override
  String get whatsappReminder => 'Relance WhatsApp';

  @override
  String reminderMessage(String name, String amount) {
    return 'Bonjour $name, petit rappel : il vous reste $amount à régler. Merci !';
  }

  @override
  String get purchaseHistory => 'Historique d\'achats';

  @override
  String get noPurchases => 'Aucun achat';

  @override
  String get orderNew => 'Nouvelle';

  @override
  String get orderConfirmed => 'Confirmée';

  @override
  String get orderPreparing => 'En préparation';

  @override
  String get orderReady => 'Prête';

  @override
  String get orderShipped => 'Expédiée';

  @override
  String get orderDelivered => 'Livrée';

  @override
  String get orderCancelled => 'Annulée';

  @override
  String get orderReturned => 'Retournée';

  @override
  String get orderDetail => 'Détail de la commande';

  @override
  String get newOrderReceived => 'Nouvelle commande';

  @override
  String get pickup => 'Retrait en boutique';

  @override
  String get delivery => 'Livraison';

  @override
  String get paymentMode => 'Paiement';

  @override
  String get paymentProof => 'Preuve de paiement';

  @override
  String get cancelOrderConfirm =>
      'Annuler cette commande ? Le stock réservé sera libéré.';

  @override
  String get generateInvoice => 'Générer la facture';

  @override
  String get invoiceCreated => 'Facture créée';

  @override
  String get viewInvoice => 'Voir la facture';

  @override
  String orderStatusMessage(String number, String status) {
    return 'Votre commande $number : $status';
  }

  @override
  String get shopProfile => 'Profil de la boutique';

  @override
  String get onlineStore => 'Boutique en ligne';

  @override
  String get employees => 'Employées';

  @override
  String get currency => 'Devise';

  @override
  String get documentFooterAr => 'Pied de page des documents (arabe)';

  @override
  String get documentFooterFr => 'Pied de page des documents (français)';

  @override
  String get defaultStockThreshold => 'Seuil de stock par défaut';

  @override
  String get allowNegativeStock => 'Autoriser le stock négatif';

  @override
  String get subdomain => 'Sous-domaine';

  @override
  String get subdomainReadOnlyHint =>
      'Le sous-domaine est attribué à la création et ne peut pas être modifié ici. Contactez l\'éditeur pour le changer.';

  @override
  String get customDomain => 'Domaine personnalisé';

  @override
  String get shopCode => 'Code boutique';

  @override
  String get role => 'Rôle';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Vendeuse';

  @override
  String get roleStockKeeper => 'Magasinière';

  @override
  String get inviteEmployee => 'Inviter une employée';

  @override
  String get initialCode => 'Code initial';

  @override
  String get initialCodeHint =>
      'Transmettez-lui son numéro et ce code (affiché une seule fois).';

  @override
  String get resetCode => 'Réinitialiser le code';

  @override
  String get unlimited => 'illimité';

  @override
  String get renewalHint =>
      'Pour renouveler, contactez l\'éditeur : le paiement est enregistré depuis la console.';

  @override
  String get onboardingTitle => 'Bienvenue !';

  @override
  String get onboardingShop => 'Votre boutique';

  @override
  String get onboardingCategories => 'Catégories de départ';

  @override
  String get onboardingCategoriesHint =>
      'Gardez les catégories que vous vendez. Modifiables plus tard.';

  @override
  String get onboardingPayment => 'Mode de paiement par défaut';

  @override
  String get onboardingPaymentHint => 'Elle sera présélectionnée à la caisse.';

  @override
  String get chooseLogo => 'Choisir un logo';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get finish => 'Terminer';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeModeTitle => 'Mode d\'affichage';

  @override
  String get themeSystem => 'Auto';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get appColor => 'Couleur de l\'application';

  @override
  String get appColorHint =>
      'Faites glisser le doigt sur le carré et la barre, ou touchez une couleur rapide.';

  @override
  String get resetColor => 'Couleur d\'origine';

  @override
  String get shopLogo => 'Logo de la boutique';

  @override
  String get shopLogoHint =>
      'Affiché sur les factures et sur la boutique en ligne.';

  @override
  String get changeLogo => 'Changer le logo';

  @override
  String get removeLogo => 'Retirer le logo';

  @override
  String get shopIdentity => 'Identité de la boutique';

  @override
  String productImageFailed(String details) {
    return 'Produit enregistré, mais l\'envoi de la photo a échoué : $details';
  }

  @override
  String get docTypeInvoice => 'Factures';

  @override
  String get docTypeQuote => 'Devis';

  @override
  String get docTypeDelivery => 'Bons de livraison';

  @override
  String get docTypeCredit => 'Avoirs';

  @override
  String get newQuote => 'Nouveau devis';

  @override
  String get newDeliveryNote => 'Nouveau bon de livraison';

  @override
  String get quoteTitle => 'Devis';

  @override
  String get deliveryTitle => 'Bon de livraison';

  @override
  String get creditTitle => 'Avoir';

  @override
  String get ticketTitle => 'Ticket';

  @override
  String get invoiceTitle => 'Facture';

  @override
  String get validUntil => 'Valable jusqu\'au';

  @override
  String get statusDraft => 'Brouillon';

  @override
  String get statusSent => 'Envoyé';

  @override
  String get statusAccepted => 'Accepté';

  @override
  String get statusRefused => 'Refusé';

  @override
  String get statusExpired => 'Expiré';

  @override
  String get statusValidated => 'Validé';

  @override
  String get statusDelivered => 'Livré';

  @override
  String get statusInvoiced => 'Facturé';

  @override
  String get statusIssued => 'Émise';

  @override
  String get statusPartiallyPaid => 'Partiellement payée';

  @override
  String get statusPaid => 'Payée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get actionSend => 'Marquer comme envoyé';

  @override
  String get actionAccept => 'Accepté par la cliente';

  @override
  String get actionRefuse => 'Refusé par la cliente';

  @override
  String get actionValidate => 'Valider (sortie de stock)';

  @override
  String get actionDeliver => 'Marquer comme livré';

  @override
  String get convertToDelivery => 'Convertir en bon de livraison';

  @override
  String get convertToInvoice => 'Convertir en facture';

  @override
  String get invoiceSelected => 'Facturer la sélection';

  @override
  String get selectDeliveryNotes =>
      'Maintenez appuyé pour regrouper plusieurs bons de livraison en une facture';

  @override
  String get cancelDocument => 'Annuler le document';

  @override
  String get cancelReason => 'Motif d\'annulation';

  @override
  String get createCreditNote => 'Créer un avoir';

  @override
  String get creditNoteReturnStock => 'Remettre les articles en stock';

  @override
  String get creditNoteHint =>
      'Indiquez les quantités à rembourser. Le montant est d\'abord imputé sur le reste dû, puis remboursé ou crédité à la cliente.';

  @override
  String get refundMode => 'Mode de remboursement';

  @override
  String get refundAmount => 'Montant remboursé';

  @override
  String alreadyCredited(String qty) {
    return 'déjà avoiré : $qty';
  }

  @override
  String get documentCreated => 'Document créé';

  @override
  String get documentUpdated => 'Document mis à jour';

  @override
  String get linesRequired => 'Ajoutez au moins un article';

  @override
  String get onlineOnly => 'Cette action nécessite une connexion Internet';

  @override
  String get linkedDocuments => 'Documents liés';

  @override
  String get unitPriceLabel => 'Prix unitaire';

  @override
  String get quantityLabel => 'Quantité';

  @override
  String get serverError_devis_expire => 'Ce devis est expiré';

  @override
  String get serverError_deja_converti => 'Ce document a déjà été converti';

  @override
  String get serverError_bl_non_valide =>
      'Validez le bon de livraison avant de le facturer';

  @override
  String get serverError_transition_invalide =>
      'Ce changement de statut n\'est pas autorisé';

  @override
  String get serverError_annulation_impossible =>
      'Annulation impossible : utilisez un avoir pour une facture encaissée';

  @override
  String get serverError_quantite_avoir_excessive =>
      'Quantité supérieure à celle facturée';

  @override
  String get serverError_avoir_excessif =>
      'Le total des avoirs dépasse la facture';

  @override
  String get serverError_remboursement_excessif =>
      'Le remboursement dépasse le montant dû';

  @override
  String get serverError_document_non_modifiable =>
      'Seul un brouillon est modifiable';

  @override
  String get serverError_clients_differents =>
      'Les documents regroupés doivent concerner la même cliente';

  @override
  String get serverError_motif_requis => 'Le motif est obligatoire';

  @override
  String get serverError_destinataire_introuvable =>
      'Boutique destinataire introuvable';

  @override
  String get serverError_transfert_deja_traite =>
      'Ce transfert a déjà été traité';

  @override
  String get serverError_correspondance_requise =>
      'Associez chaque article reçu à un produit';

  @override
  String get serverError_trop_de_requetes =>
      'Trop de demandes, réessayez plus tard';

  @override
  String get dueDate => 'Échéance';

  @override
  String get chooseCustomer => 'Choisir une cliente (facultatif)';
}
