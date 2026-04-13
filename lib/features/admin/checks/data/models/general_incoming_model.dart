import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class GeneralIncomingModel {
  final int incomingChecksCount;
  final String totalIncomingChecks;

  GeneralIncomingModel({
    required this.incomingChecksCount,
    required this.totalIncomingChecks,
  });

  factory GeneralIncomingModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return GeneralIncomingModel(
      incomingChecksCount: asInt(j['incoming_checks_count']),
      totalIncomingChecks: asString(j['total_incoming_checks']),
    );
  }
}
