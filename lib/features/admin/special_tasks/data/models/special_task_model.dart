import 'package:doctorbike/core/databases/api/end_points.dart';

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
    return SpecialTaskModel(
      id: json[ApiKey.id] ?? 0,
      name: json[ApiKey.name] ?? 'Unknown',
      startDate: json[ApiKey.start_date] != null
          ? DateTime.parse(json[ApiKey.start_date])
          : DateTime.now(),
      endDate: json[ApiKey.end_date] != null
          ? DateTime.parse(json[ApiKey.end_date])
          : DateTime.now(),
      isCanceled: json[ApiKey.is_canceled] == "1",
      status: json[ApiKey.status] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.start_date: startDate.toIso8601String(),
      ApiKey.end_date: endDate.toIso8601String(),
      ApiKey.is_canceled: isCanceled ? "1" : "0",
      ApiKey.status: status,
    };
  }
}
