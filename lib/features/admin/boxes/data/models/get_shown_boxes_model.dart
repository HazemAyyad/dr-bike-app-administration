import 'package:doctorbike/core/helpers/json_safe_parser.dart';

import '../../domain/entity/get_shown_boxes_entity.dart';

class ShownBoxesModel extends GetShownBoxesEntity {
  const ShownBoxesModel({
    required int boxId,
    required String boxName,
    required double totalBalance,
    required bool isShown,
    required String currency,
    required String type,
  }) : super(
          boxId: boxId,
          boxName: boxName,
          totalBalance: totalBalance,
          isShown: isShown,
          currency: currency,
          type: type,
        );

  factory ShownBoxesModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ShownBoxesModel(
      boxId: asInt(j['box_id']),
      boxName: asString(j['box_name']),
      totalBalance: asDouble(j['total_balance']),
      isShown: asBool(j['is_shown']),
      currency: asString(j['currency']),
      type: asString(j['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'box_id': boxId,
      'box_name': boxName,
      'total_balance': totalBalance.toStringAsFixed(2),
      'is_shown': isShown ? '1' : '0',
      'currency': currency,
      'type': type,
    };
  }
}
