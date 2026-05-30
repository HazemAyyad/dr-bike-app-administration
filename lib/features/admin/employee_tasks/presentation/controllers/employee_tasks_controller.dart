import 'dart:collection';
import 'dart:io';

import 'package:doctorbike/core/helpers/media_permissions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/helpers/camera_capture_helper.dart';
import '../../../../../core/helpers/task_details_debug.dart';
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

  final args = Get.arguments as Map<String, dynamic>?;

  RxInt currentTab = 0.obs;

  final tabs = <String>[].obs;

  bool get _isAdminViewer => userType == 'admin';

  int get archiveTabIndex => _isAdminViewer ? 3 : 2;

  RxBool isLoading = false.obs;

  final RxList<File> selectedFile = <File>[].obs;
  final RxList<File> selectedSubFile = <File>[].obs;
  final Map<int, List<File>> subTaskPendingImages = {};

  void changeTab(int index) {
    currentTab.value = index;
    rebuildFlatList();
    scrollToToday();
    update(['tasksList', 'periodBar']);
  }

  void setTasksViewMode(String mode) {
    tasksViewMode.value = mode;
    syncPeriodBounds(anchor: DateTime.now());
    applyAllFilters();
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

  static String dateKeyFrom(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

    final lists = await Future.wait([
      employeeTasksUsecase.call(page: 0),
      employeeTasksUsecase.call(page: 1),
      employeeTasksUsecase.call(page: 2),
    ]);

    _mergeTaskList(employeeTaskService.ongoingEmployeeTasks, lists[0]);
    _mergeTaskList(employeeTaskService.completedEmployeeTasks, lists[1]);
    _mergeTaskList(employeeTaskService.canceledEmployeeTasks, lists[2]);

    applyAllFilters();

    isLoading(false);
    if (scrollToTodayb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToToday());
    }
    update(['tasksList', 'periodBar']);
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
    if (fromDateController.text.isEmpty &&
        toDateController.text.isEmpty &&
        employeeNameController.text.isEmpty) {
      applyAllFilters();
      return;
    }
    ongoingTasksFilter =
        filterByRange(filterTasks(employeeTaskService.ongoingEmployeeTasks));
    completedTasksFilter =
        filterByRange(filterTasks(employeeTaskService.completedEmployeeTasks));
    canceledTasksFilter =
        filterByRange(filterTasks(employeeTaskService.canceledEmployeeTasks));
    rebuildFlatList();
    update(['tasksList', 'periodBar']);
  }

  Map<String, List<EmployeeTaskModel>> _applyNameAndRange(
    Map<String, List<EmployeeTaskModel>> source,
  ) {
    final sorted = sortByDate(source);
    final withName = employeeNameController.text.trim().isEmpty
        ? sorted
        : filterTasks(sorted);
    return filterByRange(withName);
  }

  void applyAllFilters() {
    final ongoingSorted = sortByDate(employeeTaskService.ongoingEmployeeTasks);
    if (_isAdminViewer) {
      ongoingTasksFilter = _applyNameAndRange(
        _filterMapByStatus(ongoingSorted, exclude: ['waiting_review']),
      );
      awaitingReviewTasksFilter = _applyNameAndRange(
        _filterMapByStatus(ongoingSorted, only: ['waiting_review']),
      );
    } else {
      ongoingTasksFilter = _applyNameAndRange(ongoingSorted);
      awaitingReviewTasksFilter = {};
    }
    completedTasksFilter = _applyNameAndRange(
      employeeTaskService.completedEmployeeTasks,
    );
    canceledTasksFilter = _applyNameAndRange(
      employeeTaskService.canceledEmployeeTasks,
    );
    rebuildFlatList();
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

    final file = await CameraCaptureHelper.captureProof(context);
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

  // task details
  Future<void> getTaskDetails({
    required String taskId,
    String? occurrenceId,
    bool showFullScreenLoader = true,
  }) async {
    if (showFullScreenLoader) {
      employeeTaskService.taskDetails.value = null;
    }
    lastLoadedOccurrenceId =
        occurrenceId != null && occurrenceId.isNotEmpty ? occurrenceId : null;
    isTaskDetailsLoading.value = true;
    TaskDetailsDebug.request(taskId: taskId, occurrenceId: occurrenceId);
    try {
      final result = await getTaskDetailsUsecase.call(
        taskId: taskId,
        occurrenceId: occurrenceId,
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
      employeeTaskService.taskDetails.value =
          TaskDetailsModel.fromJson(Map<String, dynamic>.from(raw));
    } catch (e, st) {
      TaskDetailsDebug.parseError(e, st);
      employeeTaskService.taskDetails.value = null;
      rethrow;
    } finally {
      isTaskDetailsLoading.value = false;
    }
  }

  /// Load details then open screen — avoids showing the previous task.
  Future<void> openTaskDetails(EmployeeTaskModel task) async {
    final taskId = task.taskId.toString();
    final occurrenceId = task.occurrenceId?.toString();
    TaskDetailsDebug.tap(
      source: 'EmployeeTasksController.openTaskDetails',
      taskId: taskId,
      occurrenceId: occurrenceId,
      taskName: task.taskName,
      status: task.status,
    );
    try {
      await getTaskDetails(taskId: taskId, occurrenceId: occurrenceId);
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
    applyAllFilters();
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
    applyAllFilters();
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
