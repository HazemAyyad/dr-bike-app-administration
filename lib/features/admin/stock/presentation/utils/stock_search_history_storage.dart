import 'dart:convert';

import '../../../../../core/services/final_classes.dart';

class StockSearchHistoryStorage {
  StockSearchHistoryStorage._();

  static const int maxItems = 10;
  static const int minQueryLength = 2;
  static const String _keyPrefix = 'stock_search_history_v1';

  static String _storageKey() {
    for (final source in [
      FinalClasses.getStorage.read('userData_backup'),
      FinalClasses.getStorage.read('userData'),
    ]) {
      if (source == null) continue;
      try {
        final map = jsonDecode(source.toString()) as Map<String, dynamic>;
        final id = map['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) return '${_keyPrefix}_$id';
      } catch (_) {}
    }
    return _keyPrefix;
  }

  static List<String> load() {
    final raw = FinalClasses.getStorage.read(_storageKey());
    if (raw is! List) return [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.length >= minQueryLength)
        .take(maxItems)
        .toList();
  }

  static Future<void> save(List<String> items) async {
    await FinalClasses.getStorage.write(
      _storageKey(),
      items.take(maxItems).toList(),
    );
  }
}
