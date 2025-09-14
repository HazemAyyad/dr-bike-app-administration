class SafesModel {
  final int id;
  final String name;
  final List<FileBoxModel> fileBoxes;

  SafesModel({
    required this.id,
    required this.name,
    required this.fileBoxes,
  });

  factory SafesModel.fromJson(Map<String, dynamic> json) {
    return SafesModel(
      id: json['id'],
      name: json['name'],
      fileBoxes: (json['file_boxes'] as List<dynamic>)
          .map((e) => FileBoxModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'file_boxes': fileBoxes.map((e) => e.toJson()).toList(),
    };
  }
}

class FileBoxModel {
  final int id;
  final String treasuryId;
  final String name;
  final List<FilesModel> files;

  FileBoxModel({
    required this.id,
    required this.treasuryId,
    required this.name,
    required this.files,
  });

  factory FileBoxModel.fromJson(Map<String, dynamic> json) {
    return FileBoxModel(
      id: json['id'],
      treasuryId: json['treasury_id'],
      name: json['name'],
      files: (json['files'] as List<dynamic>)
          .map((e) => FilesModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treasury_id': treasuryId,
      'name': name,
      'files': files.map((e) => e.toJson()).toList(),
    };
  }
}

class FilesModel {
  final int id;
  final String fileBoxId;
  final String name;

  FilesModel({
    required this.id,
    required this.fileBoxId,
    required this.name,
  });

  factory FilesModel.fromJson(Map<String, dynamic> json) {
    return FilesModel(
      id: json['id'],
      fileBoxId: json['file_box_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_box_id': fileBoxId,
      'name': name,
    };
  }
}
