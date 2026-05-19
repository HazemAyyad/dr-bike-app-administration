import 'package:flutter/foundation.dart';

/// Temporary navigation debug for Employee Tasks module.
class TaskNavDebug {
  static void log(String source, String route, {String? screen, Map? extra}) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('[TaskNavDebug] source=$source route=$route');
    if (screen != null) buffer.write(' screen=$screen');
    if (extra != null && extra.isNotEmpty) {
      buffer.write(' extra=$extra');
    }
    debugPrint(buffer.toString());
  }
}
