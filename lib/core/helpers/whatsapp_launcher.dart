import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static const MethodChannel _channel = MethodChannel('dr_bike/app_launcher');

  static List<String> numberCandidates(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('970') || digits.startsWith('972')) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.isEmpty) return const [];
    return ['972$digits', '970$digits'];
  }

  static Future<bool> openChat(String phoneDigits) async {
    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>(
          'openWhatsApp',
          {'phone': phoneDigits},
        );
        if (opened == true) return true;
      } on PlatformException {
        // Fall through to the universal link on unsupported Android builds.
      } on MissingPluginException {
        // Supports hot reload against an app binary built before this channel.
      }
    }

    return launchUrl(
      Uri.https('wa.me', '/$phoneDigits'),
      mode: LaunchMode.externalApplication,
    );
  }
}
