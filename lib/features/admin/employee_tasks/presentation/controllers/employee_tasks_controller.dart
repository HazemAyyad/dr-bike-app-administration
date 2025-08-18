import 'package:doctorbike/features/admin/employee_tasks/data/models/task_details_model.dart';
import 'package:doctorbike/features/admin/employee_tasks/domain/usecases/get_task_details_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import 'employee_task_service.dart';

class EmployeeTasksController extends GetxController {
  EmployeeTasksUsecase employeeTasksUsecase;
  EmployeeTaskService employeeTaskService;
  CancelEmployeeTaskUsecase cancelEmployeeTaskUsecase;
  GetTaskDetailsUsecase getTaskDetailsUsecase;

  EmployeeTasksController({
    required this.employeeTasksUsecase,
    required this.employeeTaskService,
    required this.cancelEmployeeTaskUsecase,
    required this.getTaskDetailsUsecase,
  });
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final employeeNameController = TextEditingController();

  RxInt currentTab = 0.obs;

  final tabs = ['employeeActiveTasks', 'employeeCompletedTasks', 'archive'].obs;

  RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    employeeTaskService.employeeTasksList.clear();
    getEmployeeTasks();
  }

  final RxBool deleteTask = false.obs;

  final RxBool deleteTasDuplicate = false.obs;

  void getEmployeeTasks() async {
    employeeTaskService.employeeTasksList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    final result = await employeeTasksUsecase.call(page: currentTab.value);
    employeeTaskService.employeeTasksList.assignAll(result);
    isLoading(false);
  }

  // cancel employee task
  void cancelEmployeeTask({
    required BuildContext context,
    required String taskId,
    required bool cancelWithRepetition,
  }) async {
    isLoading(true);

    final result = await cancelEmployeeTaskUsecase.call(
        employeeTaskId: taskId, cancelWithRepetition: cancelWithRepetition);
    result.fold(
      (failure) {
        Get.back();
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) {
        Get.back();
        Get.find<EmployeeTasksController>().getEmployeeTasks();
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            Get.snackbar(
              'success'.tr,
              success,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(milliseconds: 1500),
            );
          },
        );
      },
    );
    deleteTasDuplicate.value = false;
    deleteTask.value = false;
    isLoading(false);
  }

  final RxBool isTaskDetailsLoading = false.obs;
  // task details
  void getTaskDetails({required String taskId}) async {
    taskId == employeeTaskService.taskDetails.value?.taskId.toString()
        ? isTaskDetailsLoading(false)
        : isTaskDetailsLoading(true);

    final result = await getTaskDetailsUsecase.call(taskId: taskId);
    employeeTaskService.taskDetails.value =
        TaskDetailsModel.fromJson(result['employee_task']);
    employeeTaskService.subtaskAdminImgPath.value =
        ImagesPathInfoModel.fromJson(result['images_path_info']);
    isTaskDetailsLoading(false);
  }

  @override
  void onInit() {
    super.onInit();
    getEmployeeTasks();
  }

  @override
  void dispose() {
    super.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
  }
}
