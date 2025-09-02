import 'dart:io';

import 'package:doctorbike/features/admin/employee_tasks/data/models/task_details_model.dart';
import 'package:doctorbike/features/admin/employee_tasks/domain/usecases/get_task_details_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/employee_task_model.dart';
import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import '../../domain/usecases/upload_task_image_usecase.dart';
import 'employee_task_service.dart';

class EmployeeTasksController extends GetxController {
  final EmployeeTasksUsecase employeeTasksUsecase;
  final EmployeeTaskService employeeTaskService;
  final CancelEmployeeTaskUsecase cancelEmployeeTaskUsecase;
  final GetTaskDetailsUsecase getTaskDetailsUsecase;
  final UploadTaskImageUsecase uploadTaskImageUsecase;

  EmployeeTasksController({
    required this.employeeTasksUsecase,
    required this.employeeTaskService,
    required this.cancelEmployeeTaskUsecase,
    required this.getTaskDetailsUsecase,
    required this.uploadTaskImageUsecase,
  });

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final employeeNameController = TextEditingController();

  final args = Get.arguments as Map<String, dynamic>?;

  RxInt currentTab = 0.obs;

  final tabs = ['employeeActiveTasks', 'employeeCompletedTasks', 'archive'].obs;

  RxBool isLoading = false.obs;

  List<File> selectedFile = [];

  void changeTab(int index) {
    currentTab.value = index;
    getEmployeeTasks();
  }

  final RxBool deleteTask = false.obs;

  final RxBool deleteTasDuplicate = false.obs;

  Map<String, List<EmployeeTaskModel>> employeeTasks = {};

  // get employee tasks
  Future<void> getEmployeeTasks() async {
    employeeTasks.clear();
    isLoading(true);
    final result = await employeeTasksUsecase.call(page: currentTab.value);
    for (var task in result) {
      String dateKey = "${task.endTime.year}-${task.endTime.month}";
      if (employeeTasks.containsKey(dateKey)) {
        if (!employeeTasks[dateKey]!.any((t) => t.taskId == task.taskId)) {
          employeeTasks[dateKey]!.add(task);
        }
      } else {
        employeeTasks[dateKey] = [task];
      }
    }
    isLoading(false);
  }

  // cancel employee task
  void cancelEmployeeTask({
    required BuildContext context,
    required String taskId,
    required bool cancelWithRepetition,
    bool isCompleted = false,
  }) async {
    isLoading(true);
    isCompleted ? uploadTaskImage(taskId: taskId) : null;
    final result = await cancelEmployeeTaskUsecase.call(
      employeeTaskId: taskId,
      cancelWithRepetition: cancelWithRepetition,
      isCompleted: isCompleted,
    );

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
      (success) async {
        getEmployeeTasks();
        await Get.find<EmployeeTasksController>().getEmployeeTasks();
        Get.back();
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
    // Get.find<EmployeeTasksController>().getEmployeeTasks();

    deleteTasDuplicate.value = false;
    deleteTask.value = false;
    // isLoading(false);
    update();
  }

  // task details
  void uploadTaskImage({required String taskId}) async {
    selectedFile.isNotEmpty
        ? {
            isLoading(true),
            await uploadTaskImageUsecase.call(
              taskId: taskId,
              image: selectedFile,
            ),
            Get.back(),
            isLoading(false),
          }
        : null;
    // isTaskDetailsLoading(false);
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
    isTaskDetailsLoading(false);
  }

  @override
  void onInit() {
    super.onInit();
    getEmployeeTasks();
    final String taskId = args?['taskId'] ?? '';
    if (taskId.isNotEmpty) {
      getTaskDetails(taskId: taskId);
    }
  }

  @override
  void dispose() {
    super.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
  }
}
