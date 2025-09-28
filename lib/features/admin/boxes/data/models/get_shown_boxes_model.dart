import '../../domain/entity/get_shown_boxes_entity.dart';

class GetShownBoxesModel extends GetShownBoxesEntity {
  const GetShownBoxesModel({
    required int boxId,
    required String boxName,
    required double totalBalance,
    required bool isShown,
    required String currency,
  }) : super(
          boxId: boxId,
          boxName: boxName,
          totalBalance: totalBalance,
          isShown: isShown,
          currency: currency,
        );

  factory GetShownBoxesModel.fromJson(Map<String, dynamic> json) {
    return GetShownBoxesModel(
      boxId: int.parse(json['box_id'].toString()),
      boxName: json['box_name'] ?? '',
      totalBalance: double.parse(json['total_balance'].toString()),
      isShown: json['is_shown'].toString() == "1",
      currency: json['currency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "box_id": boxId,
      "box_name": boxName,
      "total_balance": totalBalance.toStringAsFixed(2),
      "is_shown": isShown ? "1" : "0",
    };
  }
}
