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
    return FileBoxDetailsModel(
      fileBoxId: json['file_box_id'],
      fileBoxName: json['file_box_name'],
      fileId: json['file_id'],
      fileName: json['file_name'],
      treasuryId: json['treasury_id'].toString(),
      treasuryName: json['treasury_name'],
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
