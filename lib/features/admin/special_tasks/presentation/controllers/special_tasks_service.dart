import 'package:get/get.dart';

import '../../data/models/special_task_details_model.dart';

class SpecialTasksService {
  Rxn<SpecialTaskDetailsModel> specialTaskDetails =
      Rxn<SpecialTaskDetailsModel>();

  // final RxList<SpecialTaskModel> specialTaskList = <SpecialTaskModel>[].obs;

  // final RxList<FinancialDuesModel> financialDuesList =
  //     <FinancialDuesModel>[].obs;

  // Rxn<QrGenerationModel> qrGeneration = Rxn<QrGenerationModel>();

  // Rxn<EmployeeDetailsModel> employeeDetails = Rxn<EmployeeDetailsModel>();

  // singleton pattern
  static final SpecialTasksService _instance = SpecialTasksService._internal();
  factory SpecialTasksService() => _instance;
  SpecialTasksService._internal();
}
