import 'package:doctorbike/features/admin/checks/domain/entity/general_checks_data_entity.dart';

class GeneralChecksDataModel extends GeneralChecksDataEntity {
  const GeneralChecksDataModel({
    required int outgoingChecksCount,
    required int incomingChecksCount,
    required String totalOutgoingChecks,
    required String totalIncomingChecks,
  }) : super(
          outgoingChecksCount: outgoingChecksCount,
          incomingChecksCount: incomingChecksCount,
          totalOutgoingChecks: totalOutgoingChecks,
          totalIncomingChecks: totalIncomingChecks,
        );

  factory GeneralChecksDataModel.fromJson(Map<String, dynamic> json) {
    return GeneralChecksDataModel(
      outgoingChecksCount: json['outgoing_checks_count'] ?? 0,
      incomingChecksCount: json['incoming_checks_count'] ?? 0,
      totalOutgoingChecks: (json['total_outgoing_checks'] ?? 0).toString(),
      totalIncomingChecks: (json['total_incoming_checks'] ?? 0).toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outgoing_checks_count': outgoingChecksCount,
      'incoming_checks_count': incomingChecksCount,
      'total_outgoing_checks': totalOutgoingChecks,
      'total_incoming_checks': totalIncomingChecks,
    };
  }
}
