class DebtLedgerLabelPair {
  final String taken;
  final String given;

  const DebtLedgerLabelPair({this.taken = 'أخذت', this.given = 'أعطيت'});

  factory DebtLedgerLabelPair.fromJson(Map json,
      {DebtLedgerLabelPair fallback = const DebtLedgerLabelPair()}) {
    String label(String key, String defaultValue) {
      final value = json[key]?.toString().trim() ?? '';
      return value.isEmpty ? defaultValue : value;
    }

    return DebtLedgerLabelPair(
      taken: label('taken_label', fallback.taken),
      given: label('given_label', fallback.given),
    );
  }

  Map<String, String> toJson() => {'taken_label': taken, 'given_label': given};
}

class DebtLedgerLabels {
  final DebtLedgerLabelPair general;
  final Map<String, DebtLedgerLabelPair> byType;

  const DebtLedgerLabels({
    this.general = const DebtLedgerLabelPair(),
    this.byType = const {},
  });

  factory DebtLedgerLabels.fromJson(Map json) {
    final general = DebtLedgerLabelPair.fromJson(json);
    final scopes = json['by_type'];
    return DebtLedgerLabels(
      general: general,
      byType: scopes is Map
          ? {
              for (final entry in scopes.entries)
                if (entry.value is Map)
                  entry.key.toString(): DebtLedgerLabelPair.fromJson(
                    entry.value as Map,
                    fallback: general,
                  ),
            }
          : const {},
    );
  }

  DebtLedgerLabelPair forScope(String scope) => byType[scope] ?? general;
}
