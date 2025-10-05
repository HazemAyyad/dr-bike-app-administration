import 'package:doctorbike/core/helpers/show_net_image.dart';

class PictureModel {
  final int id;
  final String name;
  final String description;
  final String file;
  final String createdAt;

  PictureModel({
    required this.id,
    required this.name,
    required this.description,
    required this.file,
    required this.createdAt,
  });

  factory PictureModel.fromJson(Map<String, dynamic> json) {
    return PictureModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      file: ShowNetImage.getPhoto(json['file']),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'file': file,
      'created_at': createdAt,
    };
  }
}
