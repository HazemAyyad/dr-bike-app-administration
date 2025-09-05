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
    return FinancialDetailsModel(
      employeeId: json[ApiKey.employee_id] ?? 0,
      employeeName: json[ApiKey.employee_name] ?? 'unknown',
      salary: json[ApiKey.salary] ?? '0',
      debts: json[ApiKey.debts] ?? '0',
      points: json[ApiKey.points] ?? '0',
      hourWorkPrice: json[ApiKey.hour_work_price] ?? '0',
      totalWorkHours: json[ApiKey.total_work_hours] ?? '0',
      numberOfWorkHours: json[ApiKey.number_of_work_hours] ?? '0',
      pointsRevenue: json[ApiKey.points_revenue] ?? '0',
      total: json[ApiKey.total] ?? 0,
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
