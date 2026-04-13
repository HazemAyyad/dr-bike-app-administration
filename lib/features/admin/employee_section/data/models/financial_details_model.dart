import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/features/admin/employee_section/domain/entities/financial_details_entity.dart';

import '../../../../../core/databases/api/end_points.dart';

class FinancialDetailsModel extends FinancialDetailsEntity {
  const FinancialDetailsModel({
    required int employeeId,
    required String employeeName,
    required String salary,
    required String debts,
    required String points,
    required String hourWorkPrice,
    required String totalWorkHours,
    required String numberOfWorkHours,
    required dynamic pointsRevenue,
    required dynamic total,
  }) : super(
          employeeId: employeeId,
          employeeName: employeeName,
          salary: salary,
          debts: debts,
          points: points,
          hourWorkPrice: hourWorkPrice,
          totalWorkHours: totalWorkHours,
          numberOfWorkHours: numberOfWorkHours,
          pointsRevenue: pointsRevenue,
          total: total,
        );

  factory FinancialDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return FinancialDetailsModel(
      employeeId: asInt(j[ApiKey.employee_id]),
      employeeName: asString(j[ApiKey.employee_name], 'unknown'),
      salary: asString(j[ApiKey.salary], '0'),
      debts: asString(j[ApiKey.debts], '0'),
      points: asString(j[ApiKey.points], '0'),
      hourWorkPrice: asString(j[ApiKey.hour_work_price], '0'),
      totalWorkHours: asString(j[ApiKey.total_work_hours], '0'),
      numberOfWorkHours: asString(j[ApiKey.number_of_work_hours], '0'),
      pointsRevenue: j[ApiKey.points_revenue],
      total: j[ApiKey.total],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.employee_id: employeeId,
      ApiKey.employee_name: employeeName,
      ApiKey.salary: salary,
      ApiKey.debts: debts,
      ApiKey.points: points,
      ApiKey.hour_work_price: hourWorkPrice,
      ApiKey.total_work_hours: totalWorkHours,
      ApiKey.number_of_work_hours: numberOfWorkHours,
      ApiKey.points_revenue: pointsRevenue,
      ApiKey.total: total,
    };
  }
}
