import 'package:get/get.dart';

import '../../data/models/task_details_model.dart';

class EmployeeTaskService {
  // final RxList<EmployeeTaskModel> employeeTasksList = <EmployeeTaskModel>[].obs;

  final Rx<TaskDetailsModel?> taskDetails = Rx<TaskDetailsModel?>(null);

  final Rx<ImagesPathInfoModel?> subtaskAdminImgPath =
      Rx<ImagesPathInfoModel?>(null);

  // singleton pattern
  static final EmployeeTaskService _instance = EmployeeTaskService._internal();
  factory EmployeeTaskService() => _instance;
  EmployeeTaskService._internal();
}
