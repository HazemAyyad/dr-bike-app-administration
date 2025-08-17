import 'package:get/get.dart';

import '../../data/models/employee_details_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../data/models/qr_generation_model.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/working_times_entity.dart';

class EmployeeService {
  final RxList<EmployeeEntity> employeeList = <EmployeeEntity>[].obs;

  final RxList<WorkingTimesEntity> workingTimesList =
      <WorkingTimesEntity>[].obs;

  final RxList<FinancialDuesModel> financialDuesList =
      <FinancialDuesModel>[].obs;

  Rxn<QrGenerationModel> qrGeneration = Rxn<QrGenerationModel>();

  Rxn<EmployeeDetailsModel> employeeDetails = Rxn<EmployeeDetailsModel>();

  // singleton pattern
  static final EmployeeService _instance = EmployeeService._internal();
  factory EmployeeService() => _instance;
  EmployeeService._internal();
}
