import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
    final j = Map<String, dynamic>.from(json);
    return GeneralOutgoingDataModel(
      outgoingChecksCount: asInt(j['outgoing_checks_count']),
      totalOutgoingChecks: asDouble(j['total_outgoing_checks']),
      totalBoxes: asDouble(j['total_boxes']),
      coveragePercentage: asDouble(j['coverage_percentage']),
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
