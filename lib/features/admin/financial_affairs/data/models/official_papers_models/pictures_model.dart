import 'package:doctorbike/core/helpers/show_net_image.dart';

class PictureModel {
  final int id;
  final String name;
  final String description;
  final String file;

  PictureModel({
    required this.id,
    required this.name,
    required this.description,
    required this.file,
  });

  factory PictureModel.fromJson(Map<String, dynamic> json) {
    return PictureModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      file: ShowNetImage.getPhoto(json['file']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'file': file,
    };
  }
}
