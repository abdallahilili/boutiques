import 'dart:ui';

import 'package:intl/intl.dart';

/// Nom localisé avec repli sur l'autre langue (nom_ar / nom_fr sont facultatifs en base).
String localName(String? ar, String? fr, {required bool arabic}) {
  final first = arabic ? ar : fr;
  final second = arabic ? fr : ar;
  if (first != null && first.trim().isNotEmpty) return first;
  return (second != null && second.trim().isNotEmpty) ? second : '—';
}

/// Montant dans la devise de la boutique : chiffres occidentaux (lecture sûre en caisse), MRU sans décimales.
String formatMoney(num value, {required String currency, int? decimals}) {
  final digits = decimals ?? (currency == 'MRU' ? 0 : 2);
  final pattern = digits == 0 ? '#,##0' : '#,##0.${'0' * digits}';
  return '${NumberFormat(pattern, 'en').format(value)} $currency';
}

/// Quantité sans décimales inutiles (3 → « 3 », 2.5 → « 2.5 »).
String formatQuantity(num value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

/// Remplace les chiffres arabo-indiens (٠-٩) et persans (۰-۹) par 0-9 : l'application affiche toujours des chiffres occidentaux.
String westernDigits(String text) => text.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
      final c = m[0]!.codeUnitAt(0);
      return String.fromCharCode(0x30 + (c >= 0x06F0 ? c - 0x06F0 : c - 0x0660));
    });

String formatDate(DateTime value, Locale locale, {bool time = false}) {
  final tag = locale.languageCode;
  return westernDigits((time ? DateFormat.yMd(tag).add_Hm() : DateFormat.yMd(tag)).format(value.toLocal()));
}

/// Lit un nombre renvoyé par PostgREST (int, double ou chaîne numérique).
double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

/// Saisie utilisateur (virgule ou point, chiffres arabo-indiens acceptés) → nombre.
double? parseAmount(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  var text = input.trim().replaceAll(',', '.').replaceAll('٫', '.');
  for (var i = 0; i < arabic.length; i++) {
    text = text.replaceAll(arabic[i], '$i');
  }
  return double.tryParse(text);
}
