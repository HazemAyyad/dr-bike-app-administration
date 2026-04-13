import 'package:doctorbike/core/helpers/json_safe_parser.dart';

class FileBoxDetailsModel {
  final int fileBoxId;
  final String fileBoxName;
  final int fileId;
  final String fileName;
  final String treasuryId;
  final String treasuryName;

  FileBoxDetailsModel({
    required this.fileBoxId,
    required this.fileBoxName,
    required this.fileId,
    required this.fileName,
    required this.treasuryId,
    required this.treasuryName,
  });

  factory FileBoxDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return FileBoxDetailsModel(
      fileBoxId: asInt(j['file_box_id']),
      fileBoxName: asString(j['file_box_name']),
      fileId: asInt(j['file_id']),
      fileName: asString(j['file_name']),
      treasuryId: asString(j['treasury_id']),
      treasuryName: asString(j['treasury_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_box_id': fileBoxId,
      'file_box_name': fileBoxName,
      'file_id': fileId,
      'file_name': fileName,
      'treasury_id': treasuryId,
      'treasury_name': treasuryName,
    };
  }
}
