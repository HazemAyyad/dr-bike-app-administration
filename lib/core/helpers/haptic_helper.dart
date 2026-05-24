import 'package:flutter/services.dart';

/// Reliable short haptic on physical devices (emulators often silent).
class HapticHelper {
  static void selection() {
    try {
      HapticFeedback.selectionClick();
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void confirm() {
    try {
      HapticFeedback.mediumImpact();
      HapticFeedback.vibrate();
    } catch (_) {}
  }
}
