import 'dart:convert';

import 'smart_home_api_service.dart';

class TuyaDeviceFunction {
  const TuyaDeviceFunction({
    required this.dpId,
    required this.code,
    required this.name,
    required this.type,
    required this.mode,
    required this.values,
  });

  final String dpId;
  final String code;
  final String name;
  final String type;
  final String mode;
  final Map<String, dynamic> values;

  bool get writable => mode.toLowerCase().contains('w');
  bool get readable => mode.toLowerCase().contains('r');
  bool get isBool => type.toLowerCase() == 'bool';
  bool get isEnum => type.toLowerCase() == 'enum';
  bool get isValue => type.toLowerCase() == 'value';
  bool get isString => type.toLowerCase() == 'string';

  Map<String, dynamic> toLogValue(dynamic value) => {
        'value': value,
        'dp_id': dpId,
        'code': code,
        'type': type,
        'mode': mode,
      };
}

class TuyaValidatedCommand {
  const TuyaValidatedCommand({required this.function, required this.value});

  final TuyaDeviceFunction function;
  final dynamic value;

  Map<String, dynamic> get dps => {function.dpId: value};

  Map<String, dynamic> toLogValue() => {
        ...function.toLogValue(value),
        'dps': dps,
        'submitted_value_type': value.runtimeType.toString(),
      };
}

class TuyaValidationResult {
  const TuyaValidationResult._({
    required this.valid,
    this.value,
    this.message = '',
  });

  final bool valid;
  final dynamic value;
  final String message;

  factory TuyaValidationResult.ok(dynamic value) =>
      TuyaValidationResult._(valid: true, value: value);

  factory TuyaValidationResult.error(String message) =>
      TuyaValidationResult._(valid: false, message: message);
}

class DeviceCapabilityResolver {
  const DeviceCapabilityResolver._();

  static List<TuyaDeviceFunction> functions(SmartDeviceModel device) {
    final functions = <TuyaDeviceFunction>[];
    _schemaEntries(device.rawMetadata).forEach((key, raw) {
      if (raw is! Map) return;
      final dpId = (raw['id']?.toString().trim().isNotEmpty == true)
          ? raw['id'].toString().trim()
          : key.toString().trim();
      final code = raw['code']?.toString().trim() ?? '';
      if (dpId.isEmpty || code.isEmpty) return;
      final values = _decodeValues(raw['property']);
      functions.add(
        TuyaDeviceFunction(
          dpId: dpId,
          code: code,
          name: raw['name']?.toString().trim() ?? '',
          type: _dataType(raw, values),
          mode: raw['mode']?.toString().trim() ?? '',
          values: values,
        ),
      );
    });
    functions.sort((a, b) {
      final ai = int.tryParse(a.dpId);
      final bi = int.tryParse(b.dpId);
      if (ai != null && bi != null) return ai.compareTo(bi);
      return a.dpId.compareTo(b.dpId);
    });
    return functions;
  }

  static Map<dynamic, dynamic> _schemaEntries(Map<String, dynamic> metadata) {
    final schemaMap = metadata['schema_map'];
    if (schemaMap is Map && schemaMap.isNotEmpty) return schemaMap;
    if (schemaMap is List && schemaMap.isNotEmpty) {
      return {
        for (final raw in schemaMap)
          if (raw is Map && raw['id'] != null) raw['id'].toString(): raw,
      };
    }

    final schema = metadata['schema'];
    final decoded = schema is String ? _decodeJson(schema) : schema;
    if (decoded is List) {
      return {
        for (final raw in decoded)
          if (raw is Map && raw['id'] != null) raw['id'].toString(): raw,
      };
    }
    if (decoded is Map) return decoded;
    return const <dynamic, dynamic>{};
  }

  static dynamic _decodeJson(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static String _dataType(Map raw, Map<String, dynamic> values) {
    final propertyType = values['type']?.toString().trim() ?? '';
    if (propertyType.isNotEmpty) return propertyType;
    final type = raw['type']?.toString().trim() ?? '';
    return type.toLowerCase() == 'obj' ? '' : type;
  }

  static List<TuyaDeviceFunction> writableFunctions(SmartDeviceModel device) =>
      functions(device).where((item) => item.writable).toList(growable: false);

  static List<TuyaDeviceFunction> boolSwitches(SmartDeviceModel device) =>
      writableFunctions(device)
          .where((item) => item.isBool && _looksLikePowerCode(item.code))
          .toList(growable: false);

  static TuyaDeviceFunction? resolvePower(SmartDeviceModel device) {
    final preferred = boolSwitches(device);
    if (preferred.isNotEmpty) return preferred.first;
    final bools = writableFunctions(device)
        .where((item) => item.isBool)
        .toList(growable: false);
    return bools.isNotEmpty ? bools.first : null;
  }

  static TuyaDeviceFunction? resolve(
    SmartDeviceModel device,
    String codeOrDpId,
  ) {
    final clean = codeOrDpId.trim();
    if (clean.isEmpty) return null;
    for (final item in writableFunctions(device)) {
      if (item.code == clean || item.dpId == clean) return item;
    }
    return null;
  }

  static dynamic statusValue(
    SmartDeviceModel device,
    TuyaDeviceFunction function,
  ) {
    final status = _mergedStatus(device);
    final intDpId = int.tryParse(function.dpId);
    if (status.containsKey(function.dpId)) {
      return status[function.dpId];
    }
    if (intDpId != null && status.containsKey(intDpId)) {
      return status[intDpId];
    }
    if (status.containsKey(function.code)) {
      return status[function.code];
    }
    return null;
  }

  static Map<dynamic, dynamic> _mergedStatus(SmartDeviceModel device) {
    final status = <dynamic, dynamic>{};
    final metadataStatus = device.rawMetadata['last_status'];
    if (metadataStatus is Map) status.addAll(metadataStatus);
    status.addAll(device.lastStatus);
    return status;
  }

  static TuyaValidationResult validate(
    TuyaDeviceFunction function,
    dynamic submittedValue,
  ) {
    if (!function.writable) {
      return TuyaValidationResult.error(
        'DP ${function.dpId} (${function.code}) is not writable',
      );
    }

    if (function.isBool) {
      if (submittedValue is bool) {
        return TuyaValidationResult.ok(submittedValue);
      }
      return TuyaValidationResult.error(
        'Expected boolean for ${function.code}, got ${submittedValue.runtimeType}',
      );
    }

    if (function.isEnum) {
      final value = submittedValue.toString();
      final range = function.values['range'];
      if (range is List &&
          range.map((item) => item.toString()).contains(value)) {
        return TuyaValidationResult.ok(value);
      }
      return TuyaValidationResult.error(
        'Invalid enum value "$value" for ${function.code}',
      );
    }

    if (function.isValue) {
      final number = submittedValue is num
          ? submittedValue
          : num.tryParse(submittedValue.toString());
      if (number == null) {
        return TuyaValidationResult.error(
          'Expected numeric value for ${function.code}',
        );
      }
      final min = _numValue(function.values['min']);
      final max = _numValue(function.values['max']);
      final step = _numValue(function.values['step']);
      if (min != null && number < min) {
        return TuyaValidationResult.error('${function.code} is below min $min');
      }
      if (max != null && number > max) {
        return TuyaValidationResult.error('${function.code} is above max $max');
      }
      if (step != null && step > 0 && min != null) {
        final offset = (number - min) / step;
        if ((offset - offset.round()).abs() > 0.000001) {
          return TuyaValidationResult.error(
            '${function.code} must match step $step',
          );
        }
      }
      return TuyaValidationResult.ok(number is int ? number : number.round());
    }

    if (function.isString) {
      return submittedValue is String
          ? TuyaValidationResult.ok(submittedValue)
          : TuyaValidationResult.error(
              'Expected string value for ${function.code}',
            );
    }

    return TuyaValidationResult.error(
      'Unsupported Tuya DP type ${function.type} for ${function.code}',
    );
  }

  static Map<String, dynamic> debugSummary(SmartDeviceModel device) => {
        'device_id': device.tuyaDeviceId,
        'product_id': device.tuyaProductId,
        'category': device.category,
        'current_dps': device.lastStatus,
        'functions': functions(device)
            .map(
              (item) => {
                'dp_id': item.dpId,
                'code': item.code,
                'type': item.type,
                'mode': item.mode,
                'values': item.values,
              },
            )
            .toList(growable: false),
      };

  static Map<String, dynamic> _decodeValues(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is! String || raw.trim().isEmpty) return const <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
    } catch (_) {
      return {'raw': raw};
    }
  }

  static bool _looksLikePowerCode(String code) {
    final clean = code.toLowerCase();
    return clean == 'switch' ||
        (clean.startsWith('switch_') &&
            clean != 'switch_backlight' &&
            clean != 'switch_inching') ||
        clean == 'switch_led' ||
        clean == 'power' ||
        clean.startsWith('power_');
  }

  static num? _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}
