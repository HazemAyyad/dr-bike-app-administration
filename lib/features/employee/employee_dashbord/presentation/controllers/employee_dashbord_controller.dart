import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:doctorbike/core/services/initial_bindings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../admin/debts/domain/usecases/get_debts_reports_usecase.dart';
import '../../../../admin/employee_tasks/presentation/controllers/employee_tasks_controller.dart';
import '../../data/models/dashbord_employee_details_model.dart';
import '../../domain/usecases/change_task_completed_uasecase.dart';
import '../../domain/usecases/get_employee_data_usecase.dart';
import '../../domain/usecases/request_over_time_loan_usecase.dart';

class EmployeeDashbordController extends GetxController
    with GetTickerProviderStateMixin {
  final RequestOverTimeLoanUsecase requestOverTimeLoanUsecase;
  final GetEmployeeDataUsecase getEmployeeDataUsecase;
  final ChangeTaskCompletedUasecase changeTaskCompletedUasecase;
  final GetDebtsReportsUsecase getDebtsReports;

  EmployeeDashbordController({
    required this.requestOverTimeLoanUsecase,
    required this.getEmployeeDataUsecase,
    required this.changeTaskCompletedUasecase,
    required this.getDebtsReports,
  });
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

// change task to completed
  void changeTaskToCompleted({
    required BuildContext context,
    required bool isSubTask,
    required int taskId,
    String? mainTaskId,
  }) async {
    isTaskLoading(true);
    final result = await changeTaskCompletedUasecase.call(
      isSubTask: isSubTask,
      taskId: taskId,
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
        Get.snackbar(
          'error'.tr,
          errorMessages,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
      (success) {
        Get.closeAllSnackbars();
        // Get.back();
        if (mainTaskId != null) {
          Get.find<EmployeeTasksController>()
              .getTaskDetails(taskId: mainTaskId.toString());
        }
        // Get.back();
        Future.delayed(
          const Duration(milliseconds: 1000),
          () {
            getEmployeeData(scrollToTodayb: false);
            // Get.back();
          },
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1000),
        );
      },
    );
    isTaskLoading(false);
  }

  // get employee data
  final Rxn<DashbordEmployeeDetailsModel> employeeData = Rxn();
  final Map<String, List<Task>> tasksData = {};
  final Map<String, List<Task>> tasksDataFilter = {};

  void getEmployeeData({bool scrollToTodayb = true}) async {
    employeeData.value != null ? isLoading(false) : isLoading(true);
    final result = await getEmployeeDataUsecase.call();
    employeeData.value = result;
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
    tasksDataFilter.assignAll(filterByRange(tasksData));
    update();
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

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  Map<String, List<Task>> filterByRange(Map<String, List<Task>> source) {
    final filtered = <String, List<Task>>{};

    // نضمن إن الأسبوع دايمًا 7 أيام من السبت للجمعة
    for (int i = 0; i < 7; i++) {
      final currentDay = startDate.add(Duration(days: i));
      final dateKey =
          "${currentDay.year}-${currentDay.month.toString().padLeft(2, '0')}-${currentDay.day.toString().padLeft(2, '0')}";

      // لو اليوم موجود في الـ source نضيف المهام، لو مش موجود نحط لستة فاضية
      filtered[dateKey] = List<Task>.from(source[dateKey] ?? []);
    }

    // الترتيب تنازليًا (اختياري)
    return LinkedHashMap.fromEntries(
      filtered.entries.toList()
        ..sort(
            (a, b) => DateTime.parse(b.key).compareTo(DateTime.parse(a.key))),
    );
  }

  void filterDataByDateRange() {
    tasksDataFilter.assignAll(filterByRange(tasksData));
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
    startDate = getStartOfWeek(DateTime.now());
    endDate = startDate.add(const Duration(days: 6));
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
