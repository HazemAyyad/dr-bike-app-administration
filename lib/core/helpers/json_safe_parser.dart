// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

/// تحليل JSON دفاعي موحّد لاستجابات Laravel (أنواع مختلطة: int/double/String/bool/null).
String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? asNullableString(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double asDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes' || v == 'active') return true;
    if (v == 'false' || v == '0' || v == 'no' || v == 'inactive') return false;
  }
  return fallback;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

List<T> mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) builder,
) {
  return asMapList(value).map(builder).toList();
}

/// تواريخ API: غالباً ISO string؛ نادراً timestamp رقمي.
DateTime parseApiDateTime(dynamic value, [DateTime? fallback]) {
  final fb = fallback ?? DateTime.now();
  if (value == null) return fb;
  if (value is String) {
    final d = DateTime.tryParse(value);
    return d ?? fb;
  }
  if (value is int) {
    if (value < 2000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return fb;
}

/// يزيل غلاف `data` إن وُجد (كائن واحد).
Map<String, dynamic> unwrapDataEnvelope(Map<String, dynamic> json) {
  final nested = json['data'];
  if (nested is Map) {
    final m = Map<String, dynamic>.from(nested);
    if (json.containsKey('status')) m['status'] = json['status'];
    if (json.containsKey('message')) m['message'] = json['message'];
    return m;
  }
  return Map<String, dynamic>.from(json);
}

/// يحاول استخراج قائمة من مفاتيح شائعة.
List<Map<String, dynamic>> readListFromKnownKeys(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final k in keys) {
    final v = json[k];
    if (v is List && v.isNotEmpty) {
      return asMapList(v);
    }
    if (v is List) {
      return [];
    }
  }
  return [];
}

/// Alias لـ [readListFromKnownKeys] (تسمية موحّدة في المشروع).
List<Map<String, dynamic>> mapListFromKnownKeys(
  Map<String, dynamic> json,
  List<String> keys,
) =>
    readListFromKnownKeys(json, keys);

/// يحاول استخراج كائن Map من أول مفتاح موجود وقيمته Map.
Map<String, dynamic> mapObjectFromKnownKeys(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final k in keys) {
    final v = json[k];
    if (v is Map) {
      return Map<String, dynamic>.from(v);
    }
  }
  return <String, dynamic>{};
}

void debugParseLog(String scope, String message) {
  if (kDebugMode) {
    debugPrint('[$scope] $message');
  }
}

/// يستخرج قائمة خرائط من استجابة API بأشكال متعددة:
/// قائمة جذر، `{ key: [...] }`, `{ data: [...] }`, `{ data: { key: [...] } }`.
List<Map<String, dynamic>> extractMapListFromResponse(
  dynamic responseData,
  String primaryKey,
) {
  if (responseData is List) {
    return asMapList(responseData);
  }
  if (responseData is! Map) {
    debugParseLog(
      'extractMapListFromResponse',
      'expected Map or List, got ${responseData.runtimeType} key=$primaryKey',
    );
    return [];
  }
  final m = Map<String, dynamic>.from(responseData);

  var v = m[primaryKey];
  if (v is List) return asMapList(v);

  final data = m['data'];
  if (data is List) return asMapList(data);
  if (data is Map) {
    final dm = Map<String, dynamic>.from(data);
    v = dm[primaryKey];
    if (v is List) return asMapList(v);
  }

  return readListFromKnownKeys(m, [primaryKey, 'items', 'results']);
}

/// يستخرج قائمة من `response.data` عبر [key] ويُحوّلها بـ [builder] بأمان.
List<T> mapListFromResponseKey<T>(
  dynamic responseData,
  String key,
  T Function(Map<String, dynamic>) builder, {
  String? debugScope,
}) {
  final list = extractMapListFromResponse(responseData, key);
  final out = <T>[];
  for (var i = 0; i < list.length; i++) {
    final m = list[i];
    try {
      out.add(builder(m));
    } catch (e, _) {
      final fieldTypes = m.map(
        (k, v) => MapEntry(k.toString(), v.runtimeType.toString()),
      );
      debugParseLog(
        debugScope ?? 'mapListFromResponseKey',
        'modelMap key=$key index=$i err=$e rawItem=$m fieldTypes=$fieldTypes',
      );
    }
  }
  return out;
}
