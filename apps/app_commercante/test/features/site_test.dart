import 'package:app_commercante/features/site/domain/site_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeDraft', () {
    test('configuration publiée : couleurs en hexadécimal et valeurs acceptées par la boutique en ligne', () {
      final draft = ThemeDraft(primary: const Color(0xFF8B3A5E), secondary: const Color(0xFFD4AF37), background: Colors.white, text: const Color(0xFF1F1F1F), font: 'naskh', radius: 'pilule', cardStyle: 'ombre', header: 'gauche', grid: 3);
      expect(draft.toConfig(), {
        'couleurs': {'primaire': '#8B3A5E', 'secondaire': '#D4AF37', 'fond': '#FFFFFF', 'texte': '#1F1F1F'},
        'police': 'naskh',
        'rayon': 'pilule',
        'style_carte': 'ombre',
        'entete': 'gauche',
        'grille': 3,
      });
    });

    test('le brouillon garde en plus le thème choisi', () {
      final draft = ThemeDraft(themeId: 'theme-1');
      expect(draft.toDraftJson()['theme_id'], 'theme-1');
      expect(draft.toConfig().containsKey('theme_id'), isFalse);
    });

    test('relecture : valeurs inconnues ou invalides remplacées par les valeurs par défaut', () {
      final draft = ThemeDraft.fromJson({
        'couleurs': {'primaire': '#112233', 'texte': 'rouge'},
        'police': 'comic',
        'rayon': 'grand',
        'style_carte': 'neon',
        'entete': 'gauche',
        'grille': 5,
        'theme_id': 't9',
      });
      expect(draft.primary, const Color(0xFF112233));
      expect(draft.text, ThemeDraft().text);
      expect(draft.font, 'systeme');
      expect(draft.radius, 'grand');
      expect(draft.cardStyle, 'bordure');
      expect(draft.header, 'gauche');
      expect(draft.grid, 2);
      expect(draft.themeId, 't9');
    });

    test('aller-retour brouillon → JSON → brouillon', () {
      final draft = ThemeDraft(themeId: 't1', primary: const Color(0xFF00AA55), font: 'serif', radius: 'aucun', grid: 3);
      final again = ThemeDraft.fromJson(draft.toDraftJson());
      expect(again.toDraftJson(), draft.toDraftJson());
    });

    test('contraste du texte sur la couleur principale', () {
      expect(ThemeDraft.onColor(Colors.white), const Color(0xFF111111));
      expect(ThemeDraft.onColor(const Color(0xFF222222)), Colors.white);
    });

    test('rayons d\'aperçu', () {
      expect(radiusPixels('aucun'), 0);
      expect(radiusPixels('pilule'), 999);
      expect(radiusPixels('inconnu'), 12);
    });
  });

  group('ordre', () {
    test('réordonner : position finale (onReorderItem)', () {
      expect(reordered(['a', 'b', 'c', 'd'], 0, 2), ['b', 'c', 'a', 'd']);
      expect(reordered(['a', 'b', 'c', 'd'], 3, 1), ['a', 'd', 'b', 'c']);
      expect(reordered(['a', 'b'], 1, 1), ['a', 'b']);
    });

    test('seules les lignes déplacées sont écrites', () {
      expect(orderUpdates(['a', 'b', 'c'], ['a', 'b', 'c']), isEmpty);
      final updates = orderUpdates(['a', 'b', 'c', 'd'], ['b', 'c', 'a', 'd']);
      expect(updates.map((u) => (u.id, u.order)), [('b', 0), ('c', 1), ('a', 2)]);
    });
  });

  group('validation', () {
    test('adresse de page statique', () {
      expect(isValidPageSlug('a-propos'), isTrue);
      expect(isValidPageSlug('livraison2'), isTrue);
      expect(isValidPageSlug('A propos'), isFalse);
      expect(isValidPageSlug('-debut'), isFalse);
      expect(isValidPageSlug(''), isFalse);
    });

    test('domaine personnalisé : normalisation puis validation', () {
      expect(normalizeDomain(' HTTPS://MaBoutique.com/page '), 'maboutique.com');
      expect(normalizeDomain('maboutique.com.'), 'maboutique.com');
      expect(isValidCustomDomain('maboutique.com'), isTrue);
      expect(isValidCustomDomain('boutique.exemple.mr'), isTrue);
      expect(isValidCustomDomain('localhost'), isFalse);
      expect(isValidCustomDomain('espace dans.com'), isFalse);
    });

    test('types de sections : mêmes valeurs que la contrainte SQL', () {
      expect(siteSectionTypes, ['banniere', 'categories_vedettes', 'nouveautes', 'promotions', 'produits_populaires', 'a_propos', 'contact']);
    });
  });
}
