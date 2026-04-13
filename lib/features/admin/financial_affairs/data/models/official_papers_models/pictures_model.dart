import 'package:doctorbike/core/helpers/json_safe_parser.dart';
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
    final j = Map<String, dynamic>.from(json);
    return PictureModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      description: asString(j['description']),
      file: ShowNetImage.getPhoto(asNullableString(j['file'])),
      createdAt: asString(j['created_at']),
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
