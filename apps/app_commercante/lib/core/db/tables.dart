import 'package:drift/drift.dart';

/// Cache SQLite des données de la boutique (lecture hors ligne). Le serveur reste la source de vérité.

@DataClassName('LocalCategory')
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get ordre => integer().withDefault(const Constant(0))();
  BoolColumn get visibleEnLigne => boolean().withDefault(const Constant(true))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalColor')
class LocalColors extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  TextColumn get codeHex => text()();
  IntColumn get ordre => integer().withDefault(const Constant(0))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalModel')
class LocalModels extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get categorieId => text().nullable()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalSize')
class LocalSizes extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('taille'))();
  IntColumn get ordre => integer().withDefault(const Constant(0))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Motifs de mouvement de stock (casse, perte, cadeau, inventaire…).
@DataClassName('LocalReason')
class LocalReasons extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get code => text().nullable()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalPaymentMode')
class LocalPaymentModes extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  TextColumn get type => text()();
  BoolColumn get parDefaut => boolean().withDefault(const Constant(false))();
  BoolColumn get actif => boolean().withDefault(const Constant(true))();
  IntColumn get ordre => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalCustomer')
class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  TextColumn get telephone => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get ville => text().nullable()();
  RealColumn get plafondCredit => real().nullable()();
  RealColumn get solde => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalProduct')
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get categorieId => text().nullable()();
  TextColumn get nomAr => text().nullable()();
  TextColumn get nomFr => text().nullable()();
  TextColumn get statut => text().withDefault(const Constant('actif'))();
  BoolColumn get visibleEnLigne => boolean().withDefault(const Constant(true))();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Variante vendable : libellés et stock dénormalisés pour la caisse (recherche et scan instantanés).
@DataClassName('LocalVariant')
class LocalVariants extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get produitId => text()();
  TextColumn get categorieId => text().nullable()();
  TextColumn get libelleAr => text()();
  TextColumn get libelleFr => text()();
  TextColumn get modeleId => text().nullable()();
  TextColumn get couleurId => text().nullable()();
  TextColumn get couleurHex => text().nullable()();
  TextColumn get tailleId => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get codeBarres => text().nullable()();
  RealColumn get prixVente => real()();
  RealColumn get prixPromo => real().nullable()();
  DateTimeColumn get promoDebut => dateTime().nullable()();
  DateTimeColumn get promoFin => dateTime().nullable()();
  RealColumn get stockMinimum => real().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get enStock => real().withDefault(const Constant(0))();
  RealColumn get reserve => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// File d'attente d'envoi (outbox) : opérations créées hors ligne, rejouées de façon idempotente (UUID d'appareil).
@DataClassName('OutboxItem')
class OutboxItems extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ventes suspendues (paniers mis en attente) : locales à l'appareil.
@DataClassName('SuspendedSale')
class SuspendedSales extends Table {
  TextColumn get id => text()();
  TextColumn get boutiqueId => text()();
  TextColumn get label => text().nullable()();
  TextColumn get cartJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Plages de numéros réservées sur le serveur pour cet appareil (ventes hors ligne sans doublon).
@DataClassName('NumberRange')
class NumberRanges extends Table {
  TextColumn get boutiqueId => text()();
  TextColumn get type => text()();
  IntColumn get year => integer()();
  TextColumn get prefix => text()();
  IntColumn get start => integer()();
  IntColumn get end => integer()();
  IntColumn get next => integer()();

  @override
  Set<Column> get primaryKey => {boutiqueId, type, year, start};
}

@DataClassName('MetaEntry')
class MetaEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
