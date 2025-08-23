import 'package:doctorbike/features/admin/special_tasks/domain/usecases/subs_pecial_task_completed_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
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
  SubsSpecialTaskCompletedUsecase subsSpecialTaskCompletedUsecase;
  SpecialTasksService specialTasksService;

  SpecialTasksController({
    required this.specialTasksUsecase,
    required this.specialTasksService,
    required this.specialTaskDetailsUsecase,
    required this.cancelSpecialTaskUsecase,
    required this.completedSpecialTasksUsecase,
    required this.subsSpecialTaskCompletedUsecase,
  });

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  RxInt currentTab = 0.obs;

  final tabs = ['weeklyTasks', 'noDateTasks', 'archive'].obs;

  final isLoading = false.obs;

  void changeTab(int index) async {
    currentTab.value = index;
    await getSpecialTasks();
    filterLists(false);
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

  final RxMap<String, List<SpecialTaskModel>> groupedTasks =
      <String, List<SpecialTaskModel>>{}.obs;

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

  final RxBool isGetLoading = false.obs;

  // Get special Tasks Details
  Future<void> getSpecialTasksDetails({required String specialTaskId}) async {
    if (specialTasksService.specialTaskDetails.value != null) {
      specialTasksService.specialTaskDetails.value!.taskId.toString() ==
              specialTaskId
          ? isGetLoading(false)
          : isGetLoading(true);
    } else {
      isGetLoading(true);
    }

    final result =
        await specialTaskDetailsUsecase.call(specialTaskId: specialTaskId);
    specialTasksService.specialTaskDetails.value = result;
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

  // تحديث المهمة الخاصة
  void makeSubsSpecialTaskCompleted(
      BuildContext context, String subTaskId, String specialTaskId) async {
    isLoading(true);

    final result =
        await subsSpecialTaskCompletedUsecase.call(subTaskId: subTaskId);
    result.fold(
      (failure) {
        final errors = failure.data != null ? failure.data['errors'] : null;

        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((list) => list)
              .cast<String>()
              .join('')
              .replaceAll('.', '- \n');

          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: messages,
          );
        } else {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: "Unexpected error occurred",
          );
        }
      },
      (success) {
        getSpecialTasksDetails(specialTaskId: specialTaskId);
        getSpecialTasks();

        Future.delayed(
          const Duration(seconds: 2),
          () {
            Get.back();
            // Get.back();
          },
        );
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
      },
    );
    isLoading(false);
  }

  // بيانات العرض بعد الفلترة
  final RxMap<String, List<SpecialTaskModel>> filteredTasks =
      <String, List<SpecialTaskModel>>{}.obs;

  void filterLists(bool isFilter) {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);

    if (from == null && to == null) {
      filteredTasks.assignAll(groupedTasks);
      isFilter ? Get.back() : null;
      return;
    }

    final Map<String, List<SpecialTaskModel>> newMap = Map.fromEntries(
      groupedTasks.entries.map((entry) {
        final list = entry.value.where((task) {
          final start = task.startDate;
          final end = task.endDate;
          // لو فيه from فقط
          if (from != null && to == null) {
            return start.isAtSameMomentAs(from) || start.isAfter(from);
          }
          // لو فيه to فقط
          if (to != null && from == null) {
            return end.isAtSameMomentAs(to) || end.isBefore(to);
          }
          // لو الاتنين موجودين
          if (from != null && to != null) {
            final startsOk =
                start.isAtSameMomentAs(from) || start.isAfter(from);
            final endsOk = end.isAtSameMomentAs(to) || end.isBefore(to);
            return startsOk && endsOk;
          }
          return true;
        }).toList();
        return MapEntry(entry.key, list);
      }).where((e) => e.value.isNotEmpty),
    );

    filteredTasks.assignAll(newMap);
    isFilter ? Get.back() : null;
  }

  @override
  void onInit() {
    super.onInit();
    getSpecialTasks();
    filteredTasks.assignAll(groupedTasks);

    // شغّل الفلترة تلقائيًا عند الكتابة
    // fromDateController.addListener(filterLists);
    // toDateController.addListener(filterLists);
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }
}
