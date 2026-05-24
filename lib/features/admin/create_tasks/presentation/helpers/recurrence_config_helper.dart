import 'package:get/get.dart';

import '../../../../../core/helpers/json_safe_parser.dart';

/// Parsed reminder settings from task details API.
class ParsedTaskReminder {
  const ParsedTaskReminder({required this.when, required this.channel});

  final String when;
  final String channel;
}

/// Builds API recurrence_config matching Laravel EmployeeTaskRecurrenceService.
class RecurrenceConfigHelper {
  static Map<String, dynamic> build({
    required String recurrenceType,
    required String durationType,
    required int endAfterCount,
    required DateTime anchorStart,
    required DateTime anchorEnd,
    DateTime? recurrenceEndDate,
    List<String> weekdays = const [],
    String monthlyMode = 'day_of_month',
    int monthDay = 1,
    String weekdayOrdinal = 'second',
    String weekdayName = 'monday',
    List<int> monthDays = const [],
    int yearlyMonth = 1,
    int yearlyDay = 1,
    String reminderWhen = 'at_time',
    String reminderChannel = 'push',
  }) {
    final cfg = <String, dynamic>{
      'start_time': anchorStart.toIso8601String(),
      'end_time': anchorEnd.toIso8601String(),
      'anchor_date': anchorStart.toIso8601String(),
    };

    if (reminderWhen != 'none') {
      cfg['reminder_before_minutes'] = _reminderMinutes(reminderWhen);
      cfg['reminder_channel'] = reminderChannel;
    }

    if (recurrenceType.isEmpty || recurrenceType == 'noRepeat') {
      return cfg;
    }

    cfg['duration_type'] = durationType;

    if (durationType == 'end_after_count') {
      cfg['end_after_count'] = endAfterCount;
    } else if (durationType == 'end_date' && recurrenceEndDate != null) {
      cfg['end_date'] = recurrenceEndDate.toIso8601String().split('T').first;
    }

    switch (recurrenceType) {
      case 'weekly':
        cfg['weekdays'] = weekdays.map((d) => d.toLowerCase()).toList();
        break;
      case 'monthly':
        if (monthlyMode == 'nth_weekday') {
          cfg['monthly_mode'] = 'nth_weekday';
          cfg['weekday_ordinal'] = weekdayOrdinal;
          cfg['weekday'] = weekdayName.toLowerCase();
        } else {
          cfg['monthly_mode'] = 'dates';
          cfg['month_days'] =
              monthDays.isNotEmpty ? monthDays : [monthDay.clamp(1, 31)];
        }
        break;
      case 'yearly':
        cfg['months'] = [yearlyMonth.clamp(1, 12)];
        cfg['month_days'] = [yearlyDay.clamp(1, 31)];
        break;
      case 'daily':
        cfg['interval'] = 1;
        break;
    }

    return cfg;
  }

  static int _reminderMinutes(String when) {
    switch (when) {
      case 'before_10m':
        return 10;
      case 'before_1h':
        return 60;
      case 'before_1d':
        return 24 * 60;
      default:
        return 0;
    }
  }

  /// Reads reminder from API `recurrence_config` or top-level reminder fields.
  static ParsedTaskReminder parseReminderFromApi(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const ParsedTaskReminder(when: 'none', channel: 'push');
    }

    final topWhen = json['reminder_when']?.toString();
    if (topWhen != null && topWhen.isNotEmpty) {
      return ParsedTaskReminder(
        when: topWhen == 'none' ? 'none' : topWhen,
        channel: json['reminder_channel']?.toString() ?? 'push',
      );
    }

    final cfg = json['recurrence_config'];
    if (cfg is Map) {
      final minutes = cfg['reminder_before_minutes'];
      if (minutes != null) {
        return ParsedTaskReminder(
          when: minutesToWhen(asInt(minutes)),
          channel: cfg['reminder_channel']?.toString() ?? 'push',
        );
      }
    }

    final minutes = json['reminder_before_minutes'];
    if (minutes != null) {
      return ParsedTaskReminder(
        when: minutesToWhen(asInt(minutes)),
        channel: json['reminder_channel']?.toString() ?? 'push',
      );
    }

    return const ParsedTaskReminder(when: 'none', channel: 'push');
  }

  static String minutesToWhen(int minutes) {
    switch (minutes) {
      case 10:
        return 'before_10m';
      case 60:
        return 'before_1h';
      case 1440:
        return 'before_1d';
      case 0:
        return 'at_time';
      default:
        return 'none';
    }
  }

  /// Arabic unit label for duration count field (يوم / يومين / 3 أيام).
  static String countUnitLabel(String recurrenceType, int count) {
    if (Get.locale?.languageCode != 'ar') {
      return count == 1 ? 'unit' : 'units';
    }
    switch (recurrenceType) {
      case 'daily':
        if (count == 1) return 'يوم';
        if (count == 2) return 'يومين';
        if (count >= 3 && count <= 10) return '$count أيام';
        return '$count يومًا';
      case 'weekly':
        if (count == 1) return 'أسبوع';
        if (count == 2) return 'أسبوعين';
        return '$count أسابيع';
      case 'monthly':
        if (count == 1) return 'شهر';
        if (count == 2) return 'شهرين';
        return '$count أشهر';
      case 'yearly':
        if (count == 1) return 'سنة';
        if (count == 2) return 'سنتين';
        return '$count سنوات';
      default:
        return '$count';
    }
  }

  /// Laravel multipart: `recurrence_config[field]` / `recurrence_config[weekdays][0]`.
  static Map<String, dynamic> flattenForRequest(
    Map<String, dynamic> nested, {
    String prefix = 'recurrence_config',
  }) {
    final out = <String, dynamic>{};
    void walk(dynamic value, String path) {
      if (value is Map) {
        value.forEach((k, v) => walk(v, '$path[$k]'));
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          walk(value[i], '$path[$i]');
        }
      } else if (value != null) {
        out[path] = value;
      }
    }
    nested.forEach((k, v) => walk(v, '$prefix[$k]'));
    return out;
  }
}
