import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../documents/domain/invoice_data.dart';
import 'receipt_renderer.dart';

/// Échec d'impression exploitable par l'écran (message traduit côté interface).
enum PrintFailure { unsupported, noPrinter, bluetoothOff, permission, connection, write }

class PrintException implements Exception {
  const PrintException(this.failure);

  final PrintFailure failure;

  @override
  String toString() => 'PrintException($failure)';
}

/// Imprimante thermique Bluetooth (profil série) : choix de l'imprimante appairée, largeur du papier,
/// impression des documents en image (arabe et français sans page de codes).
class ThermalPrinterService extends GetxService {
  ThermalPrinterService(this._prefs);

  final SharedPreferences _prefs;

  static const _macKey = 'imprimante_mac';
  static const _nameKey = 'imprimante_nom';
  static const _paperKey = 'imprimante_papier';

  final printerName = RxnString();
  final paperMm = 58.obs;

  @override
  void onInit() {
    super.onInit();
    printerName.value = _prefs.getString(_nameKey);
    paperMm.value = _prefs.getInt(_paperKey) ?? 58;
  }

  /// L'impression Bluetooth série n'est proposée que sur Android.
  bool get supported => Platform.isAndroid;

  String? get printerMac => _prefs.getString(_macKey);

  bool get hasPrinter => printerMac != null;

  Future<void> choose(String mac, String name) async {
    await _prefs.setString(_macKey, mac);
    await _prefs.setString(_nameKey, name);
    printerName.value = name;
  }

  Future<void> forget() async {
    await _prefs.remove(_macKey);
    await _prefs.remove(_nameKey);
    printerName.value = null;
  }

  Future<void> setPaper(int millimeters) async {
    paperMm.value = millimeters >= 80 ? 80 : 58;
    await _prefs.setInt(_paperKey, paperMm.value);
  }

  /// Imprimantes déjà appairées dans les réglages Bluetooth du téléphone.
  Future<List<BluetoothInfo>> pairedPrinters() async {
    if (!supported) throw const PrintException(PrintFailure.unsupported);
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) throw const PrintException(PrintFailure.permission);
    if (!await PrintBluetoothThermal.bluetoothEnabled) throw const PrintException(PrintFailure.bluetoothOff);
    return PrintBluetoothThermal.pairedBluetooths;
  }

  Future<void> _ensureConnected() async {
    if (!supported) throw const PrintException(PrintFailure.unsupported);
    final mac = printerMac;
    if (mac == null) throw const PrintException(PrintFailure.noPrinter);
    if (!await PrintBluetoothThermal.isPermissionBluetoothGranted) throw const PrintException(PrintFailure.permission);
    if (!await PrintBluetoothThermal.bluetoothEnabled) throw const PrintException(PrintFailure.bluetoothOff);
    if (await PrintBluetoothThermal.connectionStatus) return;
    if (!await PrintBluetoothThermal.connect(macPrinterAddress: mac)) throw const PrintException(PrintFailure.connection);
  }

  Future<void> _send(Uint8List bytes) async {
    await _ensureConnected();
    // Envoi par blocs : les petites imprimantes ont un tampon limité.
    const chunk = 2048;
    for (var i = 0; i < bytes.length; i += chunk) {
      final end = i + chunk > bytes.length ? bytes.length : i + chunk;
      if (!await PrintBluetoothThermal.writeBytes(bytes.sublist(i, end))) throw const PrintException(PrintFailure.write);
    }
  }

  /// Imprime un document de vente (ticket, facture, devis, bon de livraison, avoir).
  Future<void> printInvoice(InvoiceData invoice, {required bool arabic, Uint8List? logo}) async =>
      _send(await buildReceiptEscPos(invoice, arabic: arabic, paperMm: paperMm.value, logo: logo));

  /// Ticket d'essai : vérifie la connexion, la largeur du papier et le rendu de l'arabe.
  Future<void> printTest({required bool arabic}) async {
    final sample = InvoiceData(
      type: 'ticket',
      number: 'TEST-0001',
      date: DateTime.now(),
      shopNameAr: 'متجري',
      shopNameFr: 'Ma boutique',
      currency: 'MRU',
      lines: const [InvoiceLine(labelAr: 'منتج تجريبي', labelFr: 'Article de test', quantity: 2, unitPrice: 500, discount: 0, total: 1000)],
      payments: const [InvoicePayment(nameAr: 'نقداً', nameFr: 'Espèces', amount: 1000)],
      subtotal: 1000,
      discount: 0,
      total: 1000,
    );
    await printInvoice(sample, arabic: arabic);
  }
}
