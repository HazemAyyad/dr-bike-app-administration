/// Shared recurrence matching for legacy employee tasks (admin + employee apps).
class TaskRecurrenceRules {
  static const weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static bool shouldExpand({
    required String source,
    required String? parentId,
    required String recurrence,
  }) {
    if (source == 'occurrence') return false;
    if (isRepeatedCopy(parentId)) return false;
    final r = recurrence.trim();
    return r.isNotEmpty && r != 'noRepeat';
  }

  static bool isRecurringParent({
    required String source,
    required String? parentId,
    required String recurrence,
  }) =>
      shouldExpand(
        source: source,
        parentId: parentId,
        recurrence: recurrence,
      );

  static bool isRepeatedCopy(String? parentId) {
    if (parentId == null || parentId.isEmpty || parentId == '0') return false;
    return true;
  }

  static bool matchesRecurrenceOnDate({
    required DateTime taskStart,
    required String recurrence,
    required List<String> recurrenceTimes,
    required DateTime day,
    DateTime? taskEnd,
    List<String> weeklyDaysOff = const [],
  }) {
    final anchor = dayStart(taskStart);
    final check = dayStart(day);
    if (check.isBefore(anchor)) return false;
    if (taskEnd != null && check.isAfter(dayStart(taskEnd))) return false;
    if (recurrence == 'daily' && !isEmployeeWorkingDay(check, weeklyDaysOff)) {
      return false;
    }

    switch (recurrence) {
      case 'daily':
        return true;
      case 'weekly':
        final name = weekdays[check.weekday - 1];
        return recurrenceTimes
            .map((e) => e.toLowerCase().trim())
            .contains(name);
      case 'monthly':
        final dayNum = '${check.day}';
        return recurrenceTimes.map((e) => e.trim()).contains(dayNum);
      default:
        return sameDay(taskStart, day);
    }
  }

  static DateTime _local(DateTime d) => d.isUtc ? d.toLocal() : d;

  static DateTime dayStart(DateTime d) {
    final local = _local(d);
    return DateTime(local.year, local.month, local.day);
  }

  static bool sameDay(DateTime a, DateTime b) {
    final al = _local(a);
    final bl = _local(b);
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static String dateKeyFrom(DateTime d) {
    final local = _local(d);
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  static bool isEmployeeWorkingDay(DateTime day, List<String> weeklyDaysOff) {
    if (weeklyDaysOff.isEmpty) return true;
    final name = weekdays[day.weekday - 1];
    final off = weeklyDaysOff.map((e) => e.toLowerCase().trim()).toSet();
    return !off.contains(name);
  }
}
