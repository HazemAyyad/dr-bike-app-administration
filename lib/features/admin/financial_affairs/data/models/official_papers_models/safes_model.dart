import 'package:doctorbike/core/helpers/json_safe_parser.dart';

import 'files_model.dart';

/// خزينة تحتوي صناديق ملفات؛ كل صندوق يحتوي ملفات ([FilesModel] من `files_model.dart`).
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
    final j = Map<String, dynamic>.from(json);
    return SafesModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      fileBoxes: mapList(j['file_boxes'], (m) => FileBoxModel.fromJson(m)),
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
    final j = Map<String, dynamic>.from(json);
    return FileBoxModel(
      id: asInt(j['id']),
      treasuryId: asString(j['treasury_id']),
      name: asString(j['name']),
      files: mapList(j['files'], (m) => FilesModel.fromJson(m)),
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
