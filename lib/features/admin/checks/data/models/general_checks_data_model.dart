import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
    final j = Map<String, dynamic>.from(json);
    return GeneralChecksDataModel(
      notCashedOutgoingChecksCount:
          asInt(j['not_cashed_outgoing_checks_count']),
      cashedOutgoingChecksCount: asInt(j['cashed_outgoing_checks_count']),
      notCashedIncomingChecksCount:
          asInt(j['not_cashed_incoming_checks_count']),
      cashedIncomingChecksCount: asInt(j['cashed_incoming_checks_count']),
      cashedToBoxIncomingChecksCount:
          asInt(j['cashedto_box_incoming_checks_count']),
      totalOutgoingChecksDollar:
          asString(j['total_outgoing_checks_dollar'], '0'),
      totalOutgoingChecksDinar:
          asString(j['total_outgoing_checks_dinar'], '0'),
      totalOutgoingChecksShekel:
          asString(j['total_outgoing_checks_shekel'], '0'),
      totalIncomingChecksDollar:
          asString(j['total_incoming_checks_dollar'], '0'),
      totalIncomingChecksDinar:
          asString(j['total_incoming_checks_dinar'], '0'),
      totalIncomingChecksShekel:
          asString(j['total_incoming_checks_shekel'], '0'),
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
