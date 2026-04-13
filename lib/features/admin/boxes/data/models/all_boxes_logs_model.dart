import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
    final j = Map<String, dynamic>.from(json);
    return BoxLogModel(
      id: asInt(j['id']),
      fromBoxId: asNullableString(j['from_box_id']),
      toBoxId: asNullableString(j['to_box_id']),
      description: asString(j['description']),
      value: asDouble(j['value']),
      boxId: asNullableString(j['box_id']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      type: asNullableString(j['type']),
      fromBox: j['from_box'] != null
          ? BoxModel.fromJson(asMap(j['from_box']))
          : null,
      toBox:
          j['to_box'] != null ? BoxModel.fromJson(asMap(j['to_box'])) : null,
      box: j['box'] != null ? BoxModel.fromJson(asMap(j['box'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_box_id': fromBoxId,
      'to_box_id': toBoxId,
      'description': description,
      'value': value.toStringAsFixed(2),
      'box_id': boxId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'type': type,
      'from_box': fromBox is BoxModel ? (fromBox as BoxModel).toJson() : null,
      'to_box': toBox is BoxModel ? (toBox as BoxModel).toJson() : null,
      'box': box is BoxModel ? (box as BoxModel).toJson() : null,
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
    final j = Map<String, dynamic>.from(json);
    return BoxModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      total: asDouble(j['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'total': total.toStringAsFixed(2),
    };
  }
}
