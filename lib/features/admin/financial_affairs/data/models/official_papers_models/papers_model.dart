import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class PaperModel {
  final int paperId;
  final String paperName;
  final String treasuryName;
  final String fileBoxName;
  final String fileName;
  final List<String> img;
  final String note;
  final String createdAt;

  PaperModel({
    required this.paperId,
    required this.paperName,
    required this.treasuryName,
    required this.fileBoxName,
    required this.fileName,
    required this.img,
    required this.note,
    required this.createdAt,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    List<String> mapImg(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((e) => ShowNetImage.getPhoto(asNullableString(e)))
          .toList();
    }

    return PaperModel(
      paperId: asInt(j['paper_id']),
      paperName: asString(j['paper_name']),
      treasuryName: asString(j['treasury_name']),
      fileBoxName: asString(j['file_box_name']),
      fileName: asString(j['file_name']),
      img: mapImg(j['img']),
      note: asString(j['note']),
      createdAt: asString(j['created_at']),
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
      'note': note,
      'created_at': createdAt,
    };
  }
}
