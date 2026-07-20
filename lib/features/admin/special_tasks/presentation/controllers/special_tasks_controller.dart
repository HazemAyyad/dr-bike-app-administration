import 'dart:collection';

import 'package:doctorbike/features/admin/special_tasks/domain/usecases/subs_pecial_task_completed_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/app_navigation.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../routes/app_routes.dart';
import '../../../employee_section/domain/entities/employee_entity.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../../employee_section/presentation/controllers/employee_service.dart';
import '../../data/datasources/special_tasks_datasource.dart';
import '../../data/models/special_task_model.dart';
import '../../domain/usecases/cancel_special_task_usecase.dart';
import '../../domain/usecases/completed_special_tasks_usecase.dart';
import '../../domain/usecases/special_task_details_usecase.dart';
import '../../domain/usecases/special_tasks_usecase.dart';
import 'special_tasks_service.dart';

class SpecialTasksController extends GetxController {
  static const String tasksViewDaily = 'daily';
  static const String tasksViewWeekly = 'weekly';
  static const String tasksViewMonthly = 'monthly';

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
  final searchController = TextEditingController();

  final RxInt currentTab = 0.obs;

  final tabs = ['weeklyTasks', 'noDateTasks', 'archive'].obs;
  final RxString tasksViewMode = tasksViewWeekly.obs;

  final isLoading = false.obs;
  final isConvertingTask = false.obs;

  EmployeeService get _employeeService {
    AppDependencyRegistry.ensureEmployeeSection();
    return Get.find<EmployeeService>();
  }

  SpecialTasksDatasource get _specialDs {
    AppDependencyRegistry.ensureSpecialTasks();
    return Get.find<SpecialTasksDatasource>();
  }

  Future<List<EmployeeEntity>> employeesForConversion() async {
    AppDependencyRegistry.ensureEmployeeSection();
    if (_employeeService.employeeList.isNotEmpty) {
      return _employeeService.employeeList;
    }
    final employees = await Get.find<GetAllEmployeeUsecase>().call();
    _employeeService.employeeList.assignAll(employees);
    return employees;
  }

  void changeTab(int index) {
    currentTab.value = index;
    update(['specialTasksList', 'specialPeriodBar', 'specialViewMode']);
  }

  void setTasksViewMode(String mode) {
    tasksViewMode.value = mode;
    syncPeriodBounds(anchor: DateTime.now());
    filterDataByDateRange();
    scrollToToday();
    update(['specialTasksList', 'specialPeriodBar', 'specialViewMode']);
  }

  String get periodLabel {
    if (tasksViewMode.value == tasksViewDaily) {
      return DateFormat('EEEE, d/M/yyyy', Get.locale?.languageCode)
          .format(startDate);
    }
    if (tasksViewMode.value == tasksViewWeekly) {
      final startLabel =
          DateFormat('EEEE d/M', Get.locale?.languageCode).format(startDate);
      return '$startLabel — ${DateFormat('d/M/yyyy').format(endDate)}';
    }
    return '${DateFormat('d/M/yyyy').format(startDate)} — ${DateFormat('d/M/yyyy').format(endDate)}';
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
    if (transferTask.value) {
      final firstAvailable = transferWeekDays.firstWhere(
        (day) => !isPastTransferDay(day),
        orElse: () => transferWeekDays.last,
      );
      selectTransferWeekDay(firstAvailable);
    }
  }

  DateTime get transferWeekStart => getStartOfWeek(startDate);

  List<DateTime> get transferWeekDays => List.generate(
        7,
        (index) => transferWeekStart.add(Duration(days: index)),
      );

  void selectTransferWeekDay(DateTime day) {
    selectedDay.value = DateTime(day.year, day.month, day.day);
  }

  bool isPastTransferDay(DateTime day) {
    final selected = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return selected.isBefore(today);
  }

  Map<String, List<SpecialTaskModel>> sortByDate(
      Map<String, List<SpecialTaskModel>> source) {
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
    update(['specialTasksList']);
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
    filterLists(false);
    if (scrollToTodayb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToToday();
      });
    }
    update(['specialTasksList', 'specialPeriodBar']);
  }

  Future<void> pullToRefresh() => getSpecialTasks(scrollToTodayb: true);

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
      if (isPastTransferDay(selectedDay.value)) {
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

  Future<void> convertSpecialTaskToEmployee({
    required String specialTaskId,
    required int employeeId,
  }) async {
    isConvertingTask(true);
    try {
      final res = await _specialDs.convertSpecialTaskToEmployee(
        specialTaskId: specialTaskId,
        employeeId: employeeId,
      );
      if (res['status'] == 'success') {
        specialTasksService.specialTaskDetails.value = null;
        await getSpecialTasks(scrollToTodayb: false);
        Get.back();
        Get.snackbar(
          'success'.tr,
          '${res['message'] ?? 'taskConvertedToEmployee'.tr}',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      Get.snackbar(
        'error'.tr,
        '${res['message'] ?? ''}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isConvertingTask(false);
    }
  }

  // تحديث المهمة الخاصة
  void makeSubsSpecialTaskCompleted(
      BuildContext context, String subTaskId, String specialTaskId) async {
    final details = specialTasksService.specialTaskDetails.value;
    final pendingSubtasks =
        details?.subTasks.where((s) => s.status != 'completed').length ?? 0;
    final isLastSubtask = pendingSubtasks <= 1;

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
      (success) async {
        Get.back();
        await getSpecialTasksDetails(specialTaskId: specialTaskId);
        getSpecialTasks();

        if (isLastSubtask) {
          Future.delayed(
            const Duration(milliseconds: 650),
            () {
              AppNavigation.popToRoute(AppRoutes.PRIVATETASKSSCREEN);
            },
          );
        }

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
    final query = searchController.text.trim().toLowerCase();
    final Map<String, List<SpecialTaskModel>> newMap = {};
    source.forEach((key, tasks) {
      final filteredList = tasks.where((task) {
        if (query.isNotEmpty && !task.matchesSearchQuery(query)) {
          return false;
        }
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
    if (fromDateController.text.isEmpty &&
        toDateController.text.isEmpty &&
        searchController.text.trim().isEmpty) {
      filteredWeeklyTasks
          .assignAll(filterByRange(specialTasksService.weeklyTasks));
      filteredNoDateTasks.assignAll(specialTasksService.noDateTasks);
      filteredArchivedTasks
          .assignAll(filterByRange(specialTasksService.archivedTasks));
      if (isFilter) Get.back();
      update(['specialTasksList', 'specialPeriodBar']);
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
    update(['specialTasksList', 'specialPeriodBar']);
  }

  void onSearchChanged(String _) {
    filterLists(false);
  }

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  static String dateKeyFrom(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void syncPeriodBounds({DateTime? anchor}) {
    final ref = anchor ?? DateTime.now();
    final day = DateTime(ref.year, ref.month, ref.day);
    switch (tasksViewMode.value) {
      case tasksViewDaily:
        startDate = day;
        endDate = day;
        break;
      case tasksViewMonthly:
        startDate = DateTime(day.year, day.month, 1);
        endDate = DateTime(day.year, day.month + 1, 0);
        break;
      case tasksViewWeekly:
      default:
        startDate = getStartOfWeek(day);
        endDate = startDate.add(const Duration(days: 6));
        break;
    }
  }

  int get _periodDayCount => endDate.difference(startDate).inDays + 1;

  Map<String, List<SpecialTaskModel>> filterByRange(
      Map<String, List<SpecialTaskModel>> source) {
    final filtered = <String, List<SpecialTaskModel>>{};

    for (int i = 0; i < _periodDayCount; i++) {
      final currentDay = startDate.add(Duration(days: i));
      final dateKey = dateKeyFrom(currentDay);
      filtered[dateKey] = List<SpecialTaskModel>.from(source[dateKey] ?? []);
    }

    return LinkedHashMap.fromEntries(
      orderedDisplayKeys(filtered.keys.toList()).map(
        (key) => MapEntry(key, filtered[key]!),
      ),
    );
  }

  List<String> orderedDisplayKeys(List<String> keys) {
    if (keys.isEmpty) return [];
    if (tasksViewMode.value == tasksViewWeekly) {
      return keys.toList()
        ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    }

    final today = dateKeyFrom(DateTime.now());
    final todayDate = DateTime.parse(today);
    final entries = keys.map((k) => MapEntry(k, DateTime.parse(k))).toList();

    final todayEntry = entries.where((e) => e.key == today).toList();
    final future = entries
        .where((e) => e.key != today && !e.value.isBefore(todayDate))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final past = entries.where((e) => e.value.isBefore(todayDate)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      ...todayEntry.map((e) => e.key),
      ...future.map((e) => e.key),
      ...past.map((e) => e.key),
    ];
  }

  void filterDataByDateRange() {
    filterLists(false);
  }

  void changePeriod(bool isNext) {
    switch (tasksViewMode.value) {
      case tasksViewDaily:
        startDate = isNext
            ? startDate.add(const Duration(days: 1))
            : startDate.subtract(const Duration(days: 1));
        endDate = startDate;
        break;
      case tasksViewMonthly:
        final month =
            DateTime(startDate.year, startDate.month + (isNext ? 1 : -1), 1);
        startDate = month;
        endDate = DateTime(month.year, month.month + 1, 0);
        break;
      case tasksViewWeekly:
      default:
        startDate = isNext
            ? startDate.add(const Duration(days: 7))
            : startDate.subtract(const Duration(days: 7));
        endDate = startDate.add(const Duration(days: 6));
        break;
    }
    filterDataByDateRange();
    scrollToToday();
    update(['specialTasksList', 'specialPeriodBar']);
  }

  void changeWeek(bool isNext) => changePeriod(isNext);

  DateTime getStartOfWeek(DateTime date) {
    int weekday = date.weekday; // 1 = Monday ... 7 = Sunday
    // لو السبت (6) هو بداية الأسبوع
    int daysToSubtract = (weekday >= 6) ? weekday - 6 : weekday + 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  final ScrollController scrollController = ScrollController();
  void scrollToToday() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
  }

  @override
  void onInit() {
    super.onInit();
    tasksViewMode.value = tasksViewWeekly;
    syncPeriodBounds();
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
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
