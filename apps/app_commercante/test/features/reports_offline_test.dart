import 'dart:convert';

import 'package:app_commercante/core/db/app_database.dart';
import 'package:app_commercante/core/sync/sync_service.dart';
import 'package:app_commercante/features/documents/data/offline_documents.dart';
import 'package:app_commercante/features/documents/domain/document_payloads.dart';
import 'package:app_commercante/features/expenses/expenses_page.dart';
import 'package:app_commercante/features/reports/domain/report_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportPeriod', () {
    final now = DateTime(2026, 6, 17, 15, 30);

    test('aujourd\'hui, 7 jours glissants et mois en cours', () {
      final today = ReportPeriod.of(ReportPeriodKind.today, now);
      expect((today.startParam, today.endParam), ('2026-06-17', '2026-06-17'));
      final week = ReportPeriod.of(ReportPeriodKind.week, now);
      expect((week.startParam, week.endParam), ('2026-06-11', '2026-06-17'));
      final month = ReportPeriod.of(ReportPeriodKind.month, now);
      expect((month.startParam, month.endParam), ('2026-06-01', '2026-06-17'));
    });

    test('période personnalisée et paramètres des RPC', () {
      final custom = ReportPeriod.of(ReportPeriodKind.custom, now, customStart: DateTime(2026, 1, 5), customEnd: DateTime(2026, 2, 9));
      expect(custom.params('shop-1'), {'p_boutique': 'shop-1', 'p_debut': '2026-01-05', 'p_fin': '2026-02-09'});
    });

    test('axe mode de paiement : valeur attendue par le serveur', () {
      expect(SalesAxis.modePaiement.value, 'mode_paiement');
      expect(SalesAxis.jour.value, 'jour');
    });
  });

  group('lignes et synthèse', () {
    test('ligne de ventes par produit', () {
      final row = ReportRow.fromJson({'cle': 'p1', 'libelle_ar': 'حقيبة', 'libelle_fr': 'Sac', 'nb': 3, 'quantite': '5.000', 'ca': '5000.00', 'marge': 900});
      expect(row.count, 3);
      expect(row.quantity, 5);
      expect(row.revenue, 5000);
      expect(row.margin, 900);
    });

    test('ligne de stock dormant : quantité en stock, valeur, dernière vente', () {
      final row = ReportRow.fromJson({'variante_id': 'v1', 'libelle_fr': 'Foulard', 'en_stock': 3, 'valeur': 150, 'derniere_vente': '2026-04-01T10:00:00Z'});
      expect(row.quantity, 3);
      expect(row.value, 150);
      expect(row.lastSale, isNotNull);
      expect(row.labelAr, 'Foulard');
    });

    test('synthèse : marges absentes sans la permission des coûts', () {
      final summary = ReportSummary.fromJson({'chiffre_affaires': 1000, 'nb_ventes': 1, 'encaisse': 1000, 'depenses': 100, 'marge_brute': null, 'resultat': null, 'valeur_stock': null, 'impayes_clients': 0, 'dettes_fournisseurs': 0});
      expect(summary.revenue, 1000);
      expect(summary.margin, isNull);
      expect(summary.result, isNull);
    });
  });

  group('CSV', () {
    test('séparateur ;, guillemets doublés, BOM et fins de ligne CRLF', () {
      final csv = toCsv(['Nom', 'Total'], [
        ['Sac; grand', 1000],
        ['dit "oui"', 5.5],
      ]);
      expect(csv.startsWith('﻿'), isTrue);
      expect(csv.substring(1), 'Nom;Total\r\n"Sac; grand";1000\r\n"dit ""oui""";5.5\r\n');
    });

    test('protection contre l\'injection de formules (nombres négatifs conservés)', () {
      expect(csvCell('=1+1'), "'=1+1");
      expect(csvCell('@cmd'), "'@cmd");
      expect(csvCell(-5), '-5');
      expect(csvCell(null), '');
    });
  });

  test('charge utile d\'une dépense : identifiant, montant, date et champs facultatifs', () {
    expect(expensePayload(id: 'e1', shopId: 's1', amount: 250, categoryId: 'c1', reason: ' Transport ', date: DateTime(2026, 6, 3)), {
      'id': 'e1',
      'boutique_id': 's1',
      'montant': 250.0,
      'categorie_id': 'c1',
      'motif': 'Transport',
      'date_depense': '2026-06-03',
    });
    final minimal = expensePayload(id: 'e2', shopId: 's1', amount: 10);
    expect(minimal.keys, containsAll(['id', 'boutique_id', 'montant']));
    expect(minimal.containsKey('categorie_id'), isFalse);
    expect(minimal.containsKey('motif'), isFalse);
  });

  group('documents hors ligne', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> cache() => db.setMeta(
          SyncService.recentDocumentsKey('s1'),
          jsonEncode([
            {
              'document': {'id': 'd1', 'type': 'ticket', 'numero': 'TIC-2026-0001', 'statut': 'payee', 'reste': 0, 'total': 1000},
              'lines': [{'id': 'l1', 'quantite': 1, 'total': 1000}],
              'payments': [{'montant': 1000}],
            },
            {
              'document': {'id': 'd2', 'type': 'facture', 'numero': 'FAC-2026-0001', 'statut': 'emise', 'reste': 500, 'total': 500},
              'lines': const [],
              'payments': const [],
            },
            {
              'document': {'id': 'd3', 'type': 'devis', 'numero': 'DEV-2026-0001', 'statut': 'brouillon', 'reste': 300, 'total': 300},
              'lines': const [],
              'payments': const [],
            },
          ]),
        );

    test('sans cache : liste vide et document introuvable', () async {
      final offline = OfflineDocuments(db);
      expect(await offline.list('s1', DocumentFamily.invoices), isEmpty);
      expect(await offline.bundle('s1', 'd1'), isNull);
    });

    test('liste filtrée par famille et par impayés', () async {
      await cache();
      final offline = OfflineDocuments(db);
      expect((await offline.list('s1', DocumentFamily.invoices)).map((d) => d['id']), ['d1', 'd2']);
      expect((await offline.list('s1', DocumentFamily.invoices, unpaidOnly: true)).map((d) => d['id']), ['d2']);
      expect((await offline.list('s1', DocumentFamily.quotes)).map((d) => d['id']), ['d3']);
      expect(await offline.list('autre-boutique', DocumentFamily.invoices), isEmpty);
    });

    test('document reconstitué avec ses lignes et ses paiements', () async {
      await cache();
      final bundle = await OfflineDocuments(db).bundle('s1', 'd1');
      expect(bundle, isNotNull);
      expect(bundle!.type, 'ticket');
      expect(bundle.lines, hasLength(1));
      expect(bundle.payments.single['montant'], 1000);
      expect(bundle.hasActiveDerived, isFalse);
    });
  });

  test('l\'outbox connaît les dépenses et les clientes', () {
    expect(OutboxKind.rpc(OutboxKind.expense), 'enregistrer_depense');
    expect(OutboxKind.rpc(OutboxKind.customer), 'enregistrer_client');
    expect(OutboxKind.params(OutboxKind.expense, {'id': 'x'}), {'p_donnees': {'id': 'x'}});
  });
}
