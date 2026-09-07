String formatSocialClock(DateTime? value) {
  if (value == null) return '';
  final date = value.toLocal();
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'ص' : 'م';
  return '$hour:$minute $period';
}

String formatSocialConversationStamp(DateTime? value, {DateTime? now}) {
  if (value == null) return '';
  final date = value.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final difference = _dateOnly(current).difference(_dateOnly(date)).inDays;

  if (difference == 0) return formatSocialClock(date);
  if (difference == 1) return 'أمس';
  return '${date.day}/${date.month}/${_twoDigitYear(date.year)}';
}

String formatSocialDayDivider(DateTime? value, {DateTime? now}) {
  if (value == null) return '';
  final date = value.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final difference = _dateOnly(current).difference(_dateOnly(date)).inDays;

  if (difference == 0) return 'اليوم';
  if (difference == 1) return 'أمس';
  return '${_arabicWeekday(date.weekday)}، ${date.day}/${date.month}/${date.year}';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _twoDigitYear(int year) => year.toString().padLeft(4, '0').substring(2);

String _arabicWeekday(int weekday) => const <String>[
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ][weekday - 1];
