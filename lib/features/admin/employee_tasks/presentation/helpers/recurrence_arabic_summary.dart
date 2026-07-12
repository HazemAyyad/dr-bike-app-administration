import 'package:get/get.dart';

import '../../../create_tasks/presentation/helpers/recurrence_config_helper.dart';

/// Human-readable Arabic recurrence summaries (never raw API enums).
class RecurrenceArabicSummary {
  static const _weekdayAr = {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الإثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
  };

  static const _ordinalAr = {
    'first': 'الأول',
    'second': 'الثاني',
    'third': 'الثالث',
    'fourth': 'الرابع',
    'last': 'الأخير',
  };

  static String build({
    required String recurrenceType,
    List<String> weekdays = const [],
    String durationType = 'forever',
    int endAfterCount = 0,
    String? endDate,
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
    if (recurrenceType.isEmpty || recurrenceType == 'noRepeat') {
      return 'recurrenceSummaryNoRepeat'.tr;
    }

    if (recurrenceType == 'oneTimePersistent') {
      return 'recurrenceSummaryOneTimePersistent'.tr;
    }

    final parts = <String>[_typeLabel(recurrenceType)];

    if (recurrenceType == 'weekly' && weekdays.isNotEmpty) {
      parts.add(_weekdaysPhrase(weekdays));
    }
    if (recurrenceType == 'monthly') {
      parts.add(_monthlyPhrase(
        monthlyMode,
        monthDay,
        weekdayOrdinal,
        weekdayName,
        monthDays,
      ));
    }
    if (recurrenceType == 'yearly') {
      parts.add('recurrenceYearlyOn'.trParams({
        'day': '$yearlyDay',
        'month': '$yearlyMonth',
      }));
    }

    if (durationType != 'forever') {
      parts.add(_durationPhrase(
          recurrenceType, durationType, endAfterCount, endDate));
    }

    if (reminderWhen != 'none') {
      parts.add(_reminderPhrase(reminderWhen, reminderChannel));
    }

    return 'recurrenceSummaryPrefix'.trParams({'details': parts.join(' · ')});
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'daily':
        return 'recurrenceTypeDaily'.tr;
      case 'weekly':
        return 'recurrenceTypeWeekly'.tr;
      case 'monthly':
        return 'recurrenceTypeMonthly'.tr;
      case 'yearly':
        return 'recurrenceTypeYearly'.tr;
      case 'oneTimePersistent':
        return 'recurrenceTypeOneTimePersistent'.tr;
      default:
        return 'recurrenceTypeDaily'.tr;
    }
  }

  static String _weekdaysPhrase(List<String> days) {
    final names = days.map((d) => _weekdayAr[d.toLowerCase()] ?? d).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) {
      return 'recurrenceOnDay'.trParams({'day': names.first});
    }
    final last = names.removeLast();
    return 'recurrenceOnDays'.trParams({
      'days': '${names.join('، ')} و$last',
    });
  }

  static String _monthlyPhrase(
    String mode,
    int day,
    String ordinal,
    String weekday,
    List<int> days,
  ) {
    if (mode == 'nth_weekday') {
      final ord = _ordinalAr[ordinal] ?? ordinal;
      final wd = _weekdayAr[weekday.toLowerCase()] ?? weekday;
      return 'recurrenceMonthlyNth'.trParams({'ordinal': ord, 'day': wd});
    }
    if (mode == 'custom_dates' && days.isNotEmpty) {
      final sorted = [...days]..sort();
      return 'recurrenceMonthlyDays'.trParams({
        'days': sorted.map((d) => '$d').join('، '),
      });
    }
    return 'recurrenceMonthlyDay'.trParams({'day': '$day'});
  }

  static String _durationPhrase(
    String recurrenceType,
    String durationType,
    int count,
    String? endDate,
  ) {
    if (durationType == 'end_date') {
      if (endDate != null && endDate.isNotEmpty) {
        return 'recurrenceUntilDate'.trParams({'date': endDate});
      }
      return 'recurrenceUntilDateUnknown'.tr;
    }
    if (durationType == 'end_after_count' && count > 0) {
      final unit = RecurrenceConfigHelper.countUnitLabel(recurrenceType, count);
      return 'recurrenceUntilCountUnit'
          .trParams({'count': '$count', 'unit': unit});
    }
    return 'recurrenceForever'.tr;
  }

  static String _reminderPhrase(String when, String channel) {
    if (when == 'none') return '';
    final whenLabel = {
          'at_time': 'reminderAtTime'.tr,
          'before_10m': 'reminderBefore10m'.tr,
          'before_1h': 'reminderBefore1h'.tr,
          'before_1d': 'reminderBefore1d'.tr,
        }[when] ??
        'reminderAtTime'.tr;
    final ch = channel == 'email' ? 'reminderEmail'.tr : 'reminderPush'.tr;
    return '$whenLabel ($ch)';
  }
}
