import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../domain/entities/financial_dues_entity.dart';

class FinancialDuesModel extends FinancialDuesEntity {
  const FinancialDuesModel({
    required int id,
    required String employeeName,
    required String salary,
    required String debts,
    required String employeeImg,
  }) : super(
          id: id,
          employeeName: employeeName,
          salary: salary,
          debts: debts,
          employeeImg: employeeImg,
        );

  factory FinancialDuesModel.fromJson(Map<String, dynamic> json) {
    return FinancialDuesModel(
      id: json[ApiKey.id] ?? 0,
      employeeName: json[ApiKey.user_name] ?? 'unknown',
      salary: json[ApiKey.salary] ?? '0',
      debts: json[ApiKey.debts] ?? '0',
      employeeImg: ShowNetImage.getPhoto(json[ApiKey.employee_img]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.employee_name: employeeName,
      ApiKey.salary: salary,
      ApiKey.debts: debts,
      ApiKey.employee_img: employeeImg,
    };
  }
}
