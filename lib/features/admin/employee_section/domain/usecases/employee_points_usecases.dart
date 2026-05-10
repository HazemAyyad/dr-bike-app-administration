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
    int? points,
    String? category,
    int? categoryId,
    String? reason,
    String? notes,
    String? pointsDate,
  }) {
    return employeeRepository.mutateEmployeePoints(
      employeeId: employeeId,
      isAdd: isAdd,
      points: points,
      category: category,
      categoryId: categoryId,
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
    String? statusLabel,
    String? statusColor,
  }) {
    return employeeRepository.createEmployeeRewardRule(
      minPoints: minPoints,
      maxPoints: maxPoints,
      rewardAmount: rewardAmount,
      isActive: isActive,
      statusLabel: statusLabel,
      statusColor: statusColor,
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
    String? statusLabel,
    String? statusColor,
    bool clearStatusFields = false,
    bool? isActive,
  }) {
    return employeeRepository.updateEmployeeRewardRule(
      id: id,
      minPoints: minPoints,
      maxPoints: maxPoints,
      clearMaxPoints: clearMaxPoints,
      rewardAmount: rewardAmount,
      statusLabel: statusLabel,
      statusColor: statusColor,
      clearStatusFields: clearStatusFields,
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

// =============================================================================
// Point Categories
// =============================================================================

class GetEmployeePointCategoriesUsecase {
  final EmployeeRepository employeeRepository;

  GetEmployeePointCategoriesUsecase({required this.employeeRepository});

  Future<List<EmployeePointCategoryModel>> call({
    String? operationType,
    bool? isActive,
  }) {
    return employeeRepository.getEmployeePointCategories(
      operationType: operationType,
      isActive: isActive,
    );
  }
}

class CreateEmployeePointCategoryUsecase {
  final EmployeeRepository employeeRepository;

  CreateEmployeePointCategoryUsecase({required this.employeeRepository});

  Future<Either<Failure, EmployeePointCategoryModel>> call({
    required String nameAr,
    String? nameEn,
    required String code,
    required String operationType,
    required int defaultPoints,
    bool isActive = true,
    int sortOrder = 0,
  }) {
    return employeeRepository.createEmployeePointCategory(
      nameAr: nameAr,
      nameEn: nameEn,
      code: code,
      operationType: operationType,
      defaultPoints: defaultPoints,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }
}

class UpdateEmployeePointCategoryUsecase {
  final EmployeeRepository employeeRepository;

  UpdateEmployeePointCategoryUsecase({required this.employeeRepository});

  Future<Either<Failure, EmployeePointCategoryModel>> call({
    required int id,
    String? nameAr,
    String? nameEn,
    String? code,
    String? operationType,
    int? defaultPoints,
    bool? isActive,
    int? sortOrder,
  }) {
    return employeeRepository.updateEmployeePointCategory(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      code: code,
      operationType: operationType,
      defaultPoints: defaultPoints,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }
}

class DeleteEmployeePointCategoryUsecase {
  final EmployeeRepository employeeRepository;

  DeleteEmployeePointCategoryUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({required int id}) {
    return employeeRepository.deleteEmployeePointCategory(id: id);
  }
}

// =============================================================================
// Global Points (admin)
// =============================================================================

class GetGlobalEmployeesPointsUsecase {
  final EmployeeRepository employeeRepository;

  GetGlobalEmployeesPointsUsecase({required this.employeeRepository});

  Future<List<EmployeePointsRowModel>> call({
    int? month,
    int? year,
    String? search,
  }) {
    return employeeRepository.getGlobalEmployeesPoints(
      month: month,
      year: year,
      search: search,
    );
  }
}

class GetGlobalPointsReportUsecase {
  final EmployeeRepository employeeRepository;

  GetGlobalPointsReportUsecase({required this.employeeRepository});

  Future<EmployeePointsReportModel> call({
    int? month,
    int? year,
    List<int>? employeeIds,
    String? operationType,
    int? categoryId,
    bool includeLogs = false,
  }) {
    return employeeRepository.getGlobalPointsReport(
      month: month,
      year: year,
      employeeIds: employeeIds,
      operationType: operationType,
      categoryId: categoryId,
      includeLogs: includeLogs,
    );
  }
}
