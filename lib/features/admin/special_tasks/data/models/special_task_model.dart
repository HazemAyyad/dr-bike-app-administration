import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';

import '../../domain/entities/special_tasks_entities.dart';

class SpecialTaskModel extends SpecialTaskEntity {
  SpecialTaskModel({
    required int id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required bool isCanceled,
    required String status,
  }) : super(
          id: id,
          name: name,
          startDate: startDate,
          endDate: endDate,
          isCanceled: isCanceled,
          status: status,
        );

  factory SpecialTaskModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return SpecialTaskModel(
      id: asInt(j[ApiKey.id]),
      name: asString(j[ApiKey.name], 'Unknown'),
      startDate: parseApiDateTime(j[ApiKey.start_date]),
      endDate: parseApiDateTime(j[ApiKey.end_date]),
      isCanceled: asBool(j[ApiKey.is_canceled]),
      status: asString(j[ApiKey.status]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.start_date: startDate.toIso8601String(),
      ApiKey.end_date: endDate.toIso8601String(),
      ApiKey.is_canceled: isCanceled ? '1' : '0',
      ApiKey.status: status,
    };
  }
}
