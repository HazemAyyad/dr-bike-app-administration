import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class LogsModel {
  final int id;
  final String name;
  final String description;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCanceled;

  LogsModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.isCanceled,
  });

  factory LogsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return LogsModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      description: asString(j['description']),
      type: asString(j['type']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      isCanceled: asBool(j['is_canceled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_canceled': isCanceled ? '1' : '0',
    };
  }
}
