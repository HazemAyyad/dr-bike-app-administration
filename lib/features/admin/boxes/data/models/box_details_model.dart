import 'package:doctorbike/core/helpers/json_safe_parser.dart';

import '../../domain/entity/all_boxes_logs_entity.dart';
import '../../domain/entity/box_details_entity.dart';
import 'all_boxes_logs_model.dart';

class BoxDetailsModel extends BoxDetailsEntity {
  BoxDetailsModel({
    required String boxName,
    required String totalBalance,
    required String isShown,
    required List<BoxLog> boxLogs,
    required String currency,
  }) : super(
          boxName: boxName,
          totalBalance: totalBalance,
          isShown: isShown,
          boxLogs: boxLogs,
          currency: currency,
        );

  factory BoxDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return BoxDetailsModel(
      boxName: asString(j['box_name']),
      totalBalance: asString(j['totla_balance'], '0.00'),
      isShown: asString(j['is_shown'], '0'),
      boxLogs: mapList(
        j['box_logs'],
        (Map<String, dynamic> m) => BoxLogModel.fromJson(m),
      ),
      currency: asString(j['box_currency']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'box_name': boxName,
      'totla_balance': totalBalance,
      'is_shown': isShown,
      'box_logs': boxLogs.map((e) {
        if (e is BoxLogModel) {
          return e.toJson();
        }
        return <String, dynamic>{};
      }).toList(),
      'box_currency': currency,
    };
  }
}
