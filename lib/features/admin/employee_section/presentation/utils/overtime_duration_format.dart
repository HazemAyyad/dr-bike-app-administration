import 'package:get/get.dart';

String formatOvertimeMinutes(int totalMinutes) {
  final safeMinutes = totalMinutes < 0 ? 0 : totalMinutes;
  final hours = safeMinutes ~/ 60;
  final minutes = safeMinutes % 60;

  if (hours > 0 && minutes > 0) {
    return 'overtimeDurationHoursMinutes'.trParams({
      'hours': '$hours',
      'minutes': '$minutes',
    });
  }
  if (hours > 0) {
    return 'overtimeDurationHours'.trParams({'hours': '$hours'});
  }
  return 'overtimeDurationMinutes'.trParams({'minutes': '$minutes'});
}

String formatOvertimeDecimalHours(String? rawValue) {
  final value = double.tryParse((rawValue ?? '').replaceAll(',', '.')) ?? 0;
  return formatOvertimeMinutes((value * 60).round());
}
