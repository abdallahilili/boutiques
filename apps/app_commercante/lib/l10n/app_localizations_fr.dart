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
}
