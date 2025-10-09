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

  Map<String, List<EmployeeTaskModel>> sortByDate(
      Map<String, List<EmployeeTaskModel>> source) {
    final sortedKeys = source.keys.toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a);
        final bDate = DateTime.parse(b);
        return bDate.compareTo(aDate);
      });

    return LinkedHashMap.fromIterable(
      sortedKeys,
      key: (k) => k,
      value: (k) => source[k]!,
    );
  }

  Map<String, List<EmployeeTaskModel>> ongoingTasksFilter = {};
  Map<String, List<EmployeeTaskModel>> completedTasksFilter = {};
  Map<String, List<EmployeeTaskModel>> canceledTasksFilter = {};

  // get employee tasks
  Future<void> getEmployeeTasks() async {
    // if (employeeTaskService.ongoingEmployeeTasks.isEmpty) {
    isLoading(true);
    update();
    // }
    employeeTaskService.ongoingEmployeeTasks.clear();
    employeeTaskService.completedEmployeeTasks.clear();
    employeeTaskService.canceledEmployeeTasks.clear();
    // ongoing
    final ongoing = await employeeTasksUsecase.call(page: 0);
    for (var task in ongoing) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}-${task.startTime.day.toString().padLeft(2, '0')}";
      employeeTaskService.ongoingEmployeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTaskService.ongoingEmployeeTasks[dateKey]!
          .any((t) => t.taskId == task.taskId)) {
        employeeTaskService.ongoingEmployeeTasks[dateKey]!.add(task);
      }
    }
    ongoingTasksFilter.assignAll(
        filterByRange(sortByDate(employeeTaskService.ongoingEmployeeTasks)));

    // completed
    final completed = await employeeTasksUsecase.call(page: 1);
    for (var task in completed) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}-${task.startTime.day.toString().padLeft(2, '0')}";
      employeeTaskService.completedEmployeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTaskService.completedEmployeeTasks[dateKey]!
          .any((t) => t.taskId == task.taskId)) {
        employeeTaskService.completedEmployeeTasks[dateKey]!.add(task);
      }
    }
    completedTasksFilter
        .assignAll(sortByDate(employeeTaskService.completedEmployeeTasks));

    // canceled
    final canceled = await employeeTasksUsecase.call(page: 2);
    for (var task in canceled) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}-${task.startTime.day.toString().padLeft(2, '0')}";
      employeeTaskService.canceledEmployeeTasks.putIfAbsent(dateKey, () => []);
      if (!employeeTaskService.canceledEmployeeTasks[dateKey]!
          .any((t) => t.taskId == task.taskId)) {
        employeeTaskService.canceledEmployeeTasks[dateKey]!.add(task);
      }
    }
    canceledTasksFilter.assignAll(
        filterByRange(sortByDate(employeeTaskService.canceledEmployeeTasks)));

    isLoading(false);
    update();
  }

  // filter tasks
  Map<String, List<EmployeeTaskModel>> filterTasks(
    Map<String, List<EmployeeTaskModel>> source,
  ) {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);
    final name = employeeNameController.text.trim();

    final allTasks = source.values.expand((tasks) => tasks).toList();

    final filtered = allTasks.where((task) {
      bool matchesDate = true;
      bool matchesName = true;

      // البحث في نفس اليوم
      if (from != null && to != null && from.isAtSameMomentAs(to)) {
        final isSameDay = task.startTime.year == from.year &&
            task.startTime.month == from.month &&
            task.startTime.day == from.day;
        if (!isSameDay) matchesDate = false;
      }

      // البحث بالمدى الزمني (يومي)
      else {
        if (from != null && to != null) {
          final taskStart = DateTime(
              task.startTime.year, task.startTime.month, task.startTime.day);
          final taskEnd =
              DateTime(task.endTime.year, task.endTime.month, task.endTime.day);
          final fromDay = DateTime(from.year, from.month, from.day);
          final toDay = DateTime(to.year, to.month, to.day);

          if (taskEnd.isBefore(fromDay) || taskStart.isAfter(toDay)) {
            matchesDate = false;
          }
        } else if (from != null) {
          final taskStart = DateTime(
              task.startTime.year, task.startTime.month, task.startTime.day);
          final fromDay = DateTime(from.year, from.month, from.day);
          if (taskStart.isBefore(fromDay)) matchesDate = false;
        } else if (to != null) {
          final taskEnd =
              DateTime(task.endTime.year, task.endTime.month, task.endTime.day);
          final toDay = DateTime(to.year, to.month, to.day);
          if (taskEnd.isAfter(toDay)) matchesDate = false;
        }
      }

      // فلترة بالاسم
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

  // filter employee tasks
  void filterEmployeeTasks() {
    // ✅ لو مفيش أي شرط فلترة، رجع البيانات الأصلية
    if (fromDateController.text.isEmpty &&
        toDateController.text.isEmpty &&
        employeeNameController.text.isEmpty) {
      ongoingTasksFilter.assignAll(
        filterByRange(sortByDate(employeeTaskService.ongoingEmployeeTasks)),
      );
      completedTasksFilter
          .assignAll(sortByDate(employeeTaskService.completedEmployeeTasks));
      canceledTasksFilter.assignAll(
        filterByRange(sortByDate(employeeTaskService.canceledEmployeeTasks)),
      );
      update();
      return;
    }
    // ✅ تطبيق الفلترة على التلات مابات
    ongoingTasksFilter =
        filterByRange(filterTasks(employeeTaskService.ongoingEmployeeTasks));
    completedTasksFilter =
        filterTasks(employeeTaskService.completedEmployeeTasks);
    canceledTasksFilter =
        filterByRange(filterTasks(employeeTaskService.canceledEmployeeTasks));
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
      (success) {
        getEmployeeTasks();
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

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));

  Map<String, List<EmployeeTaskModel>> filterByRange(
      Map<String, List<EmployeeTaskModel>> source) {
    final filtered = <String, List<EmployeeTaskModel>>{};

    source.forEach((key, tasks) {
      DateTime dateKey;
      try {
        dateKey = DateTime.parse(key);
      } catch (_) {
        return;
      }

      if (dateKey.isAfter(startDate.subtract(const Duration(days: 1))) &&
          dateKey.isBefore(endDate.add(const Duration(days: 1)))) {
        filtered[key] = tasks;
      }
    });

    return sortByDate(filtered);
  }

  void filterDataByDateRange() {
    ongoingTasksFilter
        .assignAll(sortByDate(employeeTaskService.ongoingEmployeeTasks));
    canceledTasksFilter
        .assignAll(sortByDate(employeeTaskService.canceledEmployeeTasks));

    ongoingTasksFilter.assignAll(
      filterTasks(
        filterByRange(sortByDate(employeeTaskService.ongoingEmployeeTasks)),
      ),
    );
    canceledTasksFilter.assignAll(
      filterTasks(
        filterByRange(sortByDate(employeeTaskService.canceledEmployeeTasks)),
      ),
    );
    update();
  }

  void changeWeek(bool isNext) {
    const int daysInWeek = 8;

    if (isNext) {
      startDate = startDate.add(const Duration(days: daysInWeek));
      endDate = endDate.add(const Duration(days: daysInWeek));
    } else {
      startDate = startDate.subtract(const Duration(days: daysInWeek));
      endDate = endDate.subtract(const Duration(days: daysInWeek));
    }
    // بعد التغيير، نفلتر الداتا حسب المدى الجديد
    filterDataByDateRange();
    update();
  }

  @override
  void onInit() {
    super.onInit();
    employeePermissions.contains(7) ? getEmployeeTasks() : null;
    ongoingTasksFilter.assignAll(
        filterByRange(sortByDate(employeeTaskService.ongoingEmployeeTasks)));
    completedTasksFilter
        .assignAll(sortByDate(employeeTaskService.completedEmployeeTasks));
    canceledTasksFilter.assignAll(
        filterByRange(sortByDate(employeeTaskService.canceledEmployeeTasks)));
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
