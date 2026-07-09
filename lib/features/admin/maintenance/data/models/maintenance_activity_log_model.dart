import '../../../../../core/helpers/json_safe_parser.dart';

class MaintenanceActivityLogModel {
  final int id;
  final String action;
  final String title;
  final String description;
  final String actorName;
  final String? actorType;
  final String? oldStatus;
  final String? newStatus;
  final String createdAt;

  const MaintenanceActivityLogModel({
    required this.id,
    required this.action,
    required this.title,
    required this.description,
    required this.actorName,
    this.actorType,
    this.oldStatus,
    this.newStatus,
    required this.createdAt,
  });

  factory MaintenanceActivityLogModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceActivityLogModel(
      id: asInt(json['id']),
      action: asString(json['action']),
      title: asString(json['title']),
      description: asString(json['description']),
      actorName: asString(json['actor_name'], '-'),
      actorType: asNullableString(json['actor_type']),
      oldStatus: asNullableString(json['old_status']),
      newStatus: asNullableString(json['new_status']),
      createdAt: asString(json['created_at']),
    );
  }
}
