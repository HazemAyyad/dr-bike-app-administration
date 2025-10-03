import '../../domain/entity/general_checks_data_entity.dart';

class GeneralChecksDataModel extends GeneralChecksDataEntity {
  const GeneralChecksDataModel({
    required int notCashedOutgoingChecksCount,
    required int cashedOutgoingChecksCount,
    required int notCashedIncomingChecksCount,
    required int cashedIncomingChecksCount,
    required int cashedToBoxIncomingChecksCount,
    required String totalOutgoingChecksDollar,
    required String totalOutgoingChecksDinar,
    required String totalOutgoingChecksShekel,
    required String totalIncomingChecksDollar,
    required String totalIncomingChecksDinar,
    required String totalIncomingChecksShekel,
  }) : super(
          notCashedOutgoingChecksCount: notCashedOutgoingChecksCount,
          cashedOutgoingChecksCount: cashedOutgoingChecksCount,
          notCashedIncomingChecksCount: notCashedIncomingChecksCount,
          cashedIncomingChecksCount: cashedIncomingChecksCount,
          cashedToBoxIncomingChecksCount: cashedToBoxIncomingChecksCount,
          totalOutgoingChecksDollar: totalOutgoingChecksDollar,
          totalOutgoingChecksDinar: totalOutgoingChecksDinar,
          totalOutgoingChecksShekel: totalOutgoingChecksShekel,
          totalIncomingChecksDollar: totalIncomingChecksDollar,
          totalIncomingChecksDinar: totalIncomingChecksDinar,
          totalIncomingChecksShekel: totalIncomingChecksShekel,
        );

  factory GeneralChecksDataModel.fromJson(Map<String, dynamic> json) {
    return GeneralChecksDataModel(
      notCashedOutgoingChecksCount:
          json['not_cashed_outgoing_checks_count'] ?? 0,
      cashedOutgoingChecksCount: json['cashed_outgoing_checks_count'] ?? 0,
      notCashedIncomingChecksCount:
          json['not_cashed_incoming_checks_count'] ?? 0,
      cashedIncomingChecksCount: json['cashed_incoming_checks_count'] ?? 0,
      cashedToBoxIncomingChecksCount:
          json['cashedto_box_incoming_checks_count'] ?? 0,
      totalOutgoingChecksDollar:
          (json['total_outgoing_checks_dollar'] ?? '0').toString(),
      totalOutgoingChecksDinar:
          (json['total_outgoing_checks_dinar'] ?? '0').toString(),
      totalOutgoingChecksShekel:
          (json['total_outgoing_checks_shekel'] ?? '0').toString(),
      totalIncomingChecksDollar:
          (json['total_incoming_checks_dollar'] ?? '0').toString(),
      totalIncomingChecksDinar:
          (json['total_incoming_checks_dinar'] ?? '0').toString(),
      totalIncomingChecksShekel:
          (json['total_incoming_checks_shekel'] ?? '0').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'not_cashed_outgoing_checks_count': notCashedOutgoingChecksCount,
      'cashed_outgoing_checks_count': cashedOutgoingChecksCount,
      'not_cashed_incoming_checks_count': notCashedIncomingChecksCount,
      'cashed_incoming_checks_count': cashedIncomingChecksCount,
      'cashedto_box_incoming_checks_count': cashedToBoxIncomingChecksCount,
      'total_outgoing_checks_dollar': totalOutgoingChecksDollar,
      'total_outgoing_checks_dinar': totalOutgoingChecksDinar,
      'total_outgoing_checks_shekel': totalOutgoingChecksShekel,
      'total_incoming_checks_dollar': totalIncomingChecksDollar,
      'total_incoming_checks_dinar': totalIncomingChecksDinar,
      'total_incoming_checks_shekel': totalIncomingChecksShekel,
    };
  }
}
