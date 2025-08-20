import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/special_task_details_model.dart';
import '../../data/models/special_task_model.dart';
import '../../domain/usecases/cancel_special_task_usecase.dart';
import '../../domain/usecases/completed_special_tasks_usecase.dart';
import '../../domain/usecases/special_task_details_usecase.dart';
import '../../domain/usecases/special_tasks_usecase.dart';
import 'special_tasks_service.dart';

class SpecialTasksController extends GetxController {
  SpecialTasksUsecase specialTasksUsecase;
  CompletedSpecialTasksUsecase completedSpecialTasksUsecase;
  SpecialTaskDetailsUsecase specialTaskDetailsUsecase;
  CancelSpecialTaskUsecase cancelSpecialTaskUsecase;
  SpecialTasksService specialTasksService;

  SpecialTasksController({
    required this.specialTasksUsecase,
    required this.specialTasksService,
    required this.specialTaskDetailsUsecase,
    required this.cancelSpecialTaskUsecase,
    required this.completedSpecialTasksUsecase,
  });

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  RxInt currentTab = 0.obs;

  final tabs = ['weeklyTasks', 'noDateTasks', 'archive'].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    getSpecialTasks();
  }

  final RxMap<String, RxBool> checkedMap = <String, RxBool>{}.obs;

  final RxBool transferTask = false.obs;
  Rx<DateTime> selectedDay = DateTime.now().obs;
  final dayController = TextEditingController();

  final List<String> daysList = [
    "saturday".tr,
    "sunday".tr,
    "monday".tr,
    "tuesday".tr,
    "wednesday".tr,
    "thursday".tr,
    "friday".tr,
  ];
  final RxBool deleteTask = false.obs;

  final RxBool deleteRepeatedTask = false.obs;

  void setOnlyOneTrue(String key) {
    transferTask.value = key == 'transferTask';
    deleteTask.value = key == 'deleteTask';
    deleteRepeatedTask.value = key == 'deleteRepeatedTask';
  }

  Map<String, List<SpecialTaskModel>> groupedTasks = {};

  // Get special Tasks
  Future<void> getSpecialTasks() async {
    groupedTasks.clear();

    isLoading(true);
    final result =
        await specialTasksUsecase.call(page: currentTab.value.toString());

    for (var task in result) {
      String dateKey =
          "${task.endDate.year}-${task.endDate.month}-${task.endDate.day}";
      if (groupedTasks.containsKey(dateKey)) {
        if (!groupedTasks[dateKey]!.any((t) => t.id == task.id)) {
          groupedTasks[dateKey]!.add(task);
        }
      } else {
        groupedTasks[dateKey] = [task];
      }
    }
    isLoading(false);
  }

  Rxn<SpecialTaskDetailsModel> specialTaskDetails =
      Rxn<SpecialTaskDetailsModel>();

  final RxBool isGetLoading = false.obs;

  // Get special Tasks Details
  Future<void> getSpecialTasksDetails({required String specialTaskId}) async {
    isGetLoading(true);
    final result =
        await specialTaskDetailsUsecase.call(specialTaskId: specialTaskId);
    specialTaskDetails.value = result;
    isGetLoading(false);
  }

  // complete special Tasks
  void completedSpecialTasks(BuildContext context, String specialTaskId) async {
    // isLoading(true);
    final result =
        await completedSpecialTasksUsecase.call(specialTaskId: specialTaskId);
    await getSpecialTasks();

    result.fold(
      (failure) {
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
        checkedMap[specialTaskId]!.value = false;
      },
      (success) {
        Get.snackbar(
          success,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
  }

  // cancel special Tasks
  void cancelSpecialTasks({required String specialTaskId}) async {
    if (transferTask.value) {
      if (selectedDay.value.isBefore(DateTime.now())) {
        Get.snackbar(
          'error'.tr,
          'transferTaskError'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
        return;
      }
    }
    isLoading(true);
    final result = await cancelSpecialTaskUsecase.call(
      specialTaskId: specialTaskId,
      repitition: deleteRepeatedTask.value,
      isTransfer: transferTask.value,
      endDate: transferTask.value ? selectedDay.value : null,
    );
    await getSpecialTasks();

    result.fold(
      (failure) {
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) {
        Get.back();
        Get.snackbar(
          success,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
        deleteRepeatedTask.value = false;
        deleteTask.value = false;
        transferTask.value = false;
      },
    );
    isLoading(false);
  }

  @override
  void onInit() {
    super.onInit();
    getSpecialTasks();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }
}
