import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import 'employee_task_service.dart';

class EmployeeTasksController extends GetxController {
  EmployeeTasksUsecase employeeTasksUsecase;
  EmployeeTaskService employeeTaskService;
  CancelEmployeeTaskUsecase cancelEmployeeTaskUsecase;

  EmployeeTasksController({
    required this.employeeTasksUsecase,
    required this.employeeTaskService,
    required this.cancelEmployeeTaskUsecase,
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
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
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
