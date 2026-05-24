import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/task_details_debug.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../bottom_nav_bar/controllers/bottom_nav_bar_controller.dart';
import '../../../notifications/presentation/controllers/employee_notification_badge_controller.dart';
import '../../../../admin/debts/domain/usecases/get_debts_reports_usecase.dart';
import '../../../../admin/employee_section/data/models/employee_attendance_history_model.dart';
import '../../../../admin/employee_tasks/domain/usecases/upload_task_image_usecase.dart';
import '../../../../admin/employee_tasks/presentation/controllers/employee_tasks_controller.dart';
import '../../../../../core/helpers/camera_capture_helper.dart';
import '../../../../admin/employee_tasks/presentation/binding/employee_tasks_binding.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../../domain/usecases/change_task_completed_uasecase.dart';
import '../../domain/usecases/get_employee_data_usecase.dart';
import '../../domain/usecases/get_my_attendance_history_usecase.dart';
import '../../domain/usecases/request_over_time_loan_usecase.dart';

class EmployeeDashbordController extends GetxController
    with GetTickerProviderStateMixin {
  final RequestOverTimeLoanUsecase requestOverTimeLoanUsecase;
  final GetEmployeeDataUsecase getEmployeeDataUsecase;
  final ChangeTaskCompletedUasecase changeTaskCompletedUasecase;
  final UploadTaskImageUsecase uploadTaskImageUsecase;
  final GetDebtsReportsUsecase getDebtsReports;
  final GetMyAttendanceHistoryUsecase getMyAttendanceHistoryUsecase;

  EmployeeDashbordController({
    required this.requestOverTimeLoanUsecase,
    required this.getEmployeeDataUsecase,
    required this.changeTaskCompletedUasecase,
    required this.uploadTaskImageUsecase,
    required this.getDebtsReports,
    required this.getMyAttendanceHistoryUsecase,
  });

  final RxBool todayAttendanceLoading = false.obs;
  final Rxn<EmployeeAttendanceDay> todayAttendance = Rxn();

  Future<void> refreshTodayAttendance() async {
    try {
      todayAttendanceLoading.value = true;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final res = await getMyAttendanceHistoryUsecase.call(
        fromDate: start,
        toDate: start,
      );
      final key = DateFormat('yyyy-MM-dd').format(start);
      EmployeeAttendanceDay? match;
      for (final d in res.days) {
        if (d.date == key) {
          match = d;
          break;
        }
      }
      todayAttendance.value = match;
    } on Failure {
      todayAttendance.value = null;
    } catch (_) {
      todayAttendance.value = null;
    } finally {
      todayAttendanceLoading.value = false;
    }
  }

  bool isStartWork = false;
  final box = GetStorage();
  Timer? timer;
  DateTime? startTime;
  Rx<Duration> elapsed = Duration.zero.obs;

  void _loadStartTime() {
    final startMillis = box.read("work_start_time");
    if (startMillis != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      _startTimer();
    }
    isStartWork = box.read("isStartWork") ?? false;
    update();
  }

  void _saveStartTime() {
    box.write("work_start_time", startTime!.millisecondsSinceEpoch);
    update();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsed.value = DateTime.now().difference(startTime!);
    });
    update();
  }

  void onStartWork() {
    isStartWork = !isStartWork;
    box.write("isStartWork", isStartWork);
    if (startTime == null) {
      startTime = DateTime.now();
      _saveStartTime();
      _startTimer();
    }
    isStartWork = box.read("isStartWork") ?? false;
    update();
  }

  void onResetWork() {
    isStartWork = !isStartWork;
    box.write("isStartWork", isStartWork);
    timer?.cancel();
    startTime = null;
    elapsed.value = Duration.zero;
    isStartWork = box.read("isStartWork") ?? false;
    box.remove("work_start_time");
    update();
  }

  final formKey = GlobalKey<FormState>();

  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  final TextEditingController overtimeRequestController =
      TextEditingController();

  final TextEditingController loanRequestController = TextEditingController();
  List<Map<String, dynamic>> buttons = [
    {
      'id': '7',
      'title': 'employeeTasks',
      'route': AppRoutes.EMPLOYEETASKSSCREEN
    },
    {'id': '6', 'title': 'privateTasks', 'route': AppRoutes.PRIVATETASKSSCREEN},
    {
      'id': '5',
      'title': 'employeeDepartment',
      'route': AppRoutes.EMPLOYEESECTIONSCREEN
    },
    {
      'id': '4',
      'title': 'projectManagement',
      'route': AppRoutes.PROJECTMANAGEMENTSCREEN
    },
    {
      'id': '3',
      'title': 'targetSetting',
      'route': AppRoutes.TARGETSECTIONSCREEN
    },
    {
      'id': '2',
      'title': 'followUpDepartment',
      'route': AppRoutes.CURRENTFOLLOWUPSCREEN
    },
    {'id': '1', 'title': 'debts', 'route': AppRoutes.DEBTSSCREEN},
    {'id': '8', 'title': 'sales', 'route': AppRoutes.SALESSCREEN},
    {
      'id': '9',
      'title': 'generalData',
      'route': AppRoutes.GENERALDATALISTSCREEN
    },
    {'id': '16', 'title': 'stock', 'route': AppRoutes.STOCKSCREEN},
    {'id': '11', 'title': 'boxes', 'route': AppRoutes.BOXESSCREEN},
    {
      'id': '12',
      'title': 'purchasesandReturns',
      'route': AppRoutes.BUYINGSCREEN
    },
    {
      'id': '13',
      'title': 'financialMatters',
      'route': AppRoutes.FINANCIALAFFAIRSSCREEN
    },
    {
      'id': '14',
      'title': 'checksandCommitments',
      'route': AppRoutes.CHECKSSCREEN
    },
    {'id': '15', 'title': 'maintenance', 'route': AppRoutes.MAINTENANCESCREEN},
    if (!employeePermissions.contains(9))
      {
        'id': '40',
        'title': 'generalData',
        'route': AppRoutes.GENERALDATALISTSCREEN
      }
  ];
  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  final currentTab = 0.obs;
  final tabs = ['taskNotCompleted', 'taskCompleted'].obs;

  void changeTab(int index) {
    currentTab.value = index;
    scrollToToday();
    update();
  }

  List<Map<String, String>> employeeAddList = [
    {
      'title': 'overtimeRequest',
      'label': 'numbeOfOvertimeHours',
      'icon': AssetsManager.invoiceIcon,
    },
    {
      'title': 'loanRequest',
      'label': 'debtValue',
      'icon': AssetsManager.moneyIcon,
    },
  ];

  final RxBool isLoading = false.obs;

// Request Over Time Or Loan
  void requestOverTimeOrLoan({
    required BuildContext context,
    required bool isOverTime,
  }) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await requestOverTimeLoanUsecase.call(
        value: isOverTime
            ? overtimeRequestController.text
            : loanRequestController.text,
        isOverTime: isOverTime,
      );
      result.fold(
        (failure) {
          String errorMessages = '';
          bool data = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              if (key.startsWith('permissions')) {
                if (!data) {
                  errorMessages += "Permissions: ${value.first}\n";
                  data = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
          } else {
            errorMessages = failure.data?['message'] ?? failure.errMessage;
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
        },
        (success) {
          Get.back();
          Future.delayed(
            const Duration(milliseconds: 1500),
            () {
              Get.back();
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
  }

  final RxBool isTaskLoading = false.obs;
  final Rxn<int> completingTaskId = Rxn<int>();

  /// Camera-only proof then mark complete (from list checkbox).
  Future<void> completeTaskWithCameraProof(
    BuildContext context,
    Task task,
  ) async {
    final file = await CameraCaptureHelper.captureProof(context);
    if (file == null) return;

    completingTaskId.value = task.id;
    final uploadResult = await uploadTaskImageUsecase.call(
      isSubTask: false,
      taskId: task.id.toString(),
      image: [file],
    );

    final uploaded = await uploadResult.fold<Future<bool>>(
      (failure) async {
        Get.snackbar(
          'error'.tr,
          failure.data?['message']?.toString() ?? failure.errMessage,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      },
      (_) async => true,
    );

    completingTaskId.value = null;
    if (!uploaded) return;

    changeTaskToCompleted(
      context: context,
      isSubTask: false,
      taskId: task.id,
      task: task,
    );
  }

  /// Load the correct task, then open details (avoids showing a previous task).
  Future<void> openTaskDetails(Task task) async {
    if (!Get.isRegistered<EmployeeTasksController>()) {
      EmployeeTasksBinding().dependencies();
    }
    final tasksCtrl = Get.find<EmployeeTasksController>();
    final occurrenceId = task.isOccurrence
        ? (task.occurrenceId ?? task.id).toString()
        : null;

    TaskDetailsDebug.tap(
      source: 'EmployeeDashbordController.openTaskDetails',
      taskId: task.taskId.toString(),
      occurrenceId: occurrenceId,
      taskName: task.name,
      status: task.status,
    );

    try {
      await tasksCtrl.getTaskDetails(
        taskId: task.taskId.toString(),
        occurrenceId: occurrenceId,
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

    if (tasksCtrl.employeeTaskService.taskDetails.value == null) {
      TaskDetailsDebug.fail(
        'openTaskDetails_null_after_load',
        detail: {
          'taskId': task.taskId,
          'occurrenceId': occurrenceId,
        },
      );
      Get.snackbar(
        'error'.tr,
        'errorLoadingTaskDetails'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.toNamed(
      AppRoutes.TASKDETAILS,
      arguments: {
        'taskId': task.taskId.toString(),
        if (occurrenceId != null && occurrenceId.isNotEmpty)
          'occurrence_id': occurrenceId,
        'EmployeeDashbordController': this,
      },
    );
    await getEmployeeData(scrollToTodayb: false);
  }

  int? _occurrenceIdFor(Task? task) {
    if (task == null || !task.isOccurrence) return null;
    return task.occurrenceId ?? task.id;
  }

  /// Mark task or subtask complete (legacy row or v2 occurrence).
  Future<void> changeTaskToCompleted({
    required BuildContext context,
    required bool isSubTask,
    required int taskId,
    String? mainTaskId,
    String? reloadOccurrenceId,
    Task? task,
  }) async {
    final isOccurrence = task?.isOccurrence ?? false;
    final occurrenceId = _occurrenceIdFor(task);
    final isOccurrenceSubtask = isSubTask &&
        reloadOccurrenceId != null &&
        reloadOccurrenceId.isNotEmpty;
    completingTaskId.value = isSubTask ? taskId : (task?.id ?? taskId);
    isTaskLoading(true);
    try {
      final result = await changeTaskCompletedUasecase.call(
        isSubTask: isSubTask,
        taskId: taskId,
        isOccurrence: isOccurrence || isOccurrenceSubtask,
        occurrenceId: isSubTask ? null : occurrenceId,
      );
      await result.fold(
        (failure) async {
          String errorMessages = '';
          var permissionsShown = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              if (key.startsWith('permissions')) {
                if (!permissionsShown) {
                  errorMessages += "Permissions: ${value.first}\n";
                  permissionsShown = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
          } else {
            errorMessages = failure.data?['message'] ?? failure.errMessage;
          }
          Get.snackbar(
            'error'.tr,
            errorMessages,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1000),
          );
        },
        (success) async {
          Get.closeAllSnackbars();
          if (mainTaskId != null &&
              Get.isRegistered<EmployeeTasksController>()) {
            await Get.find<EmployeeTasksController>().getTaskDetails(
              taskId: mainTaskId,
              occurrenceId: reloadOccurrenceId,
            );
          }
          Future.delayed(
            const Duration(milliseconds: 1000),
            () => getEmployeeData(scrollToTodayb: false),
          );
          Get.snackbar(
            'success'.tr,
            success,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1000),
          );
        },
      );
    } finally {
      completingTaskId.value = null;
      isTaskLoading(false);
    }
  }

  // get employee data
  final Rxn<DashbordEmployeeDetailsModel> employeeData = Rxn();
  final Map<String, List<Task>> tasksData = {};
  final Map<String, List<Task>> tasksDataFilter = {};

  Future<void> getEmployeeData({bool scrollToTodayb = true}) async {
    employeeData.value != null ? isLoading(false) : isLoading(true);
    final result = await getEmployeeDataUsecase.call();
    final summary = result.todayTasksSummary.total > 0
        ? result.todayTasksSummary
        : TodayTasksSummary.fromTasks(result.tasks);
    employeeData.value = DashbordEmployeeDetailsModel(
      id: result.id,
      userId: result.userId,
      numberOfWorkHours: result.numberOfWorkHours,
      hourWorkPrice: result.hourWorkPrice,
      debts: result.debts,
      salary: result.salary,
      points: result.points,
      startWorkTime: result.startWorkTime,
      endWorkTime: result.endWorkTime,
      totalWorkHours: result.totalWorkHours,
      permissions: result.permissions,
      user: result.user,
      tasks: result.tasks,
      todayTasksSummary: summary,
    );
    isLoading(false);
    tasksData.clear();
    tasksDataFilter.clear();
    for (var task in employeeData.value!.tasks) {
      String dateKey =
          "${task.startTime.year}-${task.startTime.month.toString().padLeft(2, '0')}-${task.startTime.day.toString().padLeft(2, '0')}";
      tasksData.putIfAbsent(dateKey, () => []);
      if (!tasksData[dateKey]!.any((t) => t.id == task.id)) {
        tasksData[dateKey]!.add(task);
      }
    }
    syncPeriodBounds();
    tasksDataFilter.assignAll(filterByRange(tasksData));
    update();
    refreshTodayAttendance();
    if (scrollToTodayb) {
      Future.delayed(const Duration(milliseconds: 400), scrollToToday);
    }
  }

  // download report
  Future<void> downloadReport({
    required String customerId,
    required String customerName,
    required BuildContext context,
  }) async {
    try {
      Get.snackbar(
        "info".tr,
        "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
      // نجيب الداتا من API
      final response = await getDebtsReports.call(customerId: customerId);

      response.fold((failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'] ?? 'Unknown error',
        );
      }, (success) async {
        late Directory directory;
        if (Platform.isAndroid) {
          directory = Directory("/storage/emulated/0/Download/Doctor Bike/PDF");
        } else if (Platform.isIOS) {
          // على iOS نحفظ في Documents الخاص بالتطبيق
          final appDocDir = await getApplicationDocumentsDirectory();
          directory = Directory("${appDocDir.path}/Doctor Bike/PDF");
        } else {
          directory = Directory(
              "${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/PDF");
        }
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final filePath =
            "${directory.path}/تقرير_ساعات_عمل_$customerName${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(success);
        Get.snackbar(
          "fileDownloadedSuccessfully".tr,
          filePath,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 2000),
        );

        await OpenFilex.open(filePath);
      });
    } catch (e) {
      Get.snackbar(
        "error".tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2000),
      );
    }
  }

  static const String tasksViewDaily = 'daily';
  static const String tasksViewWeekly = 'weekly';
  static const String tasksViewMonthly = 'monthly';

  final RxString tasksViewMode = tasksViewDaily.obs;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  static String dateKeyFrom(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get periodLabel {
    if (tasksViewMode.value == tasksViewDaily) {
      return DateFormat('EEEE, d/M/yyyy', Get.locale?.languageCode)
          .format(startDate);
    }
    return '${DateFormat('d/M/yyyy').format(startDate)} — ${DateFormat('d/M/yyyy').format(endDate)}';
  }

  int get _periodDayCount => endDate.difference(startDate).inDays + 1;

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

  Map<String, List<Task>> filterByRange(Map<String, List<Task>> source) {
    final filtered = <String, List<Task>>{};
    for (int i = 0; i < _periodDayCount; i++) {
      final currentDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: i));
      final dateKey = dateKeyFrom(currentDay);
      filtered[dateKey] = List<Task>.from(source[dateKey] ?? []);
    }
    return LinkedHashMap.fromIterable(
      orderedDisplayKeys(filtered.keys.toList()),
      key: (k) => k as String,
      value: (k) => filtered[k]!,
    );
  }

  List<String> orderedDisplayKeys(List<String> keys) {
    if (keys.isEmpty) return [];
    final today = dateKeyFrom(DateTime.now());
    final entries = keys.map((k) => MapEntry(k, DateTime.parse(k))).toList();
    final todayEntry = entries.where((e) => e.key == today).toList();
    final future = entries
        .where((e) => e.key != today && !e.value.isBefore(DateTime.parse(today)))
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

  void filterDataByDateRange() {
    tasksDataFilter.assignAll(filterByRange(tasksData));
    update();
  }

  void setTasksViewMode(String mode) {
    tasksViewMode.value = mode;
    syncPeriodBounds(anchor: DateTime.now());
    filterDataByDateRange();
    scrollToToday();
    update();
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
        final m = DateTime(startDate.year, startDate.month + (isNext ? 1 : -1), 1);
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
    filterDataByDateRange();
    update();
  }

  void changeWeek(bool isNext) => changePeriod(isNext);

  void openTasksTab() {
    if (Get.isRegistered<BottomNavBarController>()) {
      Get.find<BottomNavBarController>().changePage(1);
    }
  }

  void openMyAttendanceHistory() {
    Get.toNamed(AppRoutes.MYATTENDANCEHISTORY);
  }

  DateTime getStartOfWeek(DateTime date) {
    int weekday = date.weekday; // 1 = Monday ... 7 = Sunday
    // لو السبت (6) هو بداية الأسبوع
    int daysToSubtract = (weekday >= 6) ? weekday - 6 : weekday + 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }

  final ScrollController scrollController = ScrollController();
  void scrollToToday() {
    DateTime today = DateTime.now();
    DateTime startOfWeek = getStartOfWeek(today);
    int todayIndex = today.difference(startOfWeek).inDays;

    // نحرك بناءً على index اليوم (0 = السبت، 6 = الجمعة)
    double position = todayIndex * 105.0; // عرض العنصر تقريبًا أو حجمه الرأسي
    scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onInit() async {
    super.onInit();
    if (Get.isRegistered<EmployeeNotificationBadgeController>()) {
      unawaited(Get.find<EmployeeNotificationBadgeController>().refresh());
    }
    syncPeriodBounds();
    _loadStartTime();
    getEmployeeData(scrollToTodayb: false);
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    opacityAnimation = Tween<double>(begin: 0, end: 1).animate(animController);
    sizeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animController, curve: Curves.fastOutSlowIn),
    );

    ever(isAddMenuOpen, (bool open) {
      if (open) {
        animController.forward();
      } else {
        animController.reverse();
      }
    });
  }

  @override
  void onClose() {
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    overtimeRequestController.dispose();
    loanRequestController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
