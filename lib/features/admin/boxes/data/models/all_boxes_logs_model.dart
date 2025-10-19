import '../../domain/entity/all_boxes_logs_entity.dart';

class BoxLogModel extends BoxLog {
  const BoxLogModel({
    required int id,
    required String? fromBoxId,
    required String? toBoxId,
    required String description,
    required double value,
    required String? boxId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String? type,
    required Box? fromBox,
    required Box? toBox,
    required Box? box,
  }) : super(
          id: id,
          fromBoxId: fromBoxId,
          toBoxId: toBoxId,
          description: description,
          value: value,
          boxId: boxId,
          createdAt: createdAt,
          updatedAt: updatedAt,
          type: type,
          fromBox: fromBox,
          toBox: toBox,
          box: box,
        );

  factory BoxLogModel.fromJson(Map<String, dynamic> json) {
    return BoxLogModel(
      id: int.parse(json['id'].toString()),
      fromBoxId: json['from_box_id']?.toString(),
      toBoxId: json['to_box_id']?.toString(),
      description: json['description'] ?? '',
      value: double.tryParse(json['value'].toString()) ?? 0.0,
      boxId: json['box_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      type: json['type'],
      fromBox:
          json['from_box'] != null ? BoxModel.fromJson(json['from_box']) : null,
      toBox: json['to_box'] != null ? BoxModel.fromJson(json['to_box']) : null,
      box: json['box'] != null ? BoxModel.fromJson(json['box']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "from_box_id": fromBoxId,
      "to_box_id": toBoxId,
      "description": description,
      "value": value.toStringAsFixed(2),
      "box_id": boxId,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "type": type,
      "from_box": fromBox is BoxModel ? (fromBox as BoxModel).toJson() : null,
      "to_box": toBox is BoxModel ? (toBox as BoxModel).toJson() : null,
      "box": box is BoxModel ? (box as BoxModel).toJson() : null,
    };
  }
}

class BoxModel extends Box {
  const BoxModel({
    required int id,
    required String name,
    required double total,
  }) : super(
          id: id,
          name: name,
          total: total,
        );

  factory BoxModel.fromJson(Map<String, dynamic> json) {
    return BoxModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "total": total.toStringAsFixed(2),
    };
  }
}
