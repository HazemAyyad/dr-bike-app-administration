import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

import '../utils/localized_number.dart';

/// Native attachment sharing stays separate from opening a wa.me text link.
class WhatsAppPdfShare {
  static const channel = MethodChannel('dr_bike/app_launcher');
  static const regular = 'com.whatsapp';
  static const business = 'com.whatsapp.w4b';

  static String phoneDigits(String raw, {String countryCode = '972'}) {
    final normalized = normalizeNumericText(raw).trim();
    var digits = normalized.replaceAll(RegExp(r'\D'), '');
    final international = normalized.startsWith('+') || digits.startsWith('00');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('970') || digits.startsWith('972')) {
      return '$countryCode${digits.substring(3)}';
    }
    if (international) return digits;
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.isEmpty ? '' : '$countryCode$digits';
  }

  static Future<List<String>> installedApps() async {
    if (defaultTargetPlatform != TargetPlatform.android) return const [];
    return (await channel.invokeListMethod<String>('whatsAppApps')) ?? const [];
  }

  static Future<bool> share(
      {required Uint8List bytes,
      required String filename,
      required String packageName,
      required String phone}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return await channel.invokeMethod<bool>('shareWhatsAppPdf', {
          'bytes': bytes,
          'filename': filename,
          'package': packageName,
          'phone': phone,
        }) ??
        false;
  }
}
