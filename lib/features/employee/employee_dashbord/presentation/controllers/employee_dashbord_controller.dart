import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';
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

  EmployeeDashbordController({
    required this.requestOverTimeLoanUsecase,
    required this.getEmployeeDataUsecase,
    required this.changeTaskCompletedUasecase,
  });
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
    {
      'id': '14',
      'title': 'checksandCommitments',
      'route': AppRoutes.CHECKSSCREEN
    },
    {'id': '15', 'title': 'maintenance', 'route': AppRoutes.MAINTENANCESCREEN},
    {
      // 'id': '18',
      // 'title': 'countersAndStatisticsAndReports',
      // 'route': AppRoutes.COUNTERSSCREEN
    },
  ];
  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  final currentTab = 0.obs;
  final tabs = ['taskNotCompleted', 'taskCompleted'].obs;

  void changeTab(int index) {
    currentTab.value = index;
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
          duration: const Duration(milliseconds: 1500),
        );
      },
      (success) {
        if (mainTaskId != null) {
          Get.find<EmployeeTasksController>()
              .getTaskDetails(taskId: mainTaskId.toString());
        }
        // Get.back();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            getEmployeeData();
            Get.back();
          },
        );
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isTaskLoading(false);
  }

  // get employee data
  final Rxn<DashbordEmployeeDetailsModel> employeeData = Rxn();
  final Map<String, List<Task>> tasksData = {};
  void getEmployeeData() async {
    employeeData.value != null ? isLoading(false) : isLoading(true);
    final result = await getEmployeeDataUsecase.call();
    employeeData.value = result;
    isLoading(false);

    for (var task in employeeData.value!.tasks) {
      String dateKey =
          "${DateFormat.E('ar').format(task.endTime)} ${task.endTime.year}/${task.endTime.month.toString().padLeft(2, '0')}/${task.endTime.day.toString().padLeft(2, '0')}";
      tasksData.putIfAbsent(dateKey, () => []);
      if (!tasksData[dateKey]!.any((t) => t.id == task.id)) {
        tasksData[dateKey]!.add(task);
      }
    }
    update();
  }

  @override
  void onInit() async {
    super.onInit();
    getEmployeeData();
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
    super.onClose();
  }
}
