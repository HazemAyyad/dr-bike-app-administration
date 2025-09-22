import 'package:get/get.dart';

import '../../data/models/employee_task_model.dart';
import '../../data/models/task_details_model.dart';

class EmployeeTaskService {
  Map<String, List<EmployeeTaskModel>> ongoingEmployeeTasks = {};

  Map<String, List<EmployeeTaskModel>> completedEmployeeTasks = {};

  Map<String, List<EmployeeTaskModel>> canceledEmployeeTasks = {};

  final Rx<TaskDetailsModel?> taskDetails = Rx<TaskDetailsModel?>(null);

  final Rx<ImagesPathInfoModel?> subtaskAdminImgPath =
      Rx<ImagesPathInfoModel?>(null);

  // singleton pattern
  static final EmployeeTaskService _instance = EmployeeTaskService._internal();
  factory EmployeeTaskService() => _instance;
  EmployeeTaskService._internal();
}
