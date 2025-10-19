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
    return FilesModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      fileBoxId: json['file_box_id'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      isCanceled: json['is_canceled'] ?? '0',
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
