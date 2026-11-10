import 'package:url_launcher/url_launcher.dart';

/// Ouvre WhatsApp avec un message pré-rempli (vers un numéro, ou la liste des conversations si null).
Future<bool> openWhatsapp(String? phone, String message) {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  final uri = digits.length >= 8
      ? Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}')
      : Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> callPhone(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

Future<bool> openUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
