import 'package:url_launcher/url_launcher.dart';

Future<void> launchWhatsApp({
  required String phoneNumber,
  String message = '',
}) async {
  final normalizedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
  if (normalizedPhone.isEmpty) {
    throw 'Could not launch WhatsApp';
  }
  final uri = Uri.parse(
    'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch WhatsApp';
  }
}

Future<void> launchDialer({required String phoneNumber}) async {
  final uri = Uri.parse('tel:$phoneNumber');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch dialer';
  }
}
