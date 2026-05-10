import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/employee_points_log_model.dart';
import '../../data/models/employee_reward_rule_model.dart';
import '../repositories/employee_section_repository.dart';

class MutateEmployeePointsUsecase {
  final EmployeeRepository employeeRepository;

  MutateEmployeePointsUsecase({required this.employeeRepository});

  Future<Either<Failure, EmployeePointsLogModel>> call({
    required int employeeId,
    required bool isAdd,
    required int points,
    required String category,
    String? reason,
    String? notes,
    String? pointsDate,
  }) {
    return employeeRepository.mutateEmployeePoints(
      employeeId: employeeId,
      isAdd: isAdd,
      points: points,
      category: category,
      reason: reason,
      notes: notes,
      pointsDate: pointsDate,
    );
  }
}

class GetEmployeePointsLogsUsecase {
  final EmployeeRepository employeeRepository;

  GetEmployeePointsLogsUsecase({required this.employeeRepository});

  Future<EmployeePointsLogsPage> call({
    required int employeeId,
    int? month,
    int? year,
    String? category,
    String? operationType,
    int perPage = 50,
    int page = 1,
  }) {
    return employeeRepository.getEmployeePointsLogs(
      employeeId: employeeId,
      month: month,
      year: year,
      category: category,
      operationType: operationType,
      perPage: perPage,
      page: page,
    );
  }
}

class GetEmployeePointsMonthlySummaryUsecase {
  final EmployeeRepository employeeRepository;

  GetEmployeePointsMonthlySummaryUsecase({required this.employeeRepository});

  Future<EmployeePointsMonthlySummaryModel> call({
    required int employeeId,
    int? month,
    int? year,
  }) {
    return employeeRepository.getEmployeePointsMonthlySummary(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }
}

class GetEmployeePointsCategoriesUsecase {
  final EmployeeRepository employeeRepository;

  GetEmployeePointsCategoriesUsecase({required this.employeeRepository});

  Future<EmployeePointsCategoriesModel> call() {
    return employeeRepository.getEmployeePointsCategories();
  }
}

class GetEmployeeRewardRulesUsecase {
  final EmployeeRepository employeeRepository;

  GetEmployeeRewardRulesUsecase({required this.employeeRepository});

  Future<List<EmployeeRewardRuleModel>> call({bool? isActive}) {
    return employeeRepository.getEmployeeRewardRules(isActive: isActive);
  }
}

class CreateEmployeeRewardRuleUsecase {
  final EmployeeRepository employeeRepository;

  CreateEmployeeRewardRuleUsecase({required this.employeeRepository});

  Future<Either<Failure, EmployeeRewardRuleModel>> call({
    required int minPoints,
    int? maxPoints,
    required double rewardAmount,
    required bool isActive,
  }) {
    return employeeRepository.createEmployeeRewardRule(
      minPoints: minPoints,
      maxPoints: maxPoints,
      rewardAmount: rewardAmount,
      isActive: isActive,
    );
  }
}

class UpdateEmployeeRewardRuleUsecase {
  final EmployeeRepository employeeRepository;

  UpdateEmployeeRewardRuleUsecase({required this.employeeRepository});

  Future<Either<Failure, EmployeeRewardRuleModel>> call({
    required int id,
    int? minPoints,
    int? maxPoints,
    bool clearMaxPoints = false,
    double? rewardAmount,
    bool? isActive,
  }) {
    return employeeRepository.updateEmployeeRewardRule(
      id: id,
      minPoints: minPoints,
      maxPoints: maxPoints,
      clearMaxPoints: clearMaxPoints,
      rewardAmount: rewardAmount,
      isActive: isActive,
    );
  }
}

class DeleteEmployeeRewardRuleUsecase {
  final EmployeeRepository employeeRepository;

  DeleteEmployeeRewardRuleUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({required int id}) {
    return employeeRepository.deleteEmployeeRewardRule(id: id);
  }
}
