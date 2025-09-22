import 'dart:collection';
import 'dart:io';

import 'package:doctorbike/core/services/initial_bindings.dart';
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
    update();
  }

  final RxBool deleteTask = false.obs;

  final RxBool deleteTasDuplicate = false.obs;

  Map<String, List<EmployeeTaskModel>> ongoingTasksFilter = {};
  Map<String, List<EmployeeTaskModel>> completedTasksFilter = {};
  Map<String, List<EmployeeTaskModel>> canceledTasksFilter = {};

  // get employee tasks
  Future<void> getEmployeeTasks() async {
    if (employeeTaskService.ongoingEmployeeTasks.isEmpty) {
      isLoading(true);
    }

    Map<String, List<EmployeeTaskModel>> sortByMonth(
        Map<String, List<EmployeeTaskModel>> source) {
      final sortedKeys = source.keys.toList()
        ..sort((a, b) {
          final aDate = DateTime.parse("$a-01");
          final bDate = DateTime.parse("$b-01");
          return bDate.compareTo(aDate);
        });

      return LinkedHashMap.fromIterable(
        sortedKeys,
        key: (k) => k,
        value: (k) => source[k]!,
      );
    }

    // ongoing
    final ongoing = await employeeTasksUsecase.call(page: 0);
    for (var task in ongoing) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}";
      employeeTaskService.ongoingEmployeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTaskService.ongoingEmployeeTasks[dateKey]!
          .any((t) => t.taskId == task.taskId)) {
        employeeTaskService.ongoingEmployeeTasks[dateKey]!.add(task);
      }
    }
    ongoingTasksFilter
        .assignAll(sortByMonth(employeeTaskService.ongoingEmployeeTasks));

    // completed
    final completed = await employeeTasksUsecase.call(page: 1);
    for (var task in completed) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}";
      employeeTaskService.completedEmployeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTaskService.completedEmployeeTasks[dateKey]!
          .any((t) => t.taskId == task.taskId)) {
        employeeTaskService.completedEmployeeTasks[dateKey]!.add(task);
      }
    }
    completedTasksFilter
        .assignAll(sortByMonth(employeeTaskService.completedEmployeeTasks));

    // canceled
    final canceled = await employeeTasksUsecase.call(page: 2);
    for (var task in canceled) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}";
      employeeTaskService.canceledEmployeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTaskService.canceledEmployeeTasks[dateKey]!
          .any((t) => t.taskId == task.taskId)) {
        employeeTaskService.canceledEmployeeTasks[dateKey]!.add(task);
      }
    }
    canceledTasksFilter
        .assignAll(sortByMonth(employeeTaskService.canceledEmployeeTasks));

    isLoading(false);
    update();
  }

  // filter employee tasks
  void filterEmployeeTasks() {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);
    final name = employeeNameController.text.trim();

    // ✅ لو مفيش أي شرط فلترة، رجع البيانات الأصلية
    if (from == null && to == null && name.isEmpty) {
      ongoingTasksFilter.assignAll(
          sortTasksByMonth(employeeTaskService.ongoingEmployeeTasks));
      completedTasksFilter.assignAll(
          sortTasksByMonth(employeeTaskService.completedEmployeeTasks));
      canceledTasksFilter.assignAll(
          sortTasksByMonth(employeeTaskService.canceledEmployeeTasks));
      update();
      return;
    }

    // filter tasks
    Map<String, List<EmployeeTaskModel>> filterTasks(
      Map<String, List<EmployeeTaskModel>> source,
    ) {
      final allTasks = source.values.expand((tasks) => tasks).toList();

      final filtered = allTasks.where((task) {
        bool matchesDate = true;
        bool matchesName = true;

        // // البحث في نفس اليوم
        if (from != null && to != null && from.isAtSameMomentAs(to)) {
          final isSameDay = (task.startTime.year == from.year &&
                  task.startTime.month == from.month &&
                  task.startTime.day == from.day) ||
              (task.endTime.year == from.year &&
                  task.endTime.month == from.month &&
                  task.endTime.day == from.day);

          if (!isSameDay) matchesDate = false;
        }
        // البحث في نفس الشهر
        else if (from != null &&
            to != null &&
            from.year == to.year &&
            from.month == to.month) {
          final isSameMonth = (task.startTime.year == from.year &&
                  task.startTime.month == from.month) ||
              (task.endTime.year == from.year &&
                  task.endTime.month == from.month);

          if (!isSameMonth) matchesDate = false;
        }
        //  البحث بالمدى الزمني
        else {
          if (from != null) {
            final isSameDayAsFrom = task.startTime.year == from.year &&
                task.startTime.month == from.month &&
                task.startTime.day == from.day;

            if (task.endTime.isBefore(from) && !isSameDayAsFrom) {
              matchesDate = false;
            }
          }
          if (to != null) {
            final isSameDayAsTo = task.endTime.year == to.year &&
                task.endTime.month == to.month &&
                task.endTime.day == to.day;

            if (task.startTime.isAfter(to) && !isSameDayAsTo) {
              matchesDate = false;
            }
          }
        }

        // 🔹 فلترة بالاسم
        if (name.isNotEmpty &&
            !task.employeeName.toLowerCase().contains(name.toLowerCase())) {
          matchesName = false;
        }

        return matchesDate && matchesName;
      }).toList();

      // ✅ ترتيب التاسكات حسب startTime
      filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

      // 🔹 إعادة التجميع: باليوم
      final Map<String, List<EmployeeTaskModel>> grouped = {};
      for (var task in filtered) {
        String dateKey =
            "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}-${task.startTime.day.toString().padLeft(2, '0')}";
        grouped.putIfAbsent(dateKey, () => []).add(task);
      }

      // ✅ ترتيب الأيام (من الأحدث للأقدم)
      final sortedKeys = grouped.keys.toList()
        ..sort((a, b) {
          final aDate = DateTime.parse(a);
          final bDate = DateTime.parse(b);
          return bDate.compareTo(aDate); // تنازلي
        });

      return LinkedHashMap.fromIterable(
        sortedKeys,
        key: (k) => k,
        value: (k) => grouped[k]!,
      );
    }

    // ✅ تطبيق الفلترة على التلات مابات
    ongoingTasksFilter = filterTasks(employeeTaskService.ongoingEmployeeTasks);
    completedTasksFilter =
        filterTasks(employeeTaskService.completedEmployeeTasks);
    canceledTasksFilter =
        filterTasks(employeeTaskService.canceledEmployeeTasks);

    update();
  }

  // cancel employee task
  void cancelEmployeeTask({
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
    isLoading(false);
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

  Map<String, List<EmployeeTaskModel>> sortTasksByMonth(
    Map<String, List<EmployeeTaskModel>> source,
  ) {
    final sortedKeys = source.keys.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse("$a-01");
        final dateB = DateTime.parse("$b-01");
        return dateB.compareTo(dateA); // ترتيب تنازلي (الأحدث الأول)
      });

    final Map<String, List<EmployeeTaskModel>> sorted = {};
    for (var key in sortedKeys) {
      sorted[key] = source[key]!;
    }
    return sorted;
  }

  @override
  void onInit() {
    super.onInit();
    userType == 'admin' ? getEmployeeTasks() : null;
    ongoingTasksFilter
        .assignAll(sortTasksByMonth(employeeTaskService.ongoingEmployeeTasks));
    completedTasksFilter.assignAll(
        sortTasksByMonth(employeeTaskService.completedEmployeeTasks));
    canceledTasksFilter
        .assignAll(sortTasksByMonth(employeeTaskService.canceledEmployeeTasks));
    update();
    final String taskId = args?['taskId'] ?? '';
    if (taskId.isNotEmpty) {
      getTaskDetails(taskId: taskId);
    }
  }

  @override
  void onClose() {
    super.onClose();
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
  }
}
