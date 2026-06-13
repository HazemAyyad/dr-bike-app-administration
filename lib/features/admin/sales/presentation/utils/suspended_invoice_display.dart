import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Formats suspended-at timestamp for list display (date + 12h time).
String formatSuspendedInvoiceDateTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';

  try {
    final normalized = raw.trim().replaceFirst(' ', 'T');
    final dt = DateTime.parse(normalized);
    final local = dt.toLocal();
    final locale = Get.locale?.languageCode ?? 'ar';

    final datePart = DateFormat('d/M/y', locale).format(local);
    final timePart = DateFormat('hh:mm a', locale).format(local);

    return '$datePart\n$timePart';
  } catch (_) {
    return raw;
  }
}
