import 'package:intl/intl.dart';

/// Parses employee shift times from API strings (12h or 24h) for today.
class AttendanceTimeParser {
  AttendanceTimeParser._();

  static DateTime? parseToday(String timeStr) {
    return parseOnDate(timeStr, DateTime.now());
  }

  static DateTime? parseOnDate(String timeStr, DateTime date) {
    final raw = timeStr.trim();
    if (raw.isEmpty || raw == '0') return null;

    try {
      late DateFormat fmt;
      final upper = raw.toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        fmt = DateFormat('h:mm a', 'en_US');
      } else if (raw.split(':').length >= 3) {
        fmt = DateFormat('HH:mm:ss');
      } else {
        fmt = DateFormat('HH:mm');
      }
      final parsed = fmt.parse(raw);
      return DateTime(
        date.year,
        date.month,
        date.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );
    } catch (_) {
      return null;
    }
  }

  static String formatDurationHms(Duration d) {
    final total = d.isNegative ? Duration.zero : d;
    final h = total.inHours.toString().padLeft(2, '0');
    final m = (total.inMinutes % 60).toString().padLeft(2, '0');
    final s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
