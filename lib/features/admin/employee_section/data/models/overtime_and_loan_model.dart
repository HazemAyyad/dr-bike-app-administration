import 'package:doctorbike/core/helpers/show_net_image.dart';

class OvertimeAndLoanModel {
  final int id;
  final String employeeName;
  final String employeeImg;
  final String orderStatus;
  final String type;
  final String? overtimeValue;
  final String? loanValue;
  final String? extraWorkHoursValue;
  final DateTime orderDate;

  OvertimeAndLoanModel({
    required this.id,
    required this.employeeName,
    required this.employeeImg,
    required this.orderStatus,
    required this.type,
    this.overtimeValue,
    this.loanValue,
    this.extraWorkHoursValue,
    required this.orderDate,
  });

  factory OvertimeAndLoanModel.fromJson(Map<String, dynamic> json) {
    return OvertimeAndLoanModel(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'],
      employeeName: json['employee_name'] ?? '',
      employeeImg: ShowNetImage.getPhoto(json['employee_img'] ?? ''),
      orderStatus: json['order_status'] ?? '',
      type: json['type'] ?? '',
      overtimeValue: json['overtime_value'] ?? '',
      loanValue: json['loan_value'] ?? '',
      extraWorkHoursValue: json['extra_work_hours'] ?? '',
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_name': employeeName,
      'employee_img': employeeImg,
      'order_status': orderStatus,
      'type': type,
      'overtime_value': overtimeValue,
      'loan_value': loanValue,
      'extra_work_hours': extraWorkHoursValue,
      'order_date': orderDate,
    };
  }
}
