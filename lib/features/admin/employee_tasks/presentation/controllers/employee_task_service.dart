import 'package:get/get.dart';

import '../../data/models/employee_task_model.dart';

class EmployeeTaskService {
  final RxList<EmployeeTaskModel> employeeTasksList = <EmployeeTaskModel>[].obs;

  // singleton pattern
  static final EmployeeTaskService _instance = EmployeeTaskService._internal();
  factory EmployeeTaskService() => _instance;
  EmployeeTaskService._internal();
}
