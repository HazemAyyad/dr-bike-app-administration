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
    return FilePapersModel(
      fileId: json['file_id'],
      fileName: json['file_name'],
      paperId: json['paper_id'],
      paperName: json['paper_name'],
      paperImage: ShowNetImage.getPhoto(json['paper_image']),
      fileBoxName: json['file_box_name'],
      treasuryName: json['treasury_name'],
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
