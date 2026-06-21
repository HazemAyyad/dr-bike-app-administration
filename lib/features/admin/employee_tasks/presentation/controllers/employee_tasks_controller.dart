import 'dart:collection';
import 'dart:io';

import 'package:doctorbike/core/helpers/media_permissions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/helpers/camera_capture_helper.dart';
import '../../../../../core/helpers/task_details_debug.dart';
import '../../../../../core/helpers/task_recurrence_rules.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../employee/employee_dashbord/data/repositories/employee_dashbord_implement.dart';
import '../../../../employee/employee_dashbord/domain/usecases/change_task_completed_uasecase.dart';
import '../../../../employee/employee_dashbord/presentation/controllers/employee_dashbord_controller.dart';
import '../../data/datasources/employee_tasks_datasource.dart';
import '../../data/models/employee_task_model.dart';
import '../../data/models/task_details_model.dart';
import '../../domain/entities/task_details_entiny.dart';
import '../../domain/usecases/cancel_employee_task_usecase.dart';
import '../../domain/usecases/employee_tasks_usecase.dart';
import '../../domain/usecases/get_task_details_usecase.dart';
import '../../domain/usecases/upload_task_image_usecase.dart';
import '../models/employee_task_list_row.dart';
import '../helpers/recurring_task_expander.dart';
import 'employee_task_service.dart';

class EmployeeTasksController extends GetxController {
  static const String tasksViewDaily = 'daily';
  static const String tasksViewWeekly = 'weekly';
  static const String tasksViewMonthly = 'monthly';
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
  final RxnInt filterEmployeeId = RxnInt();
  String? _arcFilterDisplayName;

  final args = Get.arguments as Map<String, dynamic>?;

  RxInt currentTab = 0.obs;

  final tabs = <String>[].obs;

  bool get _isAdminViewer => userType == 'admin';

  int get archiveTabIndex => _isAdminViewer ? 3 : 2;

  int get completedTabIndex => _isAdminViewer ? 2 : 1;

  bool get isCompletedTab => currentTab.value == completedTabIndex;

  RxBool isLoading = false.obs;

  bool _ongoingLoaded = false;
  bool _completedTabLoaded = false;
  bool _canceledTabLoaded = false;

  final RxList<File> selectedFile = <File>[].obs;
  final RxList<File> selectedSubFile = <File>[].obs;
  final Map<int, List<File>> subTaskPendingImages = {};

  Future<void> changeTab(int index) async {
    if (currentTab.value == index && _isTabDataReady(index)) {
      rebuildFlatList();
      scrollToToday();
      update(['tasksList', 'periodBar']);
      return;
    }

    currentTab.value = index;
    isLoading(true);
    update(['tasksList']);

    try {
      await _ensureTabDataLoaded(index);
      applyFiltersForTab(index);
    } finally {
      isLoading(false);
      rebuildFlatList();
      scrollToToday();
      update(['tasksList', 'periodBar']);
    }
  }

  bool _isTabDataReady(int index) {
    if (_isAdminViewer && (index == 0 || index == 1)) {
      return _ongoingLoaded;
    }
    if (!_isAdminViewer && index == 0) {
      return _ongoingLoaded;
    }
    if (index == completedTabIndex) {
      return _completedTabLoaded;
    }
    if (index == archiveTabIndex) {
      return _canceledTabLoaded;
    }
    return false;
  }

  Future<void> _ensureTabDataLoaded(int index) async {
    if (_isAdminViewer && (index == 0 || index == 1)) {
      await _loadOngoingTab();
      return;
    }
    if (!_isAdminViewer && index == 0) {
      await _loadOngoingTab();
      return;
    }
    if (index == completedTabIndex) {
      await _loadCompletedTab();
      return;
    }
    if (index == archiveTabIndex) {
      await _loadCanceledTab();
    }
  }

  void setTasksViewMode(String mode) {
    tasksViewMode.value = mode;
    syncPeriodBounds(anchor: DateTime.now());
    applyFiltersForTab(currentTab.value);
    scrollToToday();
    update(['tasksList', 'periodBar', 'viewMode']);
  }

  Map<String, List<EmployeeTaskModel>> awaitingReviewTasksFilter = {};

  Map<String, List<EmployeeTaskModel>> get _currentTabMap {
    if (_isAdminViewer) {
      switch (currentTab.value) {
        case 1:
          return awaitingReviewTasksFilter;
        case 2:
          return completedTasksFilter;
        case 3:
          return canceledTasksFilter;
        default:
          return ongoingTasksFilter;
      }
    }
    switch (currentTab.value) {
      case 1:
        return completedTasksFilter;
      case 2:
        return canceledTasksFilter;
      default:
        return ongoingTasksFilter;
    }
  }

  Map<String, List<EmployeeTaskModel>> _filterMapByStatus(
    Map<String, List<EmployeeTaskModel>> source, {
    List<String>? only,
    List<String>? exclude,
  }) {
    final out = <String, List<EmployeeTaskModel>>{};
    source.forEach((key, list) {
      var filtered = list;
      if (only != null) {
        filtered = filtered.where((t) => only.contains(t.status)).toList();
      }
      if (exclude != null) {
        filtered = filtered.where((t) => !exclude.contains(t.status)).toList();
      }
      if (filtered.isNotEmpty) {
        out[key] = filtered;
      }
    });
    return out;
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

  final RxBool deleteTask = false.obs;

  final RxBool deleteTasDuplicate = false.obs;

  /// Default: current week. User can switch to daily / monthly.
  final RxString tasksViewMode = tasksViewWeekly.obs;

  /// Flat rows for lazy list (headers + tasks).
  List<EmployeeTaskListRow> flatTaskRows = [];

  /// Bumped whenever [flatTaskRows] is rebuilt — drives [Obx] list refresh.
  final RxInt listEpoch = 0.obs;

  String get listUiKey =>
      '${tasksViewMode.value}_${currentTab.value}_${listEpoch.value}_${startDate.millisecondsSinceEpoch}';

  static String dateKeyFrom(DateTime d) => TaskRecurrenceRules.dateKeyFrom(d);

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
  Future<void> pullToRefresh() => getEmployeeTasks(scrollToTodayb: true);

  void _mergeTaskInto(
    Map<String, List<EmployeeTaskModel>> target,
    EmployeeTaskModel task,
  ) {
    final key = dateKeyFrom(task.startTime);
    final list = target.putIfAbsent(key, () => []);
    if (list.every((t) => t.taskId != task.taskId)) {
      list.add(task);
    }
  }

  void _mergeTaskList(
    Map<String, List<EmployeeTaskModel>> target,
    List<EmployeeTaskModel> tasks,
  ) {
    for (final task in tasks) {
      _mergeTaskInto(target, task);
    }
  }

  Future<void> getEmployeeTasks({bool scrollToTodayb = true}) async {
    isLoading(true);
    update(['tasksList']);
    employeeTaskService.ongoingEmployeeTasks.clear();
    employeeTaskService.completedEmployeeTasks.clear();
    employeeTaskService.canceledEmployeeTasks.clear();
    ongoingTasksFilter = {};
    awaitingReviewTasksFilter = {};
    completedTasksFilter = {};
    canceledTasksFilter = {};
    _ongoingLoaded = false;
    _completedTabLoaded = false;
    _canceledTabLoaded = false;

    try {
      await _ensureTabDataLoaded(currentTab.value);
      applyFiltersForTab(currentTab.value);
    } finally {
      isLoading(false);
      if (scrollToTodayb) {
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToToday());
      }
      update(['tasksList', 'periodBar']);
    }
  }

  Future<void> _loadOngoingTab() async {
    if (_ongoingLoaded) return;
    final list = await employeeTasksUsecase.call(page: 0);
    employeeTaskService.ongoingEmployeeTasks.clear();
    _mergeTaskList(employeeTaskService.ongoingEmployeeTasks, list);
    _ongoingLoaded = true;
  }

  Future<void> _loadCompletedTab() async {
    if (_completedTabLoaded) return;
    final list = await employeeTasksUsecase.call(page: 1);
    employeeTaskService.completedEmployeeTasks.clear();
    _mergeTaskList(employeeTaskService.completedEmployeeTasks, list);
    _completedTabLoaded = true;
  }

  Future<void> _loadCanceledTab() async {
    if (_canceledTabLoaded) return;
    final list = await employeeTasksUsecase.call(page: 2);
    employeeTaskService.canceledEmployeeTasks.clear();
    _mergeTaskList(employeeTaskService.canceledEmployeeTasks, list);
    _canceledTabLoaded = true;
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

      // فلترة بالموظف / البحث
      if (filterEmployeeId.value != null) {
        matchesName = task.matchesAssigneeFilter(filterEmployeeId.value!);
      } else if (name.isNotEmpty) {
        matchesName = task.matchesSearchQuery(name);
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

  void applyEmployeeArcFilter({int? employeeId, String? displayName}) {
    if (employeeId == null || employeeId <= 0) {
      filterEmployeeId.value = null;
      _arcFilterDisplayName = null;
      employeeNameController.clear();
    } else {
      filterEmployeeId.value = employeeId;
      final label = displayName?.trim() ?? '';
      _arcFilterDisplayName = label.isEmpty ? null : label;
      if (label.isNotEmpty) {
        employeeNameController.text = label;
      }
    }
    applyAllFilters();
    update(['tasksList', 'periodBar']);
  }

  void clearEmployeeTaskFilters() {
    filterEmployeeId.value = null;
    _arcFilterDisplayName = null;
    employeeNameController.clear();
    applyAllFilters();
    update(['tasksList', 'periodBar']);
  }

  // filter employee tasks
  void filterEmployeeTasks() {
    final text = employeeNameController.text.trim();
    if (text.isEmpty) {
      filterEmployeeId.value = null;
      _arcFilterDisplayName = null;
    } else if (filterEmployeeId.value != null &&
        _arcFilterDisplayName != null &&
        text != _arcFilterDisplayName) {
      filterEmployeeId.value = null;
      _arcFilterDisplayName = null;
    }
    if (fromDateController.text.isEmpty &&
        toDateController.text.isEmpty &&
        employeeNameController.text.isEmpty &&
        filterEmployeeId.value == null) {
      applyFiltersForTab(currentTab.value);
      return;
    }
    applyFiltersForTab(currentTab.value);
    update(['tasksList', 'periodBar']);
  }

  Map<String, List<EmployeeTaskModel>> _expandForCurrentView(
    Map<String, List<EmployeeTaskModel>> source,
  ) {
    return RecurringTaskExpander.expand(
      source: source,
      rangeStart: startDate,
      rangeEnd: endDate,
    );
  }

  Map<String, List<EmployeeTaskModel>> _applyNameAndRange(
    Map<String, List<EmployeeTaskModel>> source,
  ) {
    final sorted = sortByDate(source);
    final hasEmployeeFilter = filterEmployeeId.value != null;
    final hasTextFilter = employeeNameController.text.trim().isNotEmpty;
    final withName = !hasEmployeeFilter && !hasTextFilter
        ? sorted
        : filterTasks(sorted);
    return filterByRange(_expandForCurrentView(withName));
  }

  void applyFiltersForTab(int tabIndex) {
    if (_isAdminViewer) {
      switch (tabIndex) {
        case 0:
          if (_ongoingLoaded) {
            final ongoingSorted =
                sortByDate(employeeTaskService.ongoingEmployeeTasks);
            ongoingTasksFilter = _applyNameAndRange(
              _filterMapByStatus(ongoingSorted, exclude: ['waiting_review']),
            );
          }
          break;
        case 1:
          if (_ongoingLoaded) {
            final ongoingSorted =
                sortByDate(employeeTaskService.ongoingEmployeeTasks);
            awaitingReviewTasksFilter = _applyNameAndRange(
              _filterMapByStatus(ongoingSorted, only: ['waiting_review']),
            );
          }
          break;
        case 2:
          if (_completedTabLoaded) {
            completedTasksFilter = _applyNameAndRange(
              employeeTaskService.completedEmployeeTasks,
            );
          }
          break;
        case 3:
          if (_canceledTabLoaded) {
            canceledTasksFilter = _applyNameAndRange(
              employeeTaskService.canceledEmployeeTasks,
            );
          }
          break;
      }
    } else {
      switch (tabIndex) {
        case 0:
          if (_ongoingLoaded) {
            ongoingTasksFilter = _applyNameAndRange(
              sortByDate(employeeTaskService.ongoingEmployeeTasks),
            );
          }
          break;
        case 1:
          if (_completedTabLoaded) {
            completedTasksFilter = _applyNameAndRange(
              employeeTaskService.completedEmployeeTasks,
            );
          }
          break;
        case 2:
          if (_canceledTabLoaded) {
            canceledTasksFilter = _applyNameAndRange(
              employeeTaskService.canceledEmployeeTasks,
            );
          }
          break;
      }
    }

    if (tabIndex == currentTab.value) {
      rebuildFlatList();
    }
  }

  void applyAllFilters() {
    applyFiltersForTab(currentTab.value);
  }

  // cancel employee task
  void cancelEmployeeTask({
    required String taskId,
    int? occurrenceId,
    required bool cancelWithRepetition,
    bool isCompleted = false,
  }) async {
    isLoading(true);
    isCompleted ? uploadTaskImage(taskId: taskId) : null;
    final result = await cancelEmployeeTaskUsecase.call(
      employeeTaskId: taskId,
      occurrenceId: occurrenceId,
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
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) {
        Get.closeAllSnackbars();
        Get.back();
        getEmployeeTasks(scrollToTodayb: false);
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
    );
    deleteTasDuplicate.value = false;
    deleteTask.value = false;
    isLoading(false);
    update();
  }

  bool taskHasEmployeeImage(TaskDetailsModel data) {
    return (data.employeeImg?.isNotEmpty ?? false) ||
        (data.employeeVideos?.isNotEmpty ?? false);
  }

  bool canCompleteTask(TaskDetailsModel data) {
    if (!data.isForcedToUploadImg) return true;
    return taskHasEmployeeImage(data) || selectedFile.isNotEmpty;
  }

  SubTaskEntity? subTaskById(int id) {
    final subs = employeeTaskService.taskDetails.value?.subTasks;
    if (subs == null) return null;
    for (final s in subs) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool subTaskHasEmployeeImage(SubTaskEntity subTask) {
    return (subTask.employeeImg?.isNotEmpty ?? false) ||
        (subTask.employeeVideos?.isNotEmpty ?? false);
  }

  bool canCompleteSubTask(SubTaskEntity subTask, List<File> pendingFiles) {
    if (!subTask.isForcedToUploadImg) return true;
    return subTaskHasEmployeeImage(subTask) || pendingFiles.isNotEmpty;
  }

  /// Parsed from last successful proof upload (subtask auto-complete flags).
  Map<String, dynamic>? lastProofUploadMeta;

  static bool metaTruthy(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  // upload task image
  Future<bool> uploadTaskImage({
    required String taskId,
    bool isSubTask = false,
    bool isOccurrenceSubtask = false,
    bool isOccurrenceMain = false,
    List<File>? files,
    String? reloadOccurrenceId,
    bool silentRefresh = true,
  }) async {
    final images = List<File>.from(
      files ?? (isSubTask ? selectedSubFile : selectedFile),
    );
    if (images.isEmpty) return false;

    isLoading(true);
    try {
      final result = await uploadTaskImageUsecase.call(
        isSubTask: isSubTask,
        taskId: taskId,
        image: images,
        isOccurrenceSubtask: isOccurrenceSubtask,
        isOccurrenceMain: isOccurrenceMain,
      );
      final status = result is Map ? result['status'] : null;
      if (status != 'success') {
        lastProofUploadMeta = null;
        final msg = result is Map
            ? (result['message']?.toString() ?? 'uploadFailed'.tr)
            : 'uploadFailed'.tr;
        Get.snackbar('error'.tr, msg);
        return false;
      }

      lastProofUploadMeta =
          result is Map ? Map<String, dynamic>.from(result) : null;

      final mainTaskId = isSubTask
          ? employeeTaskService.taskDetails.value?.taskId.toString()
          : taskId;
      if (mainTaskId != null && mainTaskId.isNotEmpty) {
        await getTaskDetails(
          taskId: mainTaskId,
          occurrenceId: reloadOccurrenceId,
          showFullScreenLoader: !silentRefresh,
        );
      }
      if (isSubTask) {
        selectedSubFile.clear();
      } else {
        final refreshed = employeeTaskService.taskDetails.value;
        if (refreshed != null && taskHasEmployeeImage(refreshed)) {
          selectedFile.clear();
        }
      }
      return true;
    } on Failure catch (f) {
      lastProofUploadMeta = null;
      Get.snackbar('error'.tr, f.errMessage);
      return false;
    } catch (e) {
      lastProofUploadMeta = null;
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  /// Camera proof for a subtask: upload then complete (server may auto-complete on upload).
  Future<bool> completeSubtaskWithCameraProof({
    required BuildContext context,
    required SubTaskEntity sub,
    required String mainTaskId,
    String? occurrenceId,
  }) async {
    final isOccurrenceSubtask = occurrenceId != null && occurrenceId.isNotEmpty;

    if (!sub.isForcedToUploadImg || subTaskHasEmployeeImage(sub)) {
      return completeSubtaskAtEmployee(
        subTaskId: sub.id,
        mainTaskId: mainTaskId,
        occurrenceId: occurrenceId,
      );
    }

    final file = await CameraCaptureHelper.captureProof(
      context,
      proofMediaType: sub.proofMediaType,
    );
    if (file == null) return false;

    final uploaded = await uploadTaskImage(
      taskId: sub.id.toString(),
      isSubTask: true,
      isOccurrenceSubtask: isOccurrenceSubtask,
      files: [file],
      reloadOccurrenceId: occurrenceId,
      silentRefresh: true,
    );
    if (!uploaded) return false;

    final meta = lastProofUploadMeta;
    if (meta != null && metaTruthy(meta['subtask_completed'])) {
      _refreshEmployeeHomeAfterTaskChange();
      Get.snackbar(
        'success'.tr,
        'subtaskCompletedSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      update(['taskDetails', 'subtasks']);
      return true;
    }

    return completeSubtaskAtEmployee(
      subTaskId: sub.id,
      mainTaskId: mainTaskId,
      occurrenceId: occurrenceId,
    );
  }

  Future<bool> tryAutoSubmitTaskAfterSubtasks({
    required String mainTaskId,
    String? occurrenceId,
  }) async {
    final data = employeeTaskService.taskDetails.value;
    if (data == null) return false;
    if (data.subTasks.any((s) => s.status != 'completed')) return false;
    if (data.status == 'waiting_review' ||
        data.status == 'completed' ||
        data.status == 'canceled') {
      return true;
    }

    if (data.isForcedToUploadImg && !taskHasEmployeeImage(data)) {
      return false;
    }

    return submitTaskForReview(mainTaskId, occurrenceId: occurrenceId);
  }

  void _refreshEmployeeHomeAfterTaskChange() {
    if (Get.isRegistered<EmployeeDashbordController>()) {
      Get.find<EmployeeDashbordController>()
          .getEmployeeData(scrollToTodayb: false);
    }
  }

  /// Complete a subtask from task details (does not depend on dashboard controller).
  Future<bool> completeSubtaskAtEmployee({
    required int subTaskId,
    required String mainTaskId,
    String? occurrenceId,
  }) async {
    final occ = occurrenceId ?? lastLoadedOccurrenceId;
    final isOccurrence = occ != null && occ.isNotEmpty;

    AppDependencyRegistry.ensureEmployeeDashbord();
    final usecase = ChangeTaskCompletedUasecase(
      employeeDashbordRepository: Get.find<EmployeeDashbordImplement>(),
    );

    isLoading(true);
    try {
      final result = await usecase.call(
        isSubTask: true,
        taskId: subTaskId,
        isOccurrence: isOccurrence,
        occurrenceId: null,
      );
      return await result.fold(
        (failure) async {
          final msg = failure.data is Map
              ? (failure.data['message']?.toString() ?? failure.errMessage)
              : failure.errMessage;
          Get.snackbar('error'.tr, msg);
          return false;
        },
        (success) async {
          await getTaskDetails(
            taskId: mainTaskId,
            occurrenceId: occ,
            showFullScreenLoader: false,
          );
          _refreshEmployeeHomeAfterTaskChange();
          final msg = success.toString();
          final needsMainProof = msg.contains('upload_proof') ||
              msg.contains('إثبات المهمة الرئيسية') ||
              msg.contains('main task proof');
          if (needsMainProof) {
            Get.snackbar(
              'note'.tr,
              'allSubtasksDoneUploadMainProof'.tr,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'success'.tr,
              'subtaskCompletedSuccess'.tr,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
          update(['taskDetails', 'subtasks']);
          return true;
        },
      );
    } on Failure catch (f) {
      Get.snackbar('error'.tr, f.errMessage);
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  final ImagePicker picker = ImagePicker();

  Future<bool> uploadSubTaskImage({
    required String taskId,
    required BuildContext context,
  }) async {
    // دالة محلية لبناء نافذة الاختيار
    Widget buildSourceOptionsBoth(BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text("takeImage".tr),
              onTap: () => Navigator.pop(context, 'camera_image'),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text("selectImage".tr),
              onTap: () => Navigator.pop(context, 'gallery_image'),
            ),
            // ListTile(
            //   leading: const Icon(Icons.videocam),
            //   title: Text("takeVideo".tr),
            //   onTap: () => Navigator.pop(context, 'camera_video'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.video_library),
            //   title: Text("selectVideo".tr),
            //   onTap: () => Navigator.pop(context, 'gallery_video'),
            // ),
          ],
        ),
      );
    }

    // افتح الخيارات
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => buildSourceOptionsBoth(context),
    );

    if (choice == null) return false;

    XFile? pickedFile;
    List<XFile>? pickedFiles;

    switch (choice) {
      case 'camera_image':
        if (!await ensureCameraPermission()) {
          showMediaPermissionDeniedSnackbar();
          return false;
        }
        pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) selectedSubFile.add(File(pickedFile.path));
        update(['proof', 'subtasks']);
        break;

      case 'gallery_image':
        if (!await ensurePhotosPermission()) {
          showMediaPermissionDeniedSnackbar();
          return false;
        }
        pickedFiles = await picker.pickMultiImage();
        selectedSubFile.addAll(pickedFiles.map((e) => File(e.path)));
        update(['proof', 'subtasks']);
        break;

      // case 'camera_video':
      //   pickedFile = await picker.pickVideo(source: ImageSource.camera);
      //   if (pickedFile != null) selectedSubFile.add(File(pickedFile.path));
      //   break;

      // case 'gallery_video':
      //   pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      //   if (pickedFile != null) selectedSubFile.add(File(pickedFile.path));
      //   break;
    }

    if (selectedSubFile.isEmpty) return false;
    return uploadTaskImage(
      taskId: taskId,
      isSubTask: true,
      files: selectedSubFile.toList(),
    );
  }

  final RxBool isTaskDetailsLoading = false.obs;

  /// Set when details are loaded with [occurrenceId] (v2 occurrence tasks).
  String? lastLoadedOccurrenceId;

  /// Calendar day for legacy recurring task details (yyyy-MM-dd).
  String? lastLoadedTaskDate;

  // task details
  Future<void> getTaskDetails({
    required String taskId,
    String? occurrenceId,
    String? taskDate,
    bool showFullScreenLoader = true,
  }) async {
    if (showFullScreenLoader) {
      employeeTaskService.taskDetails.value = null;
    }
    if (occurrenceId != null && occurrenceId.isNotEmpty) {
      lastLoadedOccurrenceId = occurrenceId;
      lastLoadedTaskDate = null;
    } else {
      lastLoadedOccurrenceId = null;
      if (taskDate != null && taskDate.isNotEmpty) {
        lastLoadedTaskDate = taskDate;
      }
    }
    final effectiveTaskDate =
        (occurrenceId == null || occurrenceId.isEmpty)
            ? (taskDate ?? lastLoadedTaskDate)
            : null;
    isTaskDetailsLoading.value = true;
    TaskDetailsDebug.request(taskId: taskId, occurrenceId: occurrenceId);
    try {
      final result = await getTaskDetailsUsecase.call(
        taskId: taskId,
        occurrenceId: occurrenceId,
        taskDate: effectiveTaskDate,
      );
      TaskDetailsDebug.apiResult(
        result: result,
        taskId: taskId,
        occurrenceId: occurrenceId,
      );
      if (result is Map && result['status'] == 'error') {
        employeeTaskService.taskDetails.value = null;
        return;
      }
      final raw = result['employee_task'];
      if (raw is! Map) {
        employeeTaskService.taskDetails.value = null;
        return;
      }
      final model = TaskDetailsModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
      employeeTaskService.taskDetails.value = model;
      TaskDetailsDebug.modelLoaded(
        source: 'getTaskDetails',
        taskId: model.taskId,
        occurrenceId: model.occurrenceId,
        name: model.taskName,
        subTasks: model.subTasks
            .map(
              (s) => {
                'id': s.id.toString(),
                'name': s.name,
                'status': s.status,
              },
            )
            .toList(),
        cachedNote:
            'req taskId=$taskId occ=${occurrenceId ?? "-"} | rx cleared before load=${showFullScreenLoader}',
      );
    } catch (e, st) {
      TaskDetailsDebug.parseError(e, st);
      employeeTaskService.taskDetails.value = null;
      rethrow;
    } finally {
      isTaskDetailsLoading.value = false;
    }
  }

  /// Prefer the DB child row when opening a recurring legacy instance for a given day.
  EmployeeTaskModel resolveTaskForInteraction(EmployeeTaskModel task) {
    if (task.isOccurrence || task.isRepeatedCopy) return task;
    if (!RecurringTaskExpander.shouldExpand(task)) return task;

    final flat = <EmployeeTaskModel>[
      ...employeeTaskService.ongoingEmployeeTasks.values.expand((e) => e),
      ...employeeTaskService.completedEmployeeTasks.values.expand((e) => e),
      ...employeeTaskService.canceledEmployeeTasks.values.expand((e) => e),
    ];
    final parentKey = '${task.taskId}';
    for (final row in flat) {
      if (row.parentId == parentKey &&
          row.startTime.year == task.startTime.year &&
          row.startTime.month == task.startTime.month &&
          row.startTime.day == task.startTime.day) {
        return row;
      }
    }
    return task;
  }

  /// Load details then open screen — avoids showing the previous task.
  Future<void> openTaskDetails(EmployeeTaskModel task) async {
    final actionTask = resolveTaskForInteraction(task);
    final taskId = actionTask.taskId.toString();
    final occurrenceId = actionTask.isOccurrence
        ? actionTask.occurrenceId?.toString()
        : null;
    final taskDate = occurrenceId == null
        ? dateKeyFrom(actionTask.startTime)
        : null;
    TaskDetailsDebug.tap(
      source: 'EmployeeTasksController.openTaskDetails',
      taskId: task.taskId.toString(),
      occurrenceId: task.occurrenceId?.toString(),
      listSource: task.source,
      taskName: task.taskName,
      status: actionTask.status,
      resolvedTaskId: taskId,
      resolvedOccurrenceId: occurrenceId,
    );
    try {
      await getTaskDetails(
        taskId: taskId,
        occurrenceId: occurrenceId,
        taskDate: taskDate,
      );
    } catch (e) {
      TaskDetailsDebug.fail('openTaskDetails_exception', detail: e.toString());
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final loaded = employeeTaskService.taskDetails.value;
    if (loaded == null) {
      TaskDetailsDebug.fail(
        'openTaskDetails_null_after_load',
        detail: {'taskId': taskId, 'occurrenceId': occurrenceId},
      );
      Get.snackbar(
        'error'.tr,
        'errorLoadingTaskDetails'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    TaskDetailsDebug.screen(
      phase: 'navigate',
      taskId: taskId,
      occurrenceId: occurrenceId,
      note: 'route=${AppRoutes.TASKDETAILS}',
    );
    await Get.toNamed(
      AppRoutes.TASKDETAILS,
      arguments: {
        'taskId': taskId,
        if (occurrenceId != null && occurrenceId.isNotEmpty)
          'occurrence_id': occurrenceId,
        if (taskDate != null && taskDate.isNotEmpty) 'task_date': taskDate,
        if (Get.isRegistered<EmployeeDashbordController>())
          'EmployeeDashbordController': Get.find<EmployeeDashbordController>(),
      },
    );
  }

  DateTime getStartOfWeek(DateTime date) {
    int weekday = date.weekday; // 1 = Monday ... 7 = Sunday
    // لو السبت (6) هو بداية الأسبوع
    int daysToSubtract = (weekday >= 6) ? weekday - 6 : weekday + 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

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

  Map<String, List<EmployeeTaskModel>> filterByRange(
      Map<String, List<EmployeeTaskModel>> source) {
    final filtered = <String, List<EmployeeTaskModel>>{};
    for (int i = 0; i < _periodDayCount; i++) {
      final currentDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));
      final key = dateKeyFrom(currentDay);
      filtered[key] = List<EmployeeTaskModel>.from(source[key] ?? []);
    }
    return LinkedHashMap.fromIterable(
      orderedDisplayKeys(filtered.keys.toList()),
      key: (k) => k as String,
      value: (k) => filtered[k]!,
    );
  }

  /// Today first, then future days, then earlier days in range.
  List<String> orderedDisplayKeys(List<String> keys) {
    if (keys.isEmpty) return [];
    if (tasksViewMode.value == tasksViewWeekly) {
      return keys
        ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    }

    final today = dateKeyFrom(DateTime.now());
    final entries = keys.map((k) => MapEntry(k, DateTime.parse(k))).toList();

    final todayEntry = entries.where((e) => e.key == today).toList();
    final future = entries
        .where(
            (e) => e.key != today && !e.value.isBefore(DateTime.parse(today)))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final past = entries
        .where((e) => e.value.isBefore(DateTime.parse(today)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      ...todayEntry.map((e) => e.key),
      ...future.map((e) => e.key),
      ...past.map((e) => e.key),
    ];
  }

  void rebuildFlatList() {
    final rows = <EmployeeTaskListRow>[];
    final map = _currentTabMap;
    final keys = orderedDisplayKeys(map.keys.toList());
    final todayKey = dateKeyFrom(DateTime.now());
    var headerIndex = 0;
    for (final day in keys) {
      final tasks = map[day] ?? [];
      final showSection = tasks.isNotEmpty ||
          day == todayKey ||
          tasksViewMode.value == tasksViewDaily ||
          tasksViewMode.value == tasksViewWeekly;
      if (!showSection) continue;
      rows.add(
          EmployeeTaskListRow.header(day, isFirstHeader: headerIndex == 0));
      headerIndex++;
      final sorted = List<EmployeeTaskModel>.from(tasks)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      for (final t in sorted) {
        rows.add(EmployeeTaskListRow.task(t));
      }
    }
    flatTaskRows = rows;
    listEpoch.value++;
  }

  void filterDataByDateRange() {
    applyFiltersForTab(currentTab.value);
    update(['tasksList', 'periodBar']);
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
        final m =
            DateTime(startDate.year, startDate.month + (isNext ? 1 : -1), 1);
        startDate = m;
        endDate = DateTime(m.year, m.month + 1, 0);
        break;
      case tasksViewWeekly:
      default:
        startDate = isNext
            ? startDate.add(const Duration(days: 7))
            : startDate.subtract(const Duration(days: 7));
        endDate = startDate.add(const Duration(days: 6));
        break;
    }
    applyFiltersForTab(currentTab.value);
    scrollToToday();
    update(['tasksList', 'periodBar']);
  }

  /// Kept for callers that still use [changeWeek].
  void changeWeek(bool isNext) => changePeriod(isNext);

  final ScrollController scrollController = ScrollController();

  void scrollToToday() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(0);
  }

  EmployeeTasksDatasource get _taskDs {
    AppDependencyRegistry.ensureEmployeeTasks();
    return Get.find<EmployeeTasksDatasource>();
  }

  Future<bool> startTaskWorkflow(String taskId) async {
    isLoading(true);
    try {
      final res = await _taskDs.taskWorkflowPost(
        EndPoints.employeeTaskStart,
        taskId: taskId,
      );
      if (res['status'] == 'success') {
        await getTaskDetails(taskId: taskId);
        return true;
      }
      Get.snackbar('error'.tr, '${res['message'] ?? ''}');
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> submitTaskForReview(
    String taskId, {
    String? notes,
    String? occurrenceId,
  }) async {
    final occ = occurrenceId ?? lastLoadedOccurrenceId;
    final isOccurrence = occ != null && occ.isNotEmpty;

    isLoading(true);
    try {
      final res = await _taskDs.taskWorkflowPost(
        EndPoints.employeeTaskSubmit,
        taskId: isOccurrence ? null : taskId,
        occurrenceId: isOccurrence ? occ : null,
        employeeNotes: notes,
      );
      if (res['status'] == 'success') {
        await getTaskDetails(taskId: taskId, occurrenceId: occ);
        Get.snackbar(
            'success'.tr, '${res['message'] ?? 'taskSubmittedForReview'.tr}');
        if (Get.isRegistered<EmployeeDashbordController>()) {
          Get.find<EmployeeDashbordController>()
              .getEmployeeData(scrollToTodayb: false);
        }
        return true;
      }
      Get.snackbar('error'.tr, '${res['message'] ?? ''}');
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> approveTaskWorkflow(
    String taskId, {
    String? occurrenceId,
  }) async {
    final occ = occurrenceId ?? lastLoadedOccurrenceId;
    final isOccurrence = occ != null && occ.isNotEmpty;

    isLoading(true);
    try {
      final res = await _taskDs.taskWorkflowPost(
        EndPoints.employeeTaskApprove,
        taskId: isOccurrence ? null : taskId,
        occurrenceId: isOccurrence ? occ : null,
      );
      if (res['status'] == 'success') {
        await getTaskDetails(taskId: taskId, occurrenceId: occ);
        getEmployeeTasks();
        Get.snackbar('success'.tr, '${res['message'] ?? 'taskCompleted'.tr}');
        return true;
      }
      Get.snackbar('error'.tr, '${res['message'] ?? ''}');
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> rejectTaskWorkflow(
    String taskId,
    String notes, {
    String? occurrenceId,
  }) async {
    final occ = occurrenceId ?? lastLoadedOccurrenceId;
    final isOccurrence = occ != null && occ.isNotEmpty;

    isLoading(true);
    try {
      final res = await _taskDs.taskWorkflowPost(
        EndPoints.employeeTaskReject,
        taskId: isOccurrence ? null : taskId,
        occurrenceId: isOccurrence ? occ : null,
        rejectionNotes: notes,
      );
      if (res['status'] == 'success') {
        await getTaskDetails(taskId: taskId, occurrenceId: occ);
        getEmployeeTasks();
        Get.snackbar('success'.tr, '${res['message'] ?? 'taskRejected'.tr}');
        return true;
      }
      Get.snackbar('error'.tr, '${res['message'] ?? ''}');
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> reopenCompletedTask({
    required String taskId,
    int? occurrenceId,
    String? notes,
  }) async {
    final occ = occurrenceId?.toString();
    final isOccurrence = occ != null && occ.isNotEmpty;

    isLoading(true);
    try {
      final res = await _taskDs.taskWorkflowPost(
        EndPoints.employeeTaskReopen,
        taskId: isOccurrence ? null : taskId,
        occurrenceId: isOccurrence ? occ : null,
        adminNotes: () {
          final trimmed = notes?.trim();
          return trimmed == null || trimmed.isEmpty ? null : trimmed;
        }(),
      );
      if (res['status'] == 'success') {
        getEmployeeTasks();
        Get.back();
        Get.snackbar('success'.tr, '${res['message'] ?? 'reopenTaskSuccess'.tr}');
        return true;
      }
      Get.snackbar('error'.tr, '${res['message'] ?? ''}');
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return false;
    } finally {
      isLoading(false);
    }
  }

  int subtaskProgress(TaskDetailsModel data) {
    if (data.subTasks.isEmpty) return data.progress;
    final done = data.subTasks.where((s) => s.status == 'completed').length;
    return ((done / data.subTasks.length) * 100).round();
  }

  @override
  void onInit() {
    super.onInit();
    if (_isAdminViewer) {
      tabs.assignAll([
        'employeeActiveTasks',
        'tasksAwaitingReview',
        'employeeCompletedTasks',
        'archive',
      ]);
    } else {
      tabs.assignAll([
        'employeeActiveTasks',
        'employeeCompletedTasks',
        'archive',
      ]);
    }
    tasksViewMode.value = tasksViewWeekly;
    syncPeriodBounds();
    if (userType == 'admin') {
      getEmployeeTasks();
    } else {
      if (employeePermissions.contains(7)) {
        getEmployeeTasks();
      }
    }
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
    scrollController.dispose();
  }
}
