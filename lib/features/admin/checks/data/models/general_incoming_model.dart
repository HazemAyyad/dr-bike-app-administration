class GeneralIncomingModel {
  final int incomingChecksCount;
  final String totalIncomingChecks;

  GeneralIncomingModel(
      {required this.incomingChecksCount, required this.totalIncomingChecks});

  factory GeneralIncomingModel.fromJson(Map<String, dynamic> json) {
    return GeneralIncomingModel(
      incomingChecksCount: json['incoming_checks_count'] ?? 0,
      totalIncomingChecks: (json['total_incoming_checks'] ?? '').toString(),
    );
  }
}
