# Cahier des charges — Plateforme SaaS de gestion de boutique pour commerçantes

Nov 9, 2026 · @hello

## 1. Présentation générale

La plateforme est un SaaS multi-boutiques qui permet à des commerçantes (sacs, accessoires, maquillage, voiles/melhafas, etc.) de gérer leur boutique de bout en bout et de vendre en ligne, avec un abonnement mensuel/annuel facturé par l'éditeur (vous).

### 1.1 Contexte et problème

- Les commerçantes gèrent leur stock sur cahier, WhatsApp ou Excel : erreurs de stock, pas de suivi des lots, pas de facturation propre.
- Elles n'ont pas de boutique en ligne simple, ni de lien entre vente en boutique, stock et commandes en ligne.
- Le besoin : un outil mobile simple (usage principal sur téléphone), en arabe (langue par défaut) et en français, utilisable même avec une connexion instable.

### 1.2 Vision produit

Une commerçante crée son compte, configure ses référentiels, ajoute ses produits, vend au comptoir (POS), émet devis/BL/factures, suit son stock par lot, reçoit les commandes de sa boutique en ligne et personnalise l'apparence de son site depuis son téléphone. L'éditeur administre tous les clients, abonnements et sites depuis une console web.

### 1.3 Les trois applications

| Application | Technologie | Utilisateurs | Rôle |
| --- | --- | --- | --- |
| App Admin Web | React + Supabase | Vous (éditeur) et votre équipe | Gérer les commerçantes, boutiques, abonnements, domaines/sites web, support |
| App Mobile Commerçante | Flutter + Supabase | Commerçantes et leurs employées | Le vrai produit : gestion complète de la boutique |
| Boutique en ligne | React + Supabase | Clientes finales des commerçantes | Catalogue, panier, commande, suivi |

### 1.4 Cibles et volumétrie de départ

- Cible principale : petites et moyennes boutiques de femmes (1 à 5 utilisatrices par boutique), marché mauritanien en premier (devise MRU, mobile money local), extensible à d'autres pays.
- Hypothèse de dimensionnement V1 : 100 boutiques, 2 000 produits par boutique, 200 ventes/jour par boutique au maximum.

### 1.5 Glossaire

| Terme | Définition |
| --- | --- |
| Tenant / Boutique | Une boutique cliente avec ses données isolées (identifiée par `boutique_id`) |
| POS | Point de vente : encaissement rapide au comptoir |
| BL | Bon de livraison |
| Lot | Entrée de stock datée avec quantité, coût d'achat et éventuellement fournisseur ; base du suivi FIFO |
| Variante | Combinaison modèle + couleur (+ taille) d'un produit, avec son propre stock et code-barres |
| Référentiel | Données de base paramétrables : catégories, modèles, couleurs, modes de paiement, clients, fournisseurs |
| Melhafa | Voile traditionnel mauritanien (produit à variantes de couleur/modèle) |

## 2. Périmètre, acteurs et permissions

### 2.1 Acteurs

| Acteur | Application | Description |
| --- | --- | --- |
| Super-admin | Admin Web | Vous : accès total à toutes les boutiques, plans, facturation SaaS |
| Support / Agent | Admin Web | Employé de l'éditeur : lecture et actions limitées (support, activation) |
| Propriétaire (Owner) | Mobile | La commerçante : tous les droits sur sa boutique |
| Manager | Mobile | Gestion produits, stock, rapports ; pas d'accès abonnement ni suppression sensible |
| Vendeuse (Cashier) | Mobile | POS, clients, consultation stock ; pas de coûts d'achat ni de paramètres |
| Magasinière (Stock keeper) | Mobile | Entrées, sorties, inventaire, lots ; pas de prix de vente ni rapports financiers |
| Cliente finale | Boutique en ligne | Parcourt, commande, suit ses commandes (compte optionnel) |

### 2.2 Matrice des permissions (mobile)

| Module | Owner | Manager | Vendeuse | Magasinière |
| --- | --- | --- | --- | --- |
| POS / ventes | Oui | Oui | Oui | Non |
| Devis, BL, factures | Oui | Oui | Création | Non |
| Produits (création, prix) | Oui | Oui | Lecture | Lecture |
| Coûts d'achat et marges | Oui | Oui | Non | Non |
| Stock (entrées, sorties, lots) | Oui | Oui | Lecture | Oui |
| Commandes en ligne | Oui | Oui | Oui | Préparation |
| Référentiels | Oui | Oui | Lecture | Lecture |
| Rapports financiers | Oui | Oui | Non | Non |
| Paramètres, employées, site web | Oui | Partiel | Non | Non |
| Abonnement | Oui | Non | Non | Non |

Les permissions sont stockées en base (table de rôles/permissions) pour pouvoir ajouter des rôles personnalisés en V2.

### 2.3 Dans le périmètre (V1)

- Les trois applications décrites en sections 4 à 6.
- Multi-boutiques (multi-tenant), plusieurs utilisatrices par boutique, abonnements, thèmes de site, notifications push.
- Interface en arabe (langue par défaut, RTL) et en français, devise configurable (MRU par défaut).

### 2.4 Hors périmètre (V1)

- Comptabilité générale complète, paie, fiscalité avancée.
- Paiement en ligne automatisé avec agrégateur (prévu en V2 ; V1 = paiement à la livraison ou manuel/mobile money avec preuve).
- Marketplace multi-vendeuses (les sites restent indépendants).
- Application iOS/Android pour les clientes finales (la boutique est un site web responsive/PWA).

## 3. Architecture technique et stack

Un seul projet Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime) sert les trois applications ; l'isolement entre boutiques est garanti par Row Level Security (RLS) sur `boutique_id`.

&#91;embedded content: architecture · 3 clients, 1 projet Supabase, 1 service externe\]

Les trois applications parlent au même projet Supabase ; l’app mobile est le client principal et Firebase n’est appelé que par une Edge Function.

### 3.1 Stack retenue

| Couche | Choix | Usage |
| --- | --- | --- |
| Base de données | Supabase PostgreSQL | Toutes les données, fonctions SQL (RPC), triggers, vues |
| Authentification | Supabase Auth | Numéro de téléphone (identifiant) + mot de passe à 4 chiffres, via une Edge Function de connexion (le code est converti côté serveur en secret d'authentification) ; JWT avec claims `boutique_id`, `role` |
| Stockage | Supabase Storage | Images produits, logos, bannières, justificatifs de paiement |
| Logique serveur | Edge Functions (Deno/TypeScript) | Création de boutique, webhooks, notifications, tâches planifiées |
| Temps réel | Supabase Realtime | Nouvelles commandes, mise à jour de stock |
| Admin Web | React + Vite + TypeScript, TanStack Query, shadcn/ui ou MUI | Console éditeur |
| Boutique en ligne | React (Vite SPA + pré-rendu) | Sites des clientes |
| Mobile | Flutter (GetX pour l'état, la navigation et l'injection, Drift/SQLite pour le cache hors ligne) | App commerçante |
| Notifications | Firebase Cloud Messaging (configuration ultérieure) | Push mobile (et web push éventuel) |

### 3.2 Multi-tenant et sites web

- Modèle "base partagée, schéma partagé" : chaque table métier porte `boutique_id`, avec politiques RLS basées sur les claims du JWT.
- Une seule application React de boutique en ligne est déployée ; elle identifie la boutique par sous-domaine (`nom.votreplateforme.com`) ou domaine personnalisé, résout `boutique_id` via une table `domaines_boutique`, puis charge thème, produits et paramètres.
- Le visiteur anonyme lit uniquement via des vues publiques (`produits_publics`, `parametres_boutique_publics`) et ne peut créer une commande que par une fonction RPC contrôlée.
- Domaines personnalisés : vérification DNS + certificat géré par l'hébergeur front (Vercel, Netlify ou Cloudflare Pages).

### 3.3 Sécurité des données

- RLS activée sur toutes les tables ; aucune table sans politique ; tests automatisés d'isolement entre deux boutiques.
- La clé `service_role` n'est jamais exposée côté client : uniquement dans les Edge Functions.
- Les opérations sensibles (vente, ajustement de stock, génération de numéro de facture) passent par des fonctions SQL transactionnelles pour garantir l'atomicité.
- Journal d'audit (`journal_audit`) pour les actions critiques : suppression, annulation de facture, ajustement de stock, changement de prix.
- Suspension d'abonnement : une fonction `boutique_est_active()` utilisée dans les politiques RLS d'écriture bloque les créations quand la boutique est suspendue (lecture seule conservée).

## 4. Application Admin Web (React)

Console réservée à l'éditeur pour gérer les commerçantes, leurs boutiques, leurs abonnements et leurs sites web. Accès par email + mot de passe + 2FA (TOTP) ; rôles `super_admin` et `support`.

### 4.1 Modules fonctionnels

| Module | Fonctionnalités |
| --- | --- |
| Tableau de bord | Nombre de boutiques actives/suspendues/en essai, MRR, nouvelles inscriptions du mois, abonnements expirant sous 7 jours, commandes en ligne globales, graphiques d'évolution |
| Commerçantes (clients) | Liste, recherche, filtres (statut, plan, ville) ; fiche : identité, téléphone, email, WhatsApp, ville, notes internes, historique d'activité ; création manuelle ou validation d'une inscription ; désactivation ; réinitialisation du mot de passe |
| Boutiques | Une commerçante peut avoir plusieurs boutiques ; fiche : nom, activité, logo, adresse, devise, langue, statut, utilisateurs/employées, quotas utilisés (produits, stockage, utilisateurs) ; suspension/réactivation ; "se connecter en tant que" (impersonation tracée dans le journal) |
| Plans et abonnements | CRUD des plans (Gratuit/Essai, Standard, Premium) avec prix mensuel/annuel, limites (nb utilisateurs, nb produits, boutique en ligne oui/non, domaine personnalisé, thèmes) ; affectation et changement de plan ; dates de début/fin ; renouvellement ; remises et période d'essai |
| Paiements d'abonnement | Enregistrement manuel des paiements (espèces, virement, mobile money : Bankily, Masrvi, Sedad, etc.) avec reuve en pièce jointe ; reçus PDF ; historique ; impayés ; relances |
| Sites web | Liste des sites : sous-domaine, domaine personnalisé, statut DNS/SSL, thème actif, publié/brouillon ; activation/désactivation ; gestion du catalogue de thèmes (création, aperçu, activation par plan) ; réservation de sous-domaines |
| Notifications | Envoi de messages push ou in-app à une boutique, un plan ou tous (annonces, maintenance, rappel d'expiration) ; modèles de messages FR/AR |
| Support | Tickets simples (sujet, boutique, statut, réponses) ou lien WhatsApp ; base d'aide (articles FR/AR) |
| Utilisateurs internes | Gestion des admins/agents, rôles, journal d'activité |
| Paramètres globaux | Devises, langues, conditions d'utilisation, modèles de facture par défaut, catégories prédéfinies de départ (sacs, maquillage, voiles, accessoires), versions minimales de l'app mobile (forçage de mise à jour) |
| Journal d'audit | Consultation filtrée des actions sensibles de toutes les boutiques |

### 4.2 Règles de gestion

- Création d'une commerçante : l'admin saisit les informations ; une Edge Function crée l'utilisateur Auth, la boutique, les référentiels par défaut (catégories, modes de paiement, unités, numérotation), l'abonnement d'essai et génère un code initial à 4 chiffres et l'envoie par WhatsApp (identifiant = numéro de téléphone).
- Une boutique dont l'abonnement expire passe en `grace` (7 jours par défaut, configurable), puis en `suspendu` : lecture seule dans l'app mobile et boutique en ligne affichant une page "temporairement indisponible".
- Le changement de plan applique immédiatement les nouveaux quotas ; un dépassement de quota bloque la création (pas la lecture ni la suppression).
- Toute impersonation et toute suspension est enregistrée dans `journal_audit` avec l'auteur.

### 4.3 Exigences d'interface

- Tables paginées côté serveur avec tri, filtres, export CSV/Excel.
- Interface responsive (usage tablette), mode clair/sombre, arabe (RTL) par défaut avec bascule en français.

## 5. Application Mobile Flutter (commerçante)

C'est le produit principal : une app Android (puis iOS) pour gérer toute la boutique, pensée pour un usage rapide à une main, en arabe (langue par défaut) et en français, avec un mode hors ligne pour les ventes et la consultation.

### 5.1 Navigation et accueil

- Barre inférieure : Accueil, Vente (POS), Produits, Stock, Plus (commandes, documents, clients, rapports, site web, paramètres).
- Accueil : chiffre d'affaires du jour/semaine/mois, nombre de ventes, produits en rupture ou sous seuil, commandes en ligne à traiter, impayés clients, raccourcis (Nouvelle vente, Nouveau produit, Entrée de stock).
- Sélecteur de boutique si la commerçante en possède plusieurs ; sélecteur de langue AR/FR (arabe par défaut) ; indicateur de synchronisation.

### 5.2 Authentification et onboarding

- Connexion par numéro de téléphone (identifiant) + mot de passe à 4 chiffres, identique sur l'app mobile et sur la boutique en ligne ; réinitialisation par l'administrateur ou par la propriétaire de la boutique ; verrouillage temporaire après 5 tentatives échouées (un code à 4 chiffres est faible : la limitation des tentatives est obligatoire) ; déverrouillage biométrique optionnel ; session multi-appareils avec déconnexion à distance.
- Assistant au premier lancement : infos boutique (nom, logo, adresse, téléphone, devise), choix des catégories de départ (sacs, accessoires, maquillage, voiles...), mode de paiement par défaut, ajout de la première employée (optionnel).
- Blocage clair à l'expiration de l'abonnement (écran d'information + contact éditeur), avec lecture seule pendant la période de grâce.

### 5.3 Point de vente (POS)

- Écran de vente rapide : recherche par nom, scan code-barres/QR (caméra), grille de produits par catégorie, favoris.
- Produit à variantes : sélection du modèle et de la couleur (pastille de couleur avec nom) avant ajout au panier ; affichage du stock disponible par variante.
- Panier : quantités, prix modifiable (si permission), remise par ligne et globale (montant ou %), note, cliente associée (existante ou création rapide, ou "cliente de passage").
- Paiement : un ou plusieurs modes (espèces, mobile money, carte, crédit/à recevoir) ; paiement partiel avec solde restant en dette cliente ; rendu de monnaie.
- Ticket de caisse : aperçu, partage WhatsApp (PDF généré à la demande), impression Bluetooth/thermique 58/80 mm (ESC/POS), réimpression.
- Ventes suspendues (mise en attente de plusieurs paniers), annulation, retour/avoir avec remise en stock optionnelle.
- Sessions de caisse : ouverture avec fond de caisse, clôture avec écart (attendu vs compté), rapport Z.
- Chaque vente décrémente le stock (FIFO par lot) dans une transaction unique ; le coût de revient du lot sert à calculer la marge.

### 5.4 Devis, bons de livraison et factures

| Document | Règles |
| --- | --- |
| Devis | Brouillon, envoyé, accepté, refusé, expiré ; date de validité ; conversion en BL ou facture en un clic ; aucun impact sur le stock |
| Bon de livraison (BL) | Créé depuis un devis, une commande ou librement ; sortie de stock à la validation ; statuts : brouillon, validé, livré, facturé ; regroupement de plusieurs BL en une facture |
| Facture | Créée depuis POS, devis, BL ou commande ; statuts : brouillon, émise, partiellement payée, payée, annulée ; paiements multiples ; échéance ; sortie de stock si pas déjà faite par un BL |
| Avoir | Créé depuis une facture ; retour en stock optionnel ; remboursement ou solde client |

- Numérotation séquentielle configurable par type et par année (ex. `FAC-2026-0001`, `DEV-2026-0001`, `BL-2026-0001`), attribuée à l'émission par une fonction SQL (sans trou, sans doublon, même hors ligne via plages réservées par appareil).
- Une facture émise n'est plus modifiable : correction par avoir ou annulation tracée.
- Aucun PDF n'est enregistré : le document (en-tête figé à l'émission, lignes, paiements) est conservé en base de données et le PDF est généré à la demande, côté appareil ou côté web, avec logo, coordonnées, conditions de paiement, pied de page personnalisable, modèle arabe/français ; impression Bluetooth ou A4, partage WhatsApp ou email ; QR code vers le paiement ou la facture en ligne (optionnel).

### 5.5 Produits

- Fiche produit : nom (FR/AR), description, catégorie, sous-catégorie, marque, photos multiples (galerie, photo principale, compression automatique), unité, statut (actif/inactif), visible en ligne oui/non, tags, slug SEO.
- Variantes : un produit possède des variantes définies par modèle, couleur et éventuellement taille ; chaque variante a son SKU, son code-barres (génération automatique EAN/Code128), son prix de vente, son prix promo, son seuil d'alerte et son image.
- Prix : prix de vente, prix de gros optionnel, prix promotionnel avec dates ; coût d'achat issu des lots (non saisi à la main sur la fiche).
- Création rapide : duplication d'un produit, génération automatique de toutes les variantes (modèles × couleurs), import CSV/Excel, étiquettes à imprimer (nom, prix, code-barres).
- Liste : recherche, filtres (catégorie, stock bas, inactifs), tri, vue grille/liste, actions groupées (activer, masquer, changer de catégorie).
- Suppression logique uniquement (archivage) pour préserver l'historique.

### 5.6 Stock, lots, entrées et sorties

Le stock d'une variante est la somme des quantités restantes de ses lots ; il n'est jamais modifié directement, uniquement par des mouvements.

| Opération | Description | Effet |
| --- | --- | --- |
| Entrée (achat / réception) | Bon d'entrée : fournisseur, date, référence, lignes (variante, quantité, coût unitaire, date d'expiration optionnelle) ; crée un lot par ligne avec numéro auto (`LOT-2026-0001`) | + quantité dans un nouveau lot |
| Sortie vente | Générée par POS, facture ou BL ; consommation FIFO (lot le plus ancien d'abord, ou FEFO si date d'expiration, utile pour le maquillage) | − quantité dans un ou plusieurs lots |
| Sortie manuelle | Casse, perte, vol, cadeau, usage interne, avec motif obligatoire | − quantité |
| Retour client | Depuis un avoir : remise en stock dans le lot d'origine ou un lot de retour | + quantité |
| Retour fournisseur | Sortie d'un lot avec motif | − quantité |
| Transfert | Vers une autre commerçante : vente chez l'émettrice, achat chez la destinataire (voir ci-dessous) | − chez l'émettrice, + chez la destinataire après acceptation |
| Inventaire | Comptage par catégorie/emplacement, écarts calculés, validation générant des ajustements | ± quantité avec motif "inventaire" |

- Table `mouvements_stock` en ajout seul (append-only) ; chaque mouvement référence sa source (facture, BL, bon d'entrée, ajustement) et l'utilisatrice.
- Alertes : seuil minimum par variante, notification de rupture, lots proches de l'expiration.
- Valorisation du stock au coût réel des lots ; marge par vente et par produit.
- Stock négatif interdit par défaut (paramétrable) ; réservation de stock pour les commandes en ligne confirmées non encore livrées.
- Écrans : tableau de stock, détail variante avec historique des mouvements et liste des lots, saisie d'entrée par scan, historique global filtrable.

**Transfert de stock entre deux commerçantes** (phase V1)

1. La commerçante A choisit la boutique destinataire (recherche par numéro de téléphone ou code boutique), sélectionne les variantes et fixe un prix de cession par ligne.
2. À la validation, l'opération est enregistrée chez A comme une vente (facture ou BL de type transfert, sortie de stock FIFO, coût figé) et un transfert à l'état "envoyé" apparaît chez B avec une notification.
3. B consulte le détail puis accepte ou refuse. États : brouillon, envoyé, accepté, refusé, annulé.
4. À l'acceptation, le transfert est enregistré chez B comme un achat (bon d'entrée, un lot par ligne avec le prix de cession comme coût d'achat, fournisseur = boutique A). Pour chaque ligne, B choisit une variante existante ou crée un produit à partir des informations reçues (noms, photos), puis saisit son propre prix de vente avant de valider l'achat.
5. En cas de refus ou d'annulation, le stock est remis chez A et la vente est annulée par un avoir.

- Les deux boutiques ne lisent jamais directement les données l'une de l'autre : tout passe par des fonctions SQL privilégiées (`envoyer_transfert`, `repondre_transfert`) qui ne transmettent que les lignes du transfert.

### 5.7 Commandes (site web et autres canaux)

- Sources : boutique en ligne, saisie manuelle (WhatsApp, Instagram, Facebook, téléphone, en personne) avec un champ "canal".
- Statuts : nouvelle, confirmée, en préparation, prête, expédiée/livrée, annulée, retournée ; statut de paiement : non payé, partiel, payé ; historique horodaté.
- Réception en temps réel avec notification push et son ; fiche commande : articles, cliente, adresse, mode de livraison, paiement, notes, pièce jointe (preuve de paiement).
- Actions : confirmer (réserve le stock), préparer, générer BL ou facture en un clic, marquer livrée (sortie de stock), annuler (libère la réservation), contacter la cliente via WhatsApp/appel en un tap, message de statut pré-rempli.
- Livraison : zones et frais configurables, retrait en boutique, livreur assigné (nom/téléphone libres en V1).

### 5.8 Gestion des référentiels

| Référentiel | Champs principaux |
| --- | --- |
| Catégories | Nom AR/FR, parent (arborescence), image, ordre réglable par glisser-déposer, visible en ligne |
| Modèles | Nom FR/AR, catégorie associée (ex. "Melhafa Dentelle", "Sac bandoulière") |
| Couleurs | Nom FR/AR, code hexadécimal (ex. `#00FF00`, sélecteur de couleur avec aperçu), ordre |
| Tailles / unités | Libellé, type (taille, pointure, longueur), unité de vente |
| Marques | Nom, logo |
| Modes de paiement | Nom, type (espèces, mobile money, banque, carte, crédit), icône, actif, par défaut |
| Clientes | Nom, téléphone, WhatsApp, adresse, ville, notes, plafond de crédit, solde, historique d'achats |
| Fournisseurs | Nom, contact, adresse, solde, historique d'achats |
| Zones de livraison | Nom, frais, délai |
| Motifs de mouvement | Casse, perte, cadeau, inventaire, etc. |

- Tous les référentiels : création, modification, désactivation (pas de suppression si utilisé), recherche, ordre personnalisable, données de départ fournies à la création de la boutique (palette de couleurs courantes, modes de paiement locaux).
- Création "à la volée" depuis un formulaire (ex. ajouter une couleur pendant la création d'un produit).

### 5.9 Clientes, fournisseurs et dettes

- Compte client : historique des ventes, factures, paiements, solde dû ; encaissement d'un règlement global ou affecté à des factures ; relevé de compte PDF ; relance WhatsApp pré-remplie.
- Compte fournisseur : historique des entrées, montants dus, règlements.
- Dépenses simples : catégories (loyer, transport, salaire, etc.), montant, date, mode de paiement, pour calculer le bénéfice net.

### 5.10 Rapports et statistiques

- Ventes par période, par produit, par catégorie, par vendeuse, par mode de paiement, par canal (boutique / site / WhatsApp).
- Marge brute, meilleurs produits, produits dormants, valeur du stock, mouvements de stock, impayés clients, dettes fournisseurs, dépenses, résultat simplifié.
- Export PDF/Excel et partage ; filtres de dates prédéfinis (aujourd'hui, 7 jours, mois, personnalisé).

### 5.11 Gestion de la boutique en ligne (depuis le mobile)

- Activation/désactivation du site, nom du site, sous-domaine affiché en lecture seule (attribué à la création de la boutique, non modifiable depuis le mobile), domaine personnalisé (instructions DNS affichées, statut de vérification).
- Identité visuelle : logo, favicon, bannières/slider, couleur principale et secondaire, couleur du fond et du texte (sélecteur + code hex), police (liste prédéfinie), forme des boutons et coins arrondis.
- Style/thème : choix parmi plusieurs thèmes prédéfinis (mise en page de la page d'accueil, grille produits, en-tête), aperçu en direct avant publication, brouillon puis publication.
- Contenu : sections de la page d'accueil réordonnables (bannière, catégories vedettes, nouveautés, promotions, à propos, contact), pages statiques (à propos, livraison, retours, conditions), réseaux sociaux, numéro WhatsApp, horaires, adresse et carte.
- Paramètres de vente : paiement à la livraison, paiement par mobile money avec instructions et envoi de preuve, frais et zones de livraison, retrait en boutique, commande minimale, message de confirmation, activation de la gestion du stock en ligne (afficher ou masquer "en stock").
- Catalogue de la boutique : ordre des catégories réglable par glisser-déposer (menu et accueil), produits visibles ou masqués, épinglage d'un ou plusieurs produits en tête de page, ordre des produits, collections.

### 5.12 Paramètres et utilisatrices

- Profil boutique (nom, logo, coordonnées, devise, langue, fuseau, pied de page des documents), numérotation, seuil de stock par défaut, imprimante, modèles de documents.
- Employées : invitation par téléphone/email, rôle, activation/désactivation, historique d'activité.
- Abonnement : plan actuel, date d'expiration, quotas utilisés, contact pour renouveler (le paiement est enregistré par l'éditeur dans l'Admin Web en V1).
- Sauvegarde/export : export des données de la boutique en Excel/CSV.

### 5.13 Mode hors ligne et synchronisation

- Base locale SQLite (Drift) : produits, variantes, stock, clientes, référentiels et ventes récentes disponibles sans réseau.
- Ventes POS, paiements et mouvements simples créés hors ligne puis envoyés en file d'attente (outbox) avec identifiants UUID générés côté appareil et idempotence côté serveur.
- Numéros de facture : plage réservée par appareil pour éviter les doublons hors ligne.
- Règle de conflit : le serveur reste la source de vérité pour le stock ; si un stock devient négatif après synchronisation, une alerte d'écart est créée pour validation par la commerçante.
- Création de produits, import et paramètres du site nécessitent la connexion.

### 5.14 Exigences UX mobile

- Design simple, gros boutons, peu de saisie, icônes claires, thème clair/sombre ; accessible aux utilisatrices peu techniques.
- Arabe par défaut (RTL complet) avec bascule en français, chiffres et dates localisés, devise MRU (affichage sans décimales par défaut, configurable).
- Compatible Android 8+ et iOS 14+ ; fonctionne sur téléphones d'entrée de gamme (2 Go de RAM) ; APK de taille raisonnable.

## 6. Boutique en ligne (React)

Une application web unique, multi-tenant, qui affiche la boutique de chaque commerçante selon son domaine, avec son thème et son catalogue. Objectif : simple, rapide sur mobile (80 % du trafic attendu), flexible grâce aux paramètres et thèmes.

### 6.1 Pages et fonctionnalités

| Page | Contenu |
| --- | --- |
| Accueil | Sections configurables : bannière/slider, catégories vedettes, nouveautés, promotions, produits populaires, à propos, contact |
| Catalogue | Grille/liste, filtres (catégorie, couleur avec pastilles, modèle, prix, disponibilité), tri (produits épinglés en tête, catégories dans l'ordre choisi par la commerçante), recherche avec suggestions, pagination ou défilement infini |
| Fiche produit | Galerie photos avec zoom, nom, prix et promo, choix de la couleur (pastilles) et du modèle/taille, disponibilité par variante, description, produits similaires, bouton "Ajouter au panier" et "Commander via WhatsApp" |
| Panier | Modification des quantités, suppression, code promo, sous-total, frais de livraison estimés ; persistance locale et fusion avec le compte |
| Commande (checkout) | Un seul écran : nom, téléphone, ville/zone, adresse, mode de livraison ou retrait, mode de paiement, note ; récapitulatif ; confirmation avec numéro de commande |
| Suivi de commande | Page de suivi par numéro + téléphone (sans compte) : statut, historique, contact boutique |
| Compte cliente (optionnel) | Inscription et connexion par numéro de téléphone + code à 4 chiffres, adresses enregistrées, historique des commandes, favoris |
| Pages statiques | À propos, livraison et retours, conditions, contact avec carte et horaires |

### 6.2 Règles de gestion

- Seuls les produits actifs et "visibles en ligne" apparaissent ; une variante à stock nul est marquée "épuisée" (ou masquée selon paramètre).
- La création de commande passe par une fonction RPC qui vérifie prix et stock côté serveur (les prix envoyés par le navigateur ne sont jamais crus), réserve le stock et crée la commande de manière atomique ; protection anti-spam (limitation de débit, captcha léger).
- La commerçante est notifiée immédiatement (push + temps réel) ; la cliente reçoit une page de confirmation, et un message WhatsApp/SMS en V2.
- Paiement V1 : à la livraison, ou mobile money avec envoi de capture d'écran comme preuve ; paiement en ligne automatisé en V2.
- Boutique suspendue ou site désactivé : page de maintenance générique.

### 6.3 Thèmes et personnalisation

- Les thèmes sont des gabarits React prédéfinis (3 à 5 en V1) pilotés par un JSON de configuration `parametres_site` : couleurs, polices, rayon des coins, style des cartes produit, mise en page de l'en-tête, de l'accueil et du pied de page.
- Les variables sont appliquées en variables CSS ; aucun code spécifique par boutique, donc pas de déploiement par client.
- Un seul thème est actif par boutique, avec brouillon et aperçu avant publication ; chaque thème peut être restreint à certains plans.
- Le visiteur voit l'interface dans la langue de la boutique, avec bascule FR/AR si les deux sont activées.

### 6.4 SEO, performance et conformité

- Balises meta et Open Graph par produit et par boutique, `sitemap.xml` et `robots.txt` générés, URLs lisibles (`/produit/sac-bandouliere-noir`) ; balises dynamiques par page (React Helmet) et pré-rendu des pages produits pour les robots si le référencement est prioritaire.
- Images servies via les transformations Supabase Storage (WebP, redimensionnement), chargement différé ; score Lighthouse mobile visé supérieur à 85.
- PWA : installable sur l'écran d'accueil, panier conservé hors ligne.
- Pages légales (conditions, politique de confidentialité) et bandeau de consentement si des traceurs sont utilisés (Meta Pixel, Google Analytics configurables par boutique en V2).

## 7. Modèle de données (PostgreSQL / Supabase)

Conventions : clés primaires `uuid` (`id`, générées côté client pour le hors ligne), `boutique_id` sur toutes les tables métier, `cree_le`, `modifie_le`, `cree_par`, `supprime_le` (suppression logique), montants en `numeric(14,2)`, noms de tables et de colonnes en français (`snake_case`, sans accents), et pour chaque nom deux colonnes `nom_ar` / `nom_fr` (même principe pour `description_ar` / `description_fr`). La langue par défaut est l'arabe (`'ar'`).

### 7.1 Plateforme et abonnements

| Table | Colonnes clés | Remarques |
| --- | --- | --- |
| `profils` | id (= auth.users), nom\_ar, nom\_fr, telephone (identifiant de connexion), email, role\_plateforme (super\_admin, support, aucun), langue (`ar` par défaut) | Un profil par utilisateur Auth |
| `commercantes` | id, utilisateur\_id, nom\_ar, nom\_fr, telephone, whatsapp, email, ville, notes, statut | La commerçante cliente de l'éditeur |
| `boutiques` | id, commercante\_id, nom\_ar, nom\_fr, slug, type\_activite, logo\_url, devise, langue\_par\_defaut (`ar`), fuseau\_horaire, statut (essai, actif, grace, suspendu, ferme), parametres jsonb | Le tenant |
| `membres_boutique` | boutique\_id, utilisateur\_id, role\_id, statut, invite\_le | Employées et propriétaire |
| `roles`, `permissions_role` | role\_id, cle\_permission, autorise | Permissions à la carte |
| `plans` | id, nom\_ar, nom\_fr, prix\_mensuel, prix\_annuel, limites jsonb (utilisateurs, produits, stockage\_mo, boutique\_en\_ligne, domaine\_personnalise), actif | Catalogue des plans |
| `abonnements` | id, boutique\_id, plan\_id, statut, debut\_le, fin\_le, grace\_jusqu\_au, renouvellement\_auto, remise | Un abonnement actif par boutique |
| `paiements_abonnement` | id, abonnement\_id, montant, mode, reference, justificatif\_url, paye\_le, enregistre\_par | Paiements d'abonnement |
| `journal_audit` | id, boutique\_id, utilisateur\_id, action, entite, entite\_id, avant, apres, date\_action | Journal immuable |
| `notifications`, `appareils` | utilisateur\_id, jeton\_fcm, plateforme, derniere\_activite ; titre\_ar, titre\_fr, corps\_ar, corps\_fr, cible, lu | Notifications push FCM |

### 7.2 Catalogue et référentiels

| Table | Colonnes clés |
| --- | --- |
| `categories` | id, boutique\_id, parent\_id, nom\_ar, nom\_fr, image\_url, ordre (réglable par la commerçante), visible\_en\_ligne |
| `modeles` | id, boutique\_id, categorie\_id, nom\_ar, nom\_fr |
| `couleurs` | id, boutique\_id, nom\_ar, nom\_fr, code\_hex (ex. `#00FF00`), ordre |
| `tailles`, `marques`, `unites` | id, boutique\_id, nom\_ar, nom\_fr, type (pour les tailles), logo\_url (pour les marques) |
| `modes_paiement` | id, boutique\_id, nom\_ar, nom\_fr, type, icone, par\_defaut, actif |
| `produits` | id, boutique\_id, categorie\_id, marque\_id, nom\_ar, nom\_fr, description\_ar, description\_fr, slug, statut, visible\_en\_ligne, epingle, ordre\_epinglage, ordre, etiquettes |
| `variantes_produit` | id, produit\_id, modele\_id, couleur\_id, taille\_id, sku, code\_barres, prix\_vente, prix\_promo, promo\_debut, promo\_fin, stock\_minimum, image\_url, actif |
| `images_produit` | id, produit\_id, variante\_id, url, ordre |
| `clients` | id, boutique\_id, nom\_ar, nom\_fr, telephone, whatsapp, adresse, ville, plafond\_credit, solde, notes |
| `fournisseurs` | id, boutique\_id, nom\_ar, nom\_fr, telephone, adresse, solde |
| `zones_livraison` | id, boutique\_id, nom\_ar, nom\_fr, frais, delai\_jours |
| `motifs_mouvement` | id, boutique\_id, nom\_ar, nom\_fr |

### 7.3 Stock

| Table | Colonnes clés |
| --- | --- |
| `receptions_stock` + `lignes_reception_stock` | fournisseur\_id ou transfert\_id, date, reference, total ; variante\_id, quantite, cout\_unitaire, date\_expiration, prix\_vente (prix de vente propre fixé par la commerçante à l'enregistrement de l'achat) |
| `lots_stock` | id, boutique\_id, variante\_id, numero\_lot, recu\_le, quantite\_initiale, quantite\_restante, cout\_unitaire, date\_expiration, ligne\_reception\_id |
| `mouvements_stock` | id, boutique\_id, variante\_id, lot\_id, type (entree, sortie\_vente, sortie\_manuelle, retour\_client, retour\_fournisseur, ajustement, reservation, liberation, transfert\_sortie, transfert\_entree), quantite (signée), cout\_unitaire, source\_type, source\_id, motif\_id, utilisateur\_id, cree\_le |
| `ajustements_stock`, `lignes_ajustement_stock` | inventaire : quantite\_comptee, quantite\_systeme, ecart |
| `transferts` | id, boutique\_source\_id, boutique\_destination\_id, numero, statut (brouillon, envoye, accepte, refuse, annule), document\_vente\_id (côté émettrice), reception\_id (côté destinataire), envoye\_le, repondu\_le, note |
| `lignes_transfert` | id, transfert\_id, variante\_source\_id, variante\_destination\_id (correspondance choisie par la destinataire), quantite, prix\_cession, prix\_vente\_destination |
| Vue `stock_variante` | variante\_id, en\_stock, reserve, disponible (calculés depuis les lots et les mouvements) |

### 7.4 Ventes, documents et paiements

| Table | Colonnes clés |
| --- | --- |
| `sequences_documents` | boutique\_id, type\_document, annee, prochain\_numero, prefixe, plages\_appareils |
| `documents_vente` | id, boutique\_id, type (devis, bon\_livraison, facture, avoir, ticket), numero, statut, client\_id, document\_source\_id, canal (caisse, web, whatsapp, ...), date\_emission, date\_echeance, sous\_total, remise, total, paye, notes, entete jsonb (nom, logo et coordonnées de la boutique figés à l'émission) |
| `lignes_document_vente` | id, document\_id, variante\_id, libelle, quantite, prix\_unitaire, remise, cout\_unitaire (figé depuis le lot), total |
| `paiements` | id, boutique\_id, document\_id ou client\_id, mode\_paiement\_id, montant, paye\_le, session\_caisse\_id, reference, justificatif\_url |
| `sessions_caisse` | id, boutique\_id, utilisateur\_id, ouverte\_le, fermee\_le, fond\_initial, attendu, compte, ecart |
| `depenses`, `categories_depenses` | montant, date, motif, mode\_paiement\_id ; nom\_ar, nom\_fr |
| `paiements_fournisseurs` | règlements fournisseurs |

Aucun fichier PDF n'est stocké : le document est reconstitué à partir de ces tables (en-tête figé + lignes) et le PDF est généré à la demande pour l'impression ou le partage.

### 7.5 Commandes en ligne et site web

| Table | Colonnes clés |
| --- | --- |
| `commandes` | id, boutique\_id, numero, canal, client\_id ou infos de la visiteuse (nom\_client, telephone, adresse), zone\_id, frais\_livraison, statut, statut\_paiement, mode\_paiement, sous\_total, total, notes, document\_id (facture/BL lié) |
| `lignes_commande` | commande\_id, variante\_id, quantite, prix\_unitaire, libelle (copie figée) |
| `historique_statuts_commande` | commande\_id, statut, utilisateur\_id, date\_statut, note |
| `domaines_boutique` | id, boutique\_id, sous\_domaine (attribué à la création, non modifiable par la commerçante), domaine\_personnalise, statut\_dns, statut\_ssl, principal |
| `themes_site` | id, nom\_ar, nom\_fr, apercu\_url, schema\_config, plan\_minimum, actif (catalogue global) |
| `parametres_site` | boutique\_id, theme\_id, config\_theme jsonb (couleurs, polices, style), logo, favicon, liens\_sociaux, referencement, infos\_paiement, publie |
| `sections_site`, `pages_site`, `bannieres_site` | contenu à ordonner de la page d'accueil et des pages statiques (titre\_ar, titre\_fr, contenu\_ar, contenu\_fr, ordre) |
| `comptes_clientes_site`, `favoris`, `coupons` | comptes des clientes de la boutique (téléphone + code à 4 chiffres) et promotions (V1.1) |

### 7.6 Fonctions SQL (RPC) et triggers principaux

| Fonction | Rôle |
| --- | --- |
| `creer_boutique_avec_defauts(...)` | Crée boutique, membre propriétaire, référentiels par défaut, abonnement d'essai |
| `connexion_telephone_pin(telephone, code)` | Vérifie le numéro et le code à 4 chiffres, limite les tentatives, retourne la session |
| `enregistrer_vente(donnees)` | Transaction : crée le document, les lignes, les paiements, consomme les lots FIFO/FEFO, fige le coût, met à jour le solde client ; idempotente par UUID |
| `recevoir_stock(donnees)` | Crée le bon d'entrée, les lots et les mouvements |
| `ajuster_stock(donnees)` | Sortie manuelle ou inventaire avec motif |
| `convertir_document(source_id, type_cible)` | Devis → BL → facture avec reprise des lignes |
| `attribuer_numero_document(boutique_id, type)` | Attribue le prochain numéro sans trou |
| `passer_commande_en_ligne(slug_boutique, donnees)` | RPC publique : valide prix/stock, réserve, crée la commande |
| `changer_statut_commande(commande_id, statut)` | Règles de transition + réservation/libération/sortie de stock |
| `envoyer_transfert(donnees)` | Crée la vente côté émettrice et le transfert en attente (fonction privilégiée entre deux boutiques) |
| `repondre_transfert(transfert_id, decision, correspondances)` | Accepte (crée l'achat, les lots et les prix de vente propres) ou refuse (remet le stock côté émettrice) |
| `boutique_est_active(boutique_id)` | Utilisée par la RLS d'écriture selon l'abonnement |
| Triggers `modifie_le`, `audit` | Horodatage et journal sur les tables sensibles |

## 8. Edge Functions, API, stockage et notifications

Principe : le CRUD simple passe directement par le client Supabase (protégé par RLS) ; les opérations multi-tables ou privilégiées passent par des fonctions SQL (RPC) ou des Edge Functions.

### 8.1 Edge Functions

| Fonction | Déclencheur | Rôle |
| --- | --- | --- |
| `admin-create-merchant` | Admin Web | Crée l'utilisateur Auth, la boutique, les référentiels, l'abonnement d'essai ; envoie les accès |
| `admin-impersonate` | Admin Web | Génère une session temporaire tracée (super\_admin uniquement) |
| `invite-member` | Mobile | Invite une employée (création de compte, rôle) |
| `subscription-cron` | Planifiée (quotidienne) | Passe les boutiques en `grace` puis `suspendu`, envoie les rappels d'expiration à J-7, J-3, J-1 |
| `stock-alerts-cron` | Planifiée (quotidienne) | Ruptures, seuils bas, lots proches de l'expiration |
| `on-order-created` | Webhook base de données | Envoie la notification push à la boutique |
| `domain-verify` | Admin Web / Mobile | Vérifie le DNS d'un domaine personnalisé et appelle l'API de l'hébergeur pour le lier |
| `send-notification` | Admin Web | Envoi ciblé FCM (boutique, plan, tous) |
| `export-data` | Mobile | Export Excel/CSV des données d'une boutique |
| `storefront-sitemap` | Boutique en ligne | Génère `sitemap.xml` par boutique |

### 8.2 Stockage (buckets)

| Bucket | Accès | Contenu | Chemin |
| --- | --- | --- | --- |
| `product-images` | Public en lecture | Photos produits | `{boutique_id}/{produit_id}/{fichier}` |
| `shop-assets` | Public en lecture | Logo, favicon, bannières | `{boutique_id}/...` |
| `payment-proofs` | Privé | Preuves de paiement (abonnement, commandes) | `{boutique_id}/...` |

Politiques Storage basées sur `boutique_id` du chemin et le rôle ; limite de taille par fichier (5 Mo) et compression côté client avant envoi ; quota de stockage par plan.

### 8.3 Notifications (Firebase Cloud Messaging)

La configuration Firebase sera réalisée après le démarrage ; l'architecture prévoit dès maintenant la table `appareils` et l'Edge Function `send-notification` pour brancher FCM sans refonte.

| Événement | Destinataire | Canal |
| --- | --- | --- |
| Nouvelle commande en ligne | Owner, manager, vendeuse | Push + in-app |
| Changement de statut de commande | Propriétaire, manager | In-app |
| Stock bas / rupture / lot proche d'expiration | Owner, manager, magasinière | Push + in-app |
| Abonnement bientôt expiré, expiré, suspendu | Owner | Push + in-app + WhatsApp (manuel V1) |
| Annonce de l'éditeur | Boutiques ciblées | Push + in-app |
| Impayé client dépassant l'échéance | Owner, manager | In-app |
| Transfert de stock reçu ou répondu | Propriétaire, manager | Push + in-app |

### 8.4 Temps réel

- Canaux Supabase Realtime filtrés par `boutique_id` pour `commandes` et `stock_variante` ; rafraîchissement de l'app mobile sans rechargement manuel.
- Repli sur l'interrogation périodique si la connexion temps réel est coupée.

## 9. Exigences non fonctionnelles

| Domaine | Exigence |
| --- | --- |
| Performance | Ouverture de l'app mobile en moins de 3 s ; ajout d'un article au panier POS en moins de 300 ms ; liste de produits fluide jusqu'à 5 000 variantes ; pages de la boutique en ligne en moins de 2,5 s (LCP) sur 4G |
| Disponibilité | 99,5 % mensuel côté plateforme (SLA Supabase + hébergeur front) ; ventes POS possibles hors ligne |
| Sécurité | RLS partout, HTTPS/TLS, mots de passe hachés (Auth), 2FA admin, limitation de débit sur RPC publiques, validation des entrées côté serveur, secrets uniquement dans les variables d'Edge Functions, sauvegardes chiffrées |
| Confidentialité | Isolement strict entre boutiques ; données personnelles des clientes minimales ; export et suppression sur demande ; journal d'accès de l'impersonation |
| Sauvegarde | Sauvegardes quotidiennes Supabase (PITR sur plan Pro), export mensuel externe, procédure de restauration testée |
| Langues | Arabe (langue par défaut, RTL) et français dans les 3 applications ; ajout d'autres langues possible via fichiers de traduction (ARB côté Flutter, i18next côté React) |
| Internationalisation | Devise, formats de date et de nombre, fuseau par boutique ; MRU par défaut |
| Accessibilité | Contrastes AA, tailles de police ajustables, libellés explicites |
| Compatibilité | Android 8+, iOS 14+ ; navigateurs récents (Chrome, Safari, Firefox, Edge) ; boutique responsive dès 320 px |
| Observabilité | Journalisation des erreurs (Sentry), métriques Supabase, alerte sur échec des cron et des Edge Functions |
| Qualité | Tests unitaires des fonctions SQL critiques (vente, stock, numérotation), tests d'isolement RLS, tests d'intégration des parcours POS et commande, CI/CD (GitHub Actions) avec environnements dev, staging, production |
| Maintenabilité | Migrations SQL versionnées (Supabase CLI), mono-dépôt ou trois dépôts avec types générés partagés, documentation API et guide de déploiement |
| Scalabilité | Index sur `boutique_id` et colonnes de recherche, pagination par curseur, vues matérialisées pour les rapports, possibilité de partitionner `mouvements_stock` et `documents_vente` par date |

## 10. Abonnements, plans et facturation SaaS

Les montants sont à définir par vous ; le tableau ci-dessous propose la structure et les limites, à ajuster.

### 10.1 Plans proposés

|  | Essai | Standard | Premium |
| --- | --- | --- | --- |
| Durée / prix | 14 à 30 jours, gratuit | Mensuel ou annuel (prix à définir) | Mensuel ou annuel (prix à définir) |
| Utilisatrices | 1 | 3 | 10 |
| Produits (variantes) | 50 | 1 000 | Illimité |
| App mobile complète (POS, stock, documents) | Oui | Oui | Oui |
| Boutique en ligne | Oui (sous-domaine) | Oui (sous-domaine) | Oui + domaine personnalisé |
| Thèmes | 1 | 3 | Tous |
| Stockage | 200 Mo | 2 Go | 10 Go |
| Rapports avancés et export | Non | Oui | Oui |
| Support | WhatsApp | WhatsApp prioritaire | WhatsApp prioritaire + assistance à la configuration |

### 10.2 Cycle de vie d'un abonnement

1. Inscription ou création par l'admin : boutique en `essai`.
2. Paiement enregistré dans l'Admin Web : abonnement `actif` avec date de fin calculée.
3. Pas de renouvellement à la date de fin : `grace` (7 jours), l'app reste utilisable avec bandeau d'alerte.
4. Fin de grâce : `suspendu` ; lecture seule dans l'app, site web en page de maintenance, données conservées.
5. Après 90 jours de suspension : `ferme` ; export proposé puis suppression programmée selon la politique de rétention.
6. Paiement tardif : réactivation immédiate par l'admin ou automatique à l'enregistrement du paiement.

### 10.3 Paiement des abonnements

- V1 : paiement manuel (espèces, virement, mobile money) enregistré par l'admin avec preuve ; reçu PDF automatique.
- V2 : paiement en ligne via un agrégateur local ou Stripe, renouvellement automatique, factures d'abonnement générées par la plateforme.

## 11. Planning, livrables, risques et acceptation

### 11.1 Phasage

La livraison se fait en trois phases précédées d'un cadrage ; les durées sont des estimations indicatives pour 1 à 2 développeurs, à valider après les maquettes.

&#91;embedded content: feuille de route · 4 phases, 3 jalons\]

### 11.2 Livrables

- Code source des trois applications et des migrations SQL, avec dépôt versionné et pipelines de déploiement.
- Environnements dev, staging et production configurés ; APK/AAB signés ; publication Play Store (puis App Store).
- Maquettes validées, documentation technique (schéma de données, API/RPC, déploiement), guide utilisateur commerçante FR/AR et guide de l'admin.
- Jeux de données de départ (catégories, couleurs, modes de paiement, thèmes) et scripts de création de boutique.

### 11.3 Risques et parades

| Risque | Impact | Parade |
| --- | --- | --- |
| Fuite de données entre boutiques | Critique | RLS systématique, tests automatisés d'isolement, revue avant chaque mise en production |
| Incohérences de stock (hors ligne, ventes simultanées) | Élevé | Mouvements append-only, RPC transactionnelles idempotentes, alertes d'écart après synchronisation |
| Complexité du hors ligne | Élevé | Limiter le hors ligne aux ventes et à la consultation ; reste du hors ligne en phase 2 |
| Domaines personnalisés et SSL | Moyen | Sous-domaines d'abord ; automatiser la liaison via l'API de l'hébergeur ; documenter la procédure DNS |
| Adoption par des utilisatrices peu techniques | Élevé | Interface minimale, assistant de démarrage, import Excel, formation courte et vidéos en arabe |
| Paiement mobile money non automatisé | Moyen | V1 manuelle avec preuve ; intégration d'un agrégateur en V2 |
| Limites et coûts Supabase | Moyen | Suivi des quotas par plan, passage au plan Pro avant la production, index et vues matérialisées |

### 11.4 Critères d'acceptation (MVP)

- Deux boutiques de test ne voient jamais les données l'une de l'autre (test automatisé passé sur toutes les tables).
- Une vente POS avec deux modes de paiement décrémente le bon lot FIFO, génère une facture numérotée sans doublon et se partage en PDF.
- Une entrée de stock crée un lot ; une sortie manuelle exige un motif ; le stock affiché est toujours égal à la somme des lots.
- Une commande passée sur la boutique en ligne apparaît dans l'app mobile en moins de 5 secondes, réserve le stock et peut être convertie en facture.
- L'admin crée une commerçante en moins de 2 minutes ; une boutique dont l'abonnement expire passe en lecture seule automatiquement.
- Les trois applications sont utilisables en FR et en AR (RTL sans élément cassé).

### 11.5 Points à trancher avant le démarrage

- [ ] Devise(s) et pays de lancement (MRU en Mauritanie par défaut) ; faut-il gérer plusieurs devises ?
- [ ] Modes de paiement locaux à prévoir au départ (Bankily, Masrvi, Sedad, autres) et possibilité d'un agrégateur.
- [ ] Nom de domaine de la plateforme et hébergeur front (Vercel, Netlify ou Cloudflare Pages).
- [ ] Prix des plans et durée de l'essai gratuit.
- [ ] Imprimantes thermiques à supporter en priorité (modèles Bluetooth courants).
- [ ] Nombre de thèmes de boutique à livrer en V1.
