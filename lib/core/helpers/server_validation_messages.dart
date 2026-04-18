/// يحوّل حقل [errors] القادم من Laravel إلى نص واحد للعرض.
String formatLaravelValidationErrors(Map<String, dynamic>? body) {
  if (body == null) return '';
  final raw = body['errors'];
  if (raw is! Map) return '';
  final buf = StringBuffer();
  raw.forEach((key, value) {
    if (value is List) {
      for (final v in value) {
        buf.writeln('• $key: $v');
      }
    } else {
      buf.writeln('• $key: $value');
    }
  });
  return buf.toString().trim();
}
