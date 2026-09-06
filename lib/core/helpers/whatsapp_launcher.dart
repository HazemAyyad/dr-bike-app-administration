import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static const MethodChannel _channel = MethodChannel('dr_bike/app_launcher');

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
