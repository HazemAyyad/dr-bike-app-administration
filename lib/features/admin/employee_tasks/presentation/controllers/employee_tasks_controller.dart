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
  Map<String, List<EmployeeTaskModel>> employeeTasksFilter = {};

// get employee tasks
  Future<void> getEmployeeTasks() async {
    employeeTasks.clear();
    employeeTasksFilter.clear();
    isLoading(true);

    final result = await employeeTasksUsecase.call(page: currentTab.value);

    for (var task in result) {
      String dateKey = "${task.endTime.year}-${task.endTime.month}";

      employeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTasks[dateKey]!.any((t) => t.taskId == task.taskId)) {
        employeeTasks[dateKey]!.add(task);
      }

      // خلي الفلتر نسخة طبق الأصل من الأصل
      employeeTasksFilter.putIfAbsent(dateKey, () => []);
      if (!employeeTasksFilter[dateKey]!.any((t) => t.taskId == task.taskId)) {
        employeeTasksFilter[dateKey]!.add(task);
      }
    }

    isLoading(false);
    update();
  }

  void filterEmployeeTasks() {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);
    final name = employeeNameController.text.trim();

    final allTasks = employeeTasks.values.expand((tasks) => tasks).toList();

    if (from == null && to == null && name.isEmpty) {
      employeeTasksFilter = Map.from(employeeTasks);
      update();
      return;
    }

    final filtered = allTasks.where((task) {
      bool matchesDate = true;
      bool matchesName = true;

      if (from != null && to != null && from.isAtSameMomentAs(to)) {
        // 🔹 البحث في نفس اليوم فقط
        final sameDay = task.endTime.year == from.year &&
            task.endTime.month == from.month &&
            task.endTime.day == from.day;
        if (!sameDay) matchesDate = false;
      } else {
        // 🔹 المدى الزمني (من → إلى)
        if (from != null) {
          final isSameDayAsFrom = task.endTime.year == from.year &&
              task.endTime.month == from.month &&
              task.endTime.day == from.day;
          if (task.endTime.isBefore(from) && !isSameDayAsFrom)
            matchesDate = false;
        }
        if (to != null) {
          final isSameDayAsTo = task.endTime.year == to.year &&
              task.endTime.month == to.month &&
              task.endTime.day == to.day;
          if (task.endTime.isAfter(to) && !isSameDayAsTo) matchesDate = false;
        }
      }

      // 🔹 فلترة الاسم
      if (name.isNotEmpty &&
          !task.employeeName.toLowerCase().contains(name.toLowerCase())) {
        matchesName = false;
      }

      return matchesDate && matchesName;
    }).toList();

    // إعادة التجميع
    final Map<String, List<EmployeeTaskModel>> grouped = {};
    for (var task in filtered) {
      String dateKey = "${task.endTime.year}-${task.endTime.month}";
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }

    employeeTasksFilter = grouped;
    update();
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
    deleteTasDuplicate.value = false;
    deleteTask.value = false;
    update();
  }

  // upload task image
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
