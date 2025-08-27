import 'check_model.dart';

class ArchiveDataModel {
  final String status;
  final String checksStatus;
  final String checksImagesPath;
  final List<CheckModel> archiveData;
  ArchiveDataModel({
    required this.status,
    required this.checksStatus,
    required this.checksImagesPath,
    required this.archiveData,
  });

  factory ArchiveDataModel.fromJson(Map<String, dynamic> json) {
    return ArchiveDataModel(
      status: json['status'] ?? '',
      checksStatus: json['checks_status'] ?? '',
      checksImagesPath: json['checks_images_path'] ?? '',
      archiveData: (json['archived_checks'] as List<dynamic>)
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
      'cancelled_checks': archiveData.map((e) => e.toJson()).toList(),
    };
  }
}
