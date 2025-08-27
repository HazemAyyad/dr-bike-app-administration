import 'check_model.dart';

class CashedToPersonOutgoingModel {
  final String status;
  final String checksStatus;
  final String checksImagesPath;
  final List<CheckModel> cashedToPerson;
  CashedToPersonOutgoingModel({
    required this.status,
    required this.checksStatus,
    required this.checksImagesPath,
    required this.cashedToPerson,
  });

  factory CashedToPersonOutgoingModel.fromJson(Map<String, dynamic> json) {
    return CashedToPersonOutgoingModel(
      status: json['status'] ?? '',
      checksStatus: json['checks_status'] ?? '',
      checksImagesPath: json['checks_images_path'] ?? '',
      cashedToPerson: (json['cashed_to_person_checks'] as List<dynamic>)
          .map((e) =>
              CheckModel.fromJson(e, imgPath: json['checks_images_path']))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'checks_status': checksStatus,
      'checks_images_path': checksImagesPath,
      'cashed_to_person_checks': cashedToPerson.map((e) => e.toJson()).toList(),
    };
  }
}
