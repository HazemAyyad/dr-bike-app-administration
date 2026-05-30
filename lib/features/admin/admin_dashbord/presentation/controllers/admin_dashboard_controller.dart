import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
import '../../../notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../../../employee_section/data/models/logs_model.dart';
import '../../../employee_section/domain/usecases/cancel_log_usecase.dart';
import '../../../employee_section/domain/usecases/get_all_employee.dart';
import '../../data/models/main_dashboard_mata_model.dart';
import '../../domain/usecases/get_admin_logs_usecase.dart';
import '../../domain/usecases/get_main_dashboard_data_usecase.dart';

class AdminDashboardController extends GetxController
    with GetTickerProviderStateMixin {
  final GetAllEmployeeUsecase getAllEmployeeUsecase;
  final GetAdminLogsUsecase getAdminLogsUsecase;
  final CancelLogUsecase cancelLogUsecase;
  final GetMainDashboardDataUsecase getMainDashboardDataUsecase;

  AdminDashboardController({
    required this.getAllEmployeeUsecase,
    required this.getAdminLogsUsecase,
    required this.cancelLogUsecase,
    required this.getMainDashboardDataUsecase,
  });

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
    // {'id': '17', 'title': 'messagesDepartment', 'route': ''},
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
    // {'id': '10', 'title': 'partnersDepartment', 'route': ''},
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

    {'id': '15', 'title': 'maintenance', 'route': AppRoutes.MAINTENANCESCREEN},
    {
      'id': '18',
      'title': 'productManagement',
      'route': AppRoutes.PRODUCTMANAGEMENTSCREEN
    },
    {
      'id': '14',
      'title': 'checksandCommitments',
      'route': AppRoutes.CHECKSSCREEN
    },
    {
      'id': '19',
      'title': 'categoryManagement',
      'route': AppRoutes.CATEGORYMANAGEMENTSCREEN
    },
    {
      'id': '20',
      'title': 'generalSettings',
      'route': AppRoutes.GENERALSETTINGSSCREEN
    },
    {
      'id': '21',
      'title': 'globalEmployeePointsTitle',
      'route': AppRoutes.GLOBALEMPLOYEEPOINTSSCREEN
    },
    {
      'id': '22',
      'title': 'pointsReportTitle',
      'route': AppRoutes.EMPLOYEEPOINTSREPORTSCREEN
    },
    {
      'id': '23',
      'title': 'employeeReminders',
      'route': AppRoutes.EMPLOYEEREMINDERSSCREEN
    },
  ];

  // متغيرات للإحصائيات
  final RxInt debtToUs = 100.obs;
  final RxInt debtOnUs = 20.obs;
  final RxInt products = 150.obs;
  final RxInt completedTasks = 30.obs;
  final RxInt pendingTasks = 5.obs;
  final RxInt expenses = 1200.obs;

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> adminAddList = [
    {
      'title': 'newInvoice',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.ADDNEWBILLSCREEN
    },
    {
      'title': 'newEmployee',
      'icon': AssetsManager.userIcon,
      'route': AppRoutes.ADDNEWEMPLOYEESCREEN,
    },
    {
      'title': 'newExpense',
      'icon': AssetsManager.moneyIcon,
      'route': AppRoutes.ADDEXPENSESCREEN,
    },
    {
      'title': 'newCustomer',
      'icon': AssetsManager.userIcon,
      'route': AppRoutes.ADDNEWCUSTOMERSCREEN,
    },
  ];

  final RxBool isLoading = false.obs;
  final RxBool isLogsLoading = false.obs;

  final Map<String, List<LogsModel>> logsMap = {};
  String logsSearchQuery = '';
  DateTime? logsFilterDate;
  DateTimeRange? logsFilterRange;
  bool logsNewestFirst = true;

  void setLogsSearchQuery(String value) {
    logsSearchQuery = value.trim();
    update();
  }

  void setLogsFilterDate(DateTime? value) {
    logsFilterDate = value;
    if (value != null) logsFilterRange = null;
    update();
  }

  void setLogsFilterRange(DateTimeRange? value) {
    logsFilterRange = value;
    if (value != null) logsFilterDate = null;
    update();
  }

  void clearLogsFilters() {
    logsSearchQuery = '';
    logsFilterDate = null;
    logsFilterRange = null;
    update();
  }

  void toggleLogsSortOrder() {
    logsNewestFirst = !logsNewestFirst;
    _sortLogsMap();
    update();
  }

  // Get Logs
  void getLogs() async {
    isLogsLoading(true);
    update();
    logsMap.clear();
    final result = await getAdminLogsUsecase.call()
      ..sort(_compareLogsByDate);
    for (var task in result) {
      String dateKey =
          "${task.createdAt.year}-${task.createdAt.month}-${task.createdAt.day}";
      if (logsMap.containsKey(dateKey)) {
        if (!logsMap[dateKey]!.any((t) => t.id == task.id)) {
          logsMap[dateKey]!.add(task);
        }
      } else {
        logsMap[dateKey] = [task];
      }
    }
    _sortLogsMap();
    isLogsLoading(false);
    update();
  }

  int _compareLogsByDate(LogsModel a, LogsModel b) {
    final comparison = b.createdAt.compareTo(a.createdAt);
    return logsNewestFirst ? comparison : -comparison;
  }

  void _sortLogsMap() {
    for (final logs in logsMap.values) {
      logs.sort(_compareLogsByDate);
    }

    final entries = logsMap.entries.toList()
      ..sort((a, b) {
        if (a.value.isEmpty || b.value.isEmpty) return 0;
        final comparison = b.value.first.createdAt.compareTo(
          a.value.first.createdAt,
        );
        return logsNewestFirst ? comparison : -comparison;
      });

    logsMap
      ..clear()
      ..addEntries(entries);
  }

  // cancel Log
  void cancelLog({
    required BuildContext context,
    required String logId,
  }) async {
    isLoading(true);
    final result = await cancelLogUsecase.call(logId: logId);
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            getLogs();
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
    update();
  }

  // get Main Dashboard Data
  MainDashboardDataModel? mainDashboardDataModel;
  void getMainDashboardData() async {
    isLoading(true);
    final result = await getMainDashboardDataUsecase.call();
    mainDashboardDataModel = result;
    isLoading(false);
    update();
  }

  @override
  void onInit() async {
    if (userType == 'admin') {
      if (!Get.isRegistered<AdminNotificationBadgeController>()) {
        Get.put(AdminNotificationBadgeController(), permanent: true);
      }
      Get.find<AdminNotificationBadgeController>().refresh();
    }
    getMainDashboardData();
    super.onInit();
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
    super.onClose();
  }
}
