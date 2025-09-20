class MyOrdersModel {
  final int id;
  final String type;
  final String status;
  final String overtimeValue;
  final String loanValue;
  final String extraWorkHours;
  final DateTime createdAt;

  MyOrdersModel({
    required this.id,
    required this.type,
    required this.status,
    required this.overtimeValue,
    required this.loanValue,
    required this.extraWorkHours,
    required this.createdAt,
  });

  factory MyOrdersModel.fromJson(Map<String, dynamic> json) {
    return MyOrdersModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      overtimeValue: json['overtime_value'] ?? '',
      loanValue: json['loan_value'] ?? '',
      extraWorkHours: json['extra_work_hours'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type,
      "status": status,
      "overtime_value": overtimeValue,
      "loan_value": loanValue,
      "extra_work_hours": extraWorkHours,
      "created_at": createdAt.toIso8601String(),
    };
  }
}
