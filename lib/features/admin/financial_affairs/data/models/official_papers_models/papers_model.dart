import 'package:doctorbike/core/helpers/show_net_image.dart';

class PaperModel {
  final int paperId;
  final String paperName;
  final String treasuryName;
  final String fileBoxName;
  final String fileName;
  final String img;

  PaperModel({
    required this.paperId,
    required this.paperName,
    required this.treasuryName,
    required this.fileBoxName,
    required this.fileName,
    required this.img,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) {
    return PaperModel(
      paperId: json['paper_id'] ?? 0,
      paperName: json['paper_name'] ?? '',
      treasuryName: json['treasury_name'] ?? '',
      fileBoxName: json['file_box_name'] ?? '',
      fileName: json['file_name'] ?? '',
      img: ShowNetImage.getPhoto(json['img']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paper_id': paperId,
      'paper_name': paperName,
      'treasury_name': treasuryName,
      'file_box_name': fileBoxName,
      'file_name': fileName,
      'img': img,
    };
  }
}
