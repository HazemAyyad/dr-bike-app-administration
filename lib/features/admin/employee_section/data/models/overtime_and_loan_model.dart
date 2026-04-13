import 'package:doctorbike/core/helpers/json_safe_parser.dart';
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
    final j = Map<String, dynamic>.from(json);
    return OvertimeAndLoanModel(
      id: asInt(j['id']),
      employeeName: asString(j['employee_name']),
      employeeImg: ShowNetImage.getPhoto(asNullableString(j['employee_img'])),
      orderStatus: asString(j['order_status']),
      type: asString(j['type']),
      overtimeValue: asNullableString(j['overtime_value']),
      loanValue: asNullableString(j['loan_value']),
      extraWorkHoursValue: asNullableString(j['extra_work_hours']),
      orderDate: parseApiDateTime(j['order_date']),
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
