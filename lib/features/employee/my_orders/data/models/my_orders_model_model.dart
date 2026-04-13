import 'package:doctorbike/core/helpers/json_safe_parser.dart';

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
    final j = Map<String, dynamic>.from(json);
    return MyOrdersModel(
      id: asInt(j['id']),
      type: asString(j['type']),
      status: asString(j['status']),
      overtimeValue: asString(j['overtime_value']),
      loanValue: asString(j['loan_value']),
      extraWorkHours: asString(j['extra_work_hours']),
      createdAt: parseApiDateTime(j['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'overtime_value': overtimeValue,
      'loan_value': loanValue,
      'extra_work_hours': extraWorkHours,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
