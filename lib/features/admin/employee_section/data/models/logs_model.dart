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
    return LogsModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      isCanceled: json['is_canceled']?.toString() == "1",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "type": type,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "is_canceled": isCanceled ? "1" : "0",
    };
  }
}
