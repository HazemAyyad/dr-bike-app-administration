import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class FilePapersModel {
  final int fileId;
  final String fileName;
  final int paperId;
  final String paperName;
  final String paperImage;
  final String fileBoxName;
  final String treasuryName;

  FilePapersModel({
    required this.fileId,
    required this.fileName,
    required this.paperId,
    required this.paperName,
    required this.paperImage,
    required this.fileBoxName,
    required this.treasuryName,
  });

  factory FilePapersModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return FilePapersModel(
      fileId: asInt(j['file_id']),
      fileName: asString(j['file_name']),
      paperId: asInt(j['paper_id']),
      paperName: asString(j['paper_name']),
      paperImage: ShowNetImage.getPhoto(asNullableString(j['paper_image'])),
      fileBoxName: asString(j['file_box_name']),
      treasuryName: asString(j['treasury_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'file_name': fileName,
      'paper_id': paperId,
      'paper_name': paperName,
      'paper_image': paperImage,
      'file_box_name': fileBoxName,
      'treasury_name': treasuryName,
    };
  }
}
