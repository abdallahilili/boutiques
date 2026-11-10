import '../../l10n/app_localizations.dart';
import '../../core/types/database_types.dart';

enum RefFieldKind { text, number, hex, choice, toggle, categoryParent }

class RefField {
  const RefField(this.key, this.kind, {this.choices = const [], this.defaultValue});

  final String key;
  final RefFieldKind kind;
  final List<String> choices;
  final Object? defaultValue;
}

/// Description d'un référentiel de la boutique : table, champs propres, ordre, droit d'écriture.
class RefConfig {
  const RefConfig({
    required this.table,
    required this.title,
    required this.fields,
    this.reorderable = false,
    this.hasActive = true,
    this.tracksAuthor = true,
    this.softDelete = false,
    this.writePermission = 'referentiels.ecrire',
    this.readPermission = 'referentiels.lire',
  });

  final String table;
  final String Function(AppLocalizations) title;
  final List<RefField> fields;
  final bool reorderable;
  final bool hasActive;

  /// La table possède `cree_par` / la suppression est logique (`supprime_le`).
  final bool tracksAuthor;
  final bool softDelete;
  final String writePermission;
  final String readPermission;

  /// Colonne de tri : `ordre` si le référentiel est ordonnable, sinon le nom français.
  String get orderColumn => reorderable ? 'ordre' : 'nom_fr';

  String Function(AppLocalizations) fieldLabel(RefField f) => switch (f.key) {
        'code_hex' => (l) => l.colorHex,
        'parent_id' => (l) => l.parentCategory,
        'visible_en_ligne' => (l) => l.visibleOnline,
        'type' => (l) => l.sizeType,
        'par_defaut' => (l) => l.isDefault,
        'frais' => (l) => l.deliveryFee,
        'delai_jours' => (l) => l.deliveryDays,
        'abreviation' => (l) => l.abbreviation,
        'telephone' => (l) => l.phone,
        'adresse' => (l) => l.address,
        _ => (l) => f.key,
      };

  String choiceLabel(AppLocalizations l, String value) => switch (value) {
        'taille' => l.sizeTypeSize,
        'pointure' => l.sizeTypeShoe,
        'longueur' => l.sizeTypeLength,
        'especes' => l.paymentTypeCash,
        'mobile_money' => l.paymentTypeMobile,
        'banque' => l.paymentTypeBank,
        'carte' => l.paymentTypeCard,
        'credit' => l.paymentTypeCredit,
        _ => value,
      };
}

/// Référentiels gérables depuis l'app (création, modification, désactivation, ordre, création « à la volée »).
abstract final class RefConfigs {
  static final categories = RefConfig(
    table: Tables.categories,
    title: (l) => l.refCategories,
    reorderable: true,
    fields: const [RefField('parent_id', RefFieldKind.categoryParent), RefField('visible_en_ligne', RefFieldKind.toggle, defaultValue: true)],
  );
  static final colors = RefConfig(
    table: Tables.couleurs,
    title: (l) => l.refColors,
    reorderable: true,
    fields: const [RefField('code_hex', RefFieldKind.hex, defaultValue: '#000000')],
  );
  static final models = RefConfig(table: Tables.modeles, title: (l) => l.refModels, fields: const []);
  static final sizes = RefConfig(
    table: Tables.tailles,
    title: (l) => l.refSizes,
    reorderable: true,
    fields: const [RefField('type', RefFieldKind.choice, choices: ['taille', 'pointure', 'longueur'], defaultValue: 'taille')],
  );
  static final brands = RefConfig(table: Tables.marques, title: (l) => l.refBrands, fields: const []);
  static final units = RefConfig(table: Tables.unites, title: (l) => l.refUnits, fields: const [RefField('abreviation', RefFieldKind.text)]);
  static final paymentModes = RefConfig(
    table: Tables.modesPaiement,
    title: (l) => l.refPaymentModes,
    reorderable: true,
    fields: const [
      RefField('type', RefFieldKind.choice, choices: ['especes', 'mobile_money', 'banque', 'carte', 'credit'], defaultValue: 'especes'),
      RefField('par_defaut', RefFieldKind.toggle, defaultValue: false),
    ],
  );
  static final deliveryZones = RefConfig(
    table: Tables.zonesLivraison,
    title: (l) => l.refDeliveryZones,
    reorderable: true,
    tracksAuthor: false,
    fields: const [RefField('frais', RefFieldKind.number, defaultValue: 0), RefField('delai_jours', RefFieldKind.number)],
  );
  static final suppliers = RefConfig(
    table: Tables.fournisseurs,
    title: (l) => l.refSuppliers,
    hasActive: false,
    softDelete: true,
    writePermission: 'stock.ecrire',
    readPermission: 'stock.lire',
    fields: const [RefField('telephone', RefFieldKind.text), RefField('adresse', RefFieldKind.text)],
  );

  static final all = [categories, colors, models, sizes, brands, units, paymentModes, deliveryZones, suppliers];
}
