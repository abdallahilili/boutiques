import 'package:flutter/material.dart';

import '../../../core/widgets/color_picker.dart';

/// Valeurs acceptées par la boutique en ligne (voir `app_boutique/src/lib/theme.ts`) : toute autre valeur est ignorée.
const siteFonts = ['systeme', 'serif', 'naskh', 'arrondie'];
const siteRadii = ['aucun', 'petit', 'moyen', 'grand', 'pilule'];
const siteCardStyles = ['bordure', 'ombre', 'minimal'];
const siteHeaders = ['centre', 'gauche'];
const siteGrids = [2, 3];

/// Types de sections de la page d'accueil (contrainte SQL de `sections_site.type`).
const siteSectionTypes = ['banniere', 'categories_vedettes', 'nouveautes', 'promotions', 'produits_populaires', 'a_propos', 'contact'];

/// Rayon d'angle (en pixels) utilisé pour l'aperçu à l'écran.
double radiusPixels(String radius) => switch (radius) {
      'aucun' => 0,
      'petit' => 6,
      'moyen' => 12,
      'grand' => 20,
      'pilule' => 999,
      _ => 12,
    };

/// Brouillon d'apparence du site : couleurs, police, forme, style, thème. Publié vers `config_theme`.
class ThemeDraft {
  ThemeDraft({
    this.themeId,
    this.primary = const Color(0xFF8B3A5E),
    this.secondary = const Color(0xFFD4AF37),
    this.background = const Color(0xFFFFFFFF),
    this.text = const Color(0xFF1F1F1F),
    this.font = 'systeme',
    this.radius = 'moyen',
    this.cardStyle = 'bordure',
    this.header = 'centre',
    this.grid = 2,
  });

  factory ThemeDraft.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ThemeDraft();
    final colors = (json['couleurs'] as Map?)?.cast<String, dynamic>() ?? const {};
    Color color(String key, Color fallback) => colorFromHex('${colors[key] ?? ''}') ?? fallback;
    final base = ThemeDraft();
    String pick(String? value, List<String> allowed, String fallback) => allowed.contains(value) ? value! : fallback;
    return ThemeDraft(
      themeId: json['theme_id'] as String?,
      primary: color('primaire', base.primary),
      secondary: color('secondaire', base.secondary),
      background: color('fond', base.background),
      text: color('texte', base.text),
      font: pick(json['police'] as String?, siteFonts, base.font),
      radius: pick(json['rayon'] as String?, siteRadii, base.radius),
      cardStyle: pick(json['style_carte'] as String?, siteCardStyles, base.cardStyle),
      header: pick(json['entete'] as String?, siteHeaders, base.header),
      grid: siteGrids.contains(json['grille']) ? json['grille'] as int : base.grid,
    );
  }

  String? themeId;
  Color primary;
  Color secondary;
  Color background;
  Color text;
  String font;
  String radius;
  String cardStyle;
  String header;
  int grid;

  /// Contenu de `parametres_site.config_theme` (sans l'identifiant du thème, stocké dans `theme_id`).
  Map<String, dynamic> toConfig() => {
        'couleurs': {'primaire': colorToHex(primary), 'secondaire': colorToHex(secondary), 'fond': colorToHex(background), 'texte': colorToHex(text)},
        'police': font,
        'rayon': radius,
        'style_carte': cardStyle,
        'entete': header,
        'grille': grid,
      };

  /// Contenu de `config_brouillon` : la configuration plus le thème choisi.
  Map<String, dynamic> toDraftJson() => {...toConfig(), 'theme_id': themeId};

  /// Contraste lisible (blanc ou noir) pour le texte posé sur [color], comme la boutique en ligne.
  static Color onColor(Color color) => color.computeLuminance() > 0.4 ? const Color(0xFF111111) : Colors.white;
}

/// Déplacement d'un élément dans une liste réordonnable (convention de `onReorderItem` : [newIndex] est la
/// position finale, déjà corrigée du retrait de l'élément déplacé).
List<T> reordered<T>(List<T> items, int oldIndex, int newIndex) {
  final copy = [...items];
  copy.insert(newIndex, copy.removeAt(oldIndex));
  return copy;
}

/// Modifications d'ordre à écrire : seules les lignes dont la position a changé.
List<({String id, int order})> orderUpdates(List<String> before, List<String> after) {
  final previous = {for (var i = 0; i < before.length; i++) before[i]: i};
  return [
    for (var i = 0; i < after.length; i++)
      if (previous[after[i]] != i) (id: after[i], order: i),
  ];
}

/// Adresse de page statique valide : minuscules, chiffres et tirets (contrainte SQL).
bool isValidPageSlug(String slug) => RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(slug);

/// Nom de domaine valide pour `domaines_boutique.domaine_personnalise` (minuscules, au moins un point).
bool isValidCustomDomain(String domain) => RegExp(r'^[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(domain);

/// Normalise la saisie d'un domaine : retire schéma, chemin et point final.
String normalizeDomain(String input) => input.trim().toLowerCase().replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/.*$'), '').replaceFirst(RegExp(r'\.$'), '');
