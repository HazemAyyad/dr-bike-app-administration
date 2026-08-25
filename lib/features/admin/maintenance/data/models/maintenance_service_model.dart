class MaintenanceServiceModel {
  const MaintenanceServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.media,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final bool isActive;
  final List<MaintenanceServiceMediaModel> media;

  factory MaintenanceServiceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceServiceModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      media: ((json['media'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => MaintenanceServiceMediaModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class MaintenanceServiceMediaModel {
  const MaintenanceServiceMediaModel({
    required this.id,
    required this.url,
    required this.fileType,
  });

  final int id;
  final String url;
  final String fileType;

  bool get isVideo => fileType == 'video';

  factory MaintenanceServiceMediaModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceServiceMediaModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      url: json['url']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'image',
    );
  }
}
