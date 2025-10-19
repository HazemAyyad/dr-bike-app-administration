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
    return BoxDetailsModel(
      boxName: json['box_name'] ?? '',
      totalBalance: json['totla_balance'] ?? '0.00',
      isShown: json['is_shown'] ?? '0',
      boxLogs: (json['box_logs'] as List<dynamic>?)
              ?.map((e) => BoxLogModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currency: json['box_currency'] ?? '',
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
        // fallback لو جالك Entity مش Model
        // return (e).toJson();
      }).toList(),
      'box_currency': currency,
    };
  }
}
