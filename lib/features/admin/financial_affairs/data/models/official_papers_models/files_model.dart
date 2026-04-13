import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class FilesModel {
  final int id;
  final String name;
  final String fileBoxId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String isCanceled;

  FilesModel({
    required this.id,
    required this.name,
    required this.fileBoxId,
    required this.createdAt,
    required this.updatedAt,
    required this.isCanceled,
  });

  factory FilesModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return FilesModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      fileBoxId: asString(j['file_box_id']),
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      isCanceled: asString(j['is_canceled'], '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_box_id': fileBoxId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_canceled': isCanceled,
    };
  }
}
