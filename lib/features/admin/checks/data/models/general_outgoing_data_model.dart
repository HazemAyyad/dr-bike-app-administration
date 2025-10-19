class GeneralOutgoingDataModel {
  final int outgoingChecksCount;
  final double totalOutgoingChecks;
  final double totalBoxes;
  final double coveragePercentage;

  GeneralOutgoingDataModel({
    required this.outgoingChecksCount,
    required this.totalOutgoingChecks,
    required this.totalBoxes,
    required this.coveragePercentage,
  });

  factory GeneralOutgoingDataModel.fromJson(Map<String, dynamic> json) {
    return GeneralOutgoingDataModel(
      outgoingChecksCount: json['outgoing_checks_count'] ?? 0,
      totalOutgoingChecks:
          double.tryParse(json['total_outgoing_checks'].toString()) ?? 0.0,
      totalBoxes: double.tryParse(json['total_boxes'].toString()) ?? 0.0,
      coveragePercentage:
          (json['coverage_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outgoing_checks_count': outgoingChecksCount,
      'total_outgoing_checks': totalOutgoingChecks,
      'total_boxes': totalBoxes,
      'coverage_percentage': coveragePercentage,
    };
  }
}
