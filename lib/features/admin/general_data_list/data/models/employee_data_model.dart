import 'package:doctorbike/core/helpers/show_net_image.dart';

class GeneralDataModel {
  final int id;
  final String phone;
  final String jobTitle;
  final String name;
  final String isCanceled;
  final String? idImage;

  GeneralDataModel({
    required this.id,
    required this.phone,
    required this.jobTitle,
    required this.name,
    required this.isCanceled,
    this.idImage,
  });

  factory GeneralDataModel.fromJson(Map<String, dynamic> json) {
    return GeneralDataModel(
      id: json['id'] ?? 0,
      phone: json['phone'] ?? '',
      jobTitle: json['job_title'] ?? '',
      name: json['name'] ?? '',
      isCanceled: json['is_canceled'] ?? '0',
      idImage: json['ID_image'] is String
          ? ShowNetImage.getPhoto(json['ID_image'])
          : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'job_title': jobTitle,
      'name': name,
      'is_canceled': isCanceled,
      'ID_image': idImage,
    };
  }
}
