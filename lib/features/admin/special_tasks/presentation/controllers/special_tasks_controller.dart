import 'dart:collection';

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
  final SpecialTasksUsecase specialTasksUsecase;
  final CompletedSpecialTasksUsecase completedSpecialTasksUsecase;
  final SpecialTaskDetailsUsecase specialTaskDetailsUsecase;
  final CancelSpecialTaskUsecase cancelSpecialTaskUsecase;
  final SubsSpecialTaskCompletedUsecase subsSpecialTaskCompletedUsecase;
  final SpecialTasksService specialTasksService;

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

  final RxInt currentTab = 0.obs;

  final tabs = ['weeklyTasks', 'noDateTasks', 'archive'].obs;

  final isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final RxMap<String, RxBool> checkedMap = <String, RxBool>{}.obs;

  final RxBool transferTask = false.obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
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

  Map<String, List<SpecialTaskModel>> sortByDate(
      Map<String, List<SpecialTaskModel>> source) {
    final sortedKeys = source.keys.toList()
      ..sort((a, b) {
        final aDate = a;
        final bDate = b;
        return bDate.compareTo(aDate);
      });

    return LinkedHashMap.fromIterable(
      sortedKeys,
      key: (k) => k,
      value: (k) => source[k]!,
    );
  }

// // ✅ دالة مساعدة لترتيب الـ Map حسب التاريخ
//   Map<String, List<SpecialTaskModel>> sortByDate(
//       Map<String, List<SpecialTaskModel>> source) {
//     final entries = source.entries.toList();

//     entries.sort((a, b) {
//       final dateA = a.value.first.endDate;
//       final dateB = b.value.first.endDate;
//       return dateB.compareTo(dateA);
//     });

//     return Map.fromEntries(entries);
//   }

  // Get special Tasks
  Future<void> getSpecialTasks({bool scrollToTodayb = true}) async {
    // specialTasksService.weeklyTasks.isEmpty ?
    isLoading(true);
    //  : null;
    update();
    specialTasksService.weeklyTasks.clear();
    specialTasksService.noDateTasks.clear();
    specialTasksService.archivedTasks.clear();
    final weeklyresult = await specialTasksUsecase.call(page: '0');
    for (var task in weeklyresult) {
      String dateKey =
          "${task.startDate.year}-${task.startDate.month.toString().padLeft(2, '0')}-${task.startDate.day.toString().padLeft(2, '0')}";
      if (specialTasksService.weeklyTasks.containsKey(dateKey)) {
        if (!specialTasksService.weeklyTasks[dateKey]!
            .any((t) => t.id == task.id)) {
          specialTasksService.weeklyTasks[dateKey]!.add(task);
        }
      } else {
        specialTasksService.weeklyTasks[dateKey] = [task];
      }
    }
    filteredWeeklyTasks
        .assignAll(filterByRange(sortByDate(specialTasksService.weeklyTasks)));

    final noDateresult = await specialTasksUsecase.call(page: '1');
    for (var task in noDateresult) {
      String dateKey =
          "${task.startDate.year}-${task.startDate.month.toString().padLeft(2, '0')}-${task.startDate.day.toString().padLeft(2, '0')}";
      if (specialTasksService.noDateTasks.containsKey(dateKey)) {
        if (!specialTasksService.noDateTasks[dateKey]!
            .any((t) => t.id == task.id)) {
          specialTasksService.noDateTasks[dateKey]!.add(task);
        }
      } else {
        specialTasksService.noDateTasks[dateKey] = [task];
      }
    }
    filteredNoDateTasks.assignAll(sortByDate(specialTasksService.noDateTasks));

    final archivedresult = await specialTasksUsecase.call(page: '2');
    for (var task in archivedresult) {
      String dateKey =
          "${task.startDate.year}-${task.startDate.month.toString().padLeft(2, '0')}-${task.startDate.day.toString().padLeft(2, '0')}";
      if (specialTasksService.archivedTasks.containsKey(dateKey)) {
        if (!specialTasksService.archivedTasks[dateKey]!
            .any((t) => t.id == task.id)) {
          specialTasksService.archivedTasks[dateKey]!.add(task);
        }
      } else {
        specialTasksService.archivedTasks[dateKey] = [task];
      }
    }
    filteredArchivedTasks.assignAll(
      filterByRange(sortByDate(specialTasksService.archivedTasks)),
    );

    isLoading(false);
    if (scrollToTodayb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToToday();
      });
    }
    update();
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

    result.fold(
      (failure) {
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
        checkedMap[specialTaskId]!.value = false;
      },
      (success) async {
        Get.back();
        await getSpecialTasks(scrollToTodayb: false);

        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
    );

    isLoading(false);
    update();
  }

  // cancel special Tasks
  void cancelSpecialTasks({required String specialTaskId}) async {
    if (transferTask.value) {
      if (selectedDay.value.isBefore(DateTime.now())) {
        Get.snackbar(
          'error'.tr,
          'transferTaskError'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
        return;
      }
    }
    isLoading(true);
    update();

    final result = await cancelSpecialTaskUsecase.call(
      specialTaskId: specialTaskId,
      repitition: deleteRepeatedTask.value,
      isTransfer: transferTask.value,
      endDate: transferTask.value ? selectedDay.value : null,
    );

    result.fold(
      (failure) {
        Get.snackbar(
          failure.errMessage,
          failure.data['message'],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) async {
        Get.back();
        Get.snackbar(
          success,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
        await getSpecialTasks(scrollToTodayb: false);

        deleteRepeatedTask.value = false;
        deleteTask.value = false;
        transferTask.value = false;
      },
    );
    isLoading(false);
    update();
  }

  // تحديث المهمة الخاصة
  void makeSubsSpecialTaskCompleted(
      BuildContext context, String subTaskId, String specialTaskId) async {
    isLoading(true);
    update();

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
    update();
  }

  // بيانات العرض بعد الفلترة
  final RxMap<String, List<SpecialTaskModel>> filteredWeeklyTasks =
      <String, List<SpecialTaskModel>>{}.obs;
  final RxMap<String, List<SpecialTaskModel>> filteredNoDateTasks =
      <String, List<SpecialTaskModel>>{}.obs;
  final RxMap<String, List<SpecialTaskModel>> filteredArchivedTasks =
      <String, List<SpecialTaskModel>>{}.obs;

  // دالة عامة للفلترة عشان نعيد استخدامها مع التلات Maps
  Map<String, List<SpecialTaskModel>> filterMap(
    Map<String, List<SpecialTaskModel>> source,
  ) {
    final from = DateTime.tryParse(fromDateController.text);
    final to = DateTime.tryParse(toDateController.text);
    final Map<String, List<SpecialTaskModel>> newMap = {};
    source.forEach((key, tasks) {
      final filteredList = tasks.where((task) {
        final start = task.startDate;
        final end = task.startDate;
        if (from != null && to == null) {
          return start.isAtSameMomentAs(from) || start.isAfter(from);
        }
        if (to != null && from == null) {
          return end.isAtSameMomentAs(to) || end.isBefore(to);
        }
        if (from != null && to != null) {
          final startsOk = start.isAtSameMomentAs(from) || start.isAfter(from);
          final endsOk = end.isAtSameMomentAs(to) || end.isBefore(to);
          return startsOk && endsOk;
        }
        return true;
      }).toList();

      if (filteredList.isNotEmpty) {
        newMap[key] = filteredList;
      }
    });

    return newMap;
  }

  void filterLists(bool isFilter) {
    // لو مفيش أي فلترة → رجع البيانات الأصلية كلها
    if (fromDateController.text.isEmpty && toDateController.text.isEmpty) {
      filteredWeeklyTasks
          .assignAll(filterByRange(specialTasksService.weeklyTasks));
      filteredNoDateTasks.assignAll(specialTasksService.noDateTasks);
      filteredArchivedTasks
          .assignAll(filterByRange(specialTasksService.archivedTasks));
      if (isFilter) Get.back();
      update();
      return;
    }

    // فلترة التلات Maps
    filteredWeeklyTasks.assignAll(
      filterMap(filterByRange(specialTasksService.weeklyTasks)),
    );
    filteredNoDateTasks.assignAll(filterMap(specialTasksService.noDateTasks));
    filteredArchivedTasks.assignAll(
      filterMap(filterByRange(specialTasksService.archivedTasks)),
    );

    if (isFilter) Get.back();
    update();
  }

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  Map<String, List<SpecialTaskModel>> filterByRange(
      Map<String, List<SpecialTaskModel>> source) {
    final filtered = <String, List<SpecialTaskModel>>{};

    // نضمن إن الأسبوع دايمًا 7 أيام من السبت للجمعة
    for (int i = 0; i < 7; i++) {
      final currentDay = startDate.add(Duration(days: i));
      final dateKey =
          "${currentDay.year}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}";
      // لو اليوم موجود في الـ source نضيف المهام، لو مش موجود نحط لستة فاضية
      filtered[dateKey] = List<SpecialTaskModel>.from(source[dateKey] ?? []);
    }
    // الترتيب تنازليًا (اختياري)
    return LinkedHashMap.fromEntries(
      filtered.entries.toList()
        ..sort(
            (a, b) => DateTime.parse(b.key).compareTo(DateTime.parse(a.key))),
    );
  }

  void filterDataByDateRange() {
    filteredWeeklyTasks
        .assignAll(filterByRange(specialTasksService.weeklyTasks));
    filteredArchivedTasks
        .assignAll(filterByRange(specialTasksService.archivedTasks));
    update();
  }

  void changeWeek(bool isNext) {
    const int daysInWeek = 7;
    if (isNext) {
      startDate = startDate.add(const Duration(days: daysInWeek));
    } else {
      startDate = startDate.subtract(const Duration(days: daysInWeek));
    }
    // دايمًا نهاية الأسبوع بعد 6 أيام من البداية
    endDate = startDate.add(const Duration(days: 6));
    // بعد ما نحدث النطاق نفلتر الداتا
    filterDataByDateRange();
    update();
  }

  DateTime getStartOfWeek(DateTime date) {
    // في Flutter: السبت = 6، الأحد = 7
    int weekday = date.weekday;
    // لو اليوم السبت = بداية الأسبوع
    int daysToSubtract = (weekday == 6) ? 0 : (weekday + 1);
    return date.subtract(Duration(days: daysToSubtract));
  }

  final ScrollController scrollController = ScrollController();
  void scrollToToday() {
    DateTime today = DateTime.now();
    DateTime startOfWeek = getStartOfWeek(today);
    int todayIndex = today.difference(startOfWeek).inDays;

    // نحرك بناءً على index اليوم (0 = السبت، 6 = الجمعة)
    double position = todayIndex * 120.0; // عرض العنصر تقريبًا أو حجمه الرأسي
    scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onInit() {
    super.onInit();
    startDate = getStartOfWeek(DateTime.now());
    endDate = startDate.add(const Duration(days: 6));
    getSpecialTasks();
    filteredWeeklyTasks.assignAll(
      filterByRange(sortByDate(specialTasksService.weeklyTasks)),
    );
    filteredNoDateTasks.assignAll(sortByDate(specialTasksService.noDateTasks));
    filteredArchivedTasks.assignAll(
      filterByRange(sortByDate(specialTasksService.archivedTasks)),
    );
    // fromDateController.addListener(filterLists);
    // toDateController.addListener(filterLists);
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
