import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:open_filex/open_filex.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/impersonation_service.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/user_data.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/datasources/employee_datasource.dart';
import '../../../counters/domain/usecases/get_report_by_type_usecase.dart';
import '../../data/models/financial_details_model.dart';
import '../../data/models/employee_advances_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../data/models/overtime_and_loan_model.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/working_times_entity.dart';
import '../../domain/usecases/approve_employee_order_usecase.dart';
import '../../domain/usecases/cancel_log_usecase.dart';
import '../../domain/usecases/change_employee_password_usecase.dart';
import '../../domain/usecases/delete_employee_usecase.dart';
import '../../domain/usecases/employee_details_usecase.dart';
import '../../domain/usecases/employee_advances_usecase.dart';
import '../../domain/usecases/financial_details_usecase.dart';
import '../../domain/usecases/financial_dues.usecase.dart';
import '../../domain/usecases/get_all_employee.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../../domain/usecases/overtime_and_loan_usecase.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';
import '../../domain/usecases/qr_generation_usecase.dart';
import '../../domain/usecases/qr_history_usecase.dart';
import '../../domain/usecases/reject_order_usecase.dart';
import '../../domain/usecases/get_suspended_employees_usecase.dart';
import '../../domain/usecases/suspend_employee_usecase.dart';
import '../../domain/usecases/working_times_usecase.dart';
import '../../domain/usecases/admin_users_usecase.dart';
import '../../data/models/admin_user_model.dart';
import 'employee_service.dart';

class EmployeeSectionController extends GetxController
    with GetTickerProviderStateMixin {
  final PaySalaryToEmployeeUsecase paySalaryEmployee;
  final GetAllEmployeeUsecase getAllEmployeeUsecase;
  final WorkingTimesUsecase workingTimesUsecase;
  final FinancialDuesUsecase financialDuesUsecase;
  final FinancialDetailsUsecase financialDetailsUsecase;
  final EmployeeAdvancesUsecase employeeAdvancesUsecase;
  final EmployeeDetailsUsecase employeeDetailsUsecase;
  final QrGenerationUsecase qrGenerationUsecase;
  final QrHistoryUsecase qrHistoryUsecase;
  final OvertimeAndLoanUsecase overtimeAndLoanUsecase;
  final RejectOrderUsecase rejectOrderUsecase;
  final ApproveEmployeeOrderUsecase approveEmployeeOrderUsecase;
  final GetLogsUsecase getLogsUsecase;
  final CancelLogUsecase cancelLogUsecase;
  final DeleteEmployeeUsecase deleteEmployeeUsecase;
  final SuspendEmployeeUsecase suspendEmployeeUsecase;
  final RestoreSuspendedEmployeeUsecase restoreSuspendedEmployeeUsecase;
  final GetSuspendedEmployeesUsecase getSuspendedEmployeesUsecase;
  final ChangeEmployeePasswordUsecase changeEmployeePasswordUsecase;
  final GetAdminUsersUsecase getAdminUsersUsecase;
  final ManageAdminUserUsecase manageAdminUserUsecase;
  final EmployeeService employeeService;
  final GetReportByTypeUsecase getReportByType;

  EmployeeSectionController({
    required this.paySalaryEmployee,
    required this.getAllEmployeeUsecase,
    required this.workingTimesUsecase,
    required this.financialDuesUsecase,
    required this.financialDetailsUsecase,
    required this.employeeAdvancesUsecase,
    required this.employeeDetailsUsecase,
    required this.qrGenerationUsecase,
    required this.qrHistoryUsecase,
    required this.overtimeAndLoanUsecase,
    required this.rejectOrderUsecase,
    required this.approveEmployeeOrderUsecase,
    required this.getLogsUsecase,
    required this.cancelLogUsecase,
    required this.deleteEmployeeUsecase,
    required this.suspendEmployeeUsecase,
    required this.restoreSuspendedEmployeeUsecase,
    required this.getSuspendedEmployeesUsecase,
    required this.changeEmployeePasswordUsecase,
    required this.getAdminUsersUsecase,
    required this.manageAdminUserUsecase,
    required this.employeeService,
    required this.getReportByType,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // final TextEditingController fromDateController = TextEditingController();
  // final TextEditingController toDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();

  RxInt currentTab = 0.obs;
  static const int employeeListTab = 0;
  static const int workHoursTab = 1;
  static const int entitlementsTab = 2;
  static const int loansTab = 3;
  static const int overtimeTab = 4;
  static const int adminsTab = 5;
  static const int suspendedEmployeesTab = 6;

  final tabs = <String>[].obs;
  final visibleTabIndexes = <int>[].obs;
  final RxInt actionTab = (-1).obs;

  final RxBool isLoading = false.obs;

  bool get isEmployeeListMergedWithWorkHours =>
      canViewEmployees && canViewEmployeesAttendance;

  int get pendingLoanRequestsCount => employeeService.loanList
      .where((request) => request.orderStatus == 'pending')
      .length;

  List<DateTime>? dateTimeList;
  final Rx<DateTime> selectedFinancialMonth = DateTime.now().obs;
  final Rx<DateTime> selectedFinancialDate = DateTime.now().obs;

  void changeTab(int index) {
    actionTab.value = -1;
    currentTab.value = index;
    if (activeTab == adminsTab) {
      getAdminUsers();
    }
  }

  void openLoansTab() {
    actionTab.value = loansTab;
  }

  void openEntitlementsTab() {
    actionTab.value = entitlementsTab;
  }

  void openSuspendedEmployeesTab() {
    actionTab.value = suspendedEmployeesTab;
    getSuspendedEmployees();
  }

  int get activeTab {
    if (actionTab.value >= 0) {
      return actionTab.value;
    }
    if (visibleTabIndexes.isEmpty) {
      return employeeListTab;
    }

    final index = currentTab.value.clamp(0, visibleTabIndexes.length - 1);
    return visibleTabIndexes[index];
  }

  void syncVisibleTabs() {
    final nextTabs = <String>[];
    final nextIndexes = <int>[];

    void add(int index, String label, bool visible) {
      if (!visible) return;
      nextIndexes.add(index);
      nextTabs.add(label);
    }

    add(employeeListTab, 'employeeList', canViewEmployees);
    add(
      workHoursTab,
      'workHours',
      canViewEmployeesAttendance && !isEmployeeListMergedWithWorkHours,
    );
    add(overtimeTab, 'overtime',
        canManageEmployeesOrders || canViewEmployeesAttendance);
    add(adminsTab, 'admins', userType == 'admin');
    add(suspendedEmployeesTab, 'suspendedEmployees', canViewEmployees);

    tabs.assignAll(nextTabs);
    visibleTabIndexes.assignAll(nextIndexes);
    if (actionTab.value == loansTab && !canManageEmployeesOrders) {
      actionTab.value = -1;
    }
    if (actionTab.value == entitlementsTab && !canViewEmployeesFinancial) {
      actionTab.value = -1;
    }
    if (currentTab.value >= tabs.length) {
      currentTab.value = 0;
    }
  }

  final TextEditingController paySalaryController = TextEditingController();

  final TextEditingController overtimeValueController = TextEditingController();

  final TextEditingController loanValueController = TextEditingController();
  final RxList<Map<String, dynamic>> loanApprovalBoxes =
      <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> selectedLoanApprovalBox =
      Rxn<Map<String, dynamic>>();
  final RxBool isLoanApprovalBoxesLoading = false.obs;
  final TextEditingController rejectionReasonController =
      TextEditingController();

  final TextEditingController extraWorkHoursController =
      TextEditingController();

  RxBool loanValue = false.obs;

  RxBool rejectOrder = false.obs;

  RxBool extraWorkHours = false.obs;
  final TextEditingController addRegularWorkingHoursController =
      TextEditingController();

  RxBool overtimeValue = false.obs;
  final TextEditingController addWorkHoursController = TextEditingController();

  void setOnlyOneTrue(String key) {
    loanValue.value = key == 'loanValue';
    rejectOrder.value = key == 'rejectOrder';
    extraWorkHours.value = key == 'extraWorkHours';
    overtimeValue.value = key == 'overtimeValue';
  }

  Future<void> loadLoanApprovalBoxes() async {
    if (isLoanApprovalBoxesLoading.value) return;
    try {
      isLoanApprovalBoxesLoading.value = true;
      final boxes = await Get.find<EmployeeDatasource>()
          .getShownBoxesForEmployeeAdvance();
      loanApprovalBoxes.assignAll(boxes);
    } catch (_) {
      loanApprovalBoxes.clear();
      selectedLoanApprovalBox.value = null;
    } finally {
      isLoanApprovalBoxesLoading.value = false;
    }
  }

  int? get selectedLoanApprovalBoxId {
    final box = selectedLoanApprovalBox.value;
    if (box == null) return null;
    return int.tryParse((box['box_id'] ?? box['id'] ?? '').toString());
  }

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> addList = [
    {
      'title': 'newEmployee',
      'icon': AssetsManager.userIcon,
      'route': AppRoutes.ADDNEWEMPLOYEESCREEN
    },
    {
      'title': 'newAdmin',
      'icon': AssetsManager.userIcon,
      'route': AppRoutes.ADDEDITADMINSCREEN,
    },
  ];

  List<Map<String, String>> get visibleAddList => addList.where((item) {
        final route = item['route'];
        if (route == AppRoutes.ADDNEWEMPLOYEESCREEN) {
          return canCreateEmployees;
        }
        if (route == AppRoutes.ADDEDITADMINSCREEN) {
          return userType == 'admin';
        }

        return true;
      }).toList();

  bool get canShowAddMenu =>
      visibleAddList.isNotEmpty || canManageEmployeesAttendance;

  final RxBool isPaymentLoading = false.obs;
  //pay Salary To Employee
  void paySalaryToEmployee(BuildContext context, String employeeId) async {
    if ((formKey.currentState as FormState).validate()) {
      isPaymentLoading(true);
      final result = await paySalaryEmployee.call(
        employeeId: employeeId,
        salary: paySalaryController.text,
      );
      result.fold(
        (failure) {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        },
        (success) {
          getFinancialDues();
          paySalaryController.clear();
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
      isPaymentLoading(false);
    }
  }

  // reject Employee Order
  void rejectEmployeeOrder(BuildContext context, String employeeOrderId) async {
    isPaymentLoading(true);
    final result = await rejectOrderUsecase.call(
      employeeOrderId: employeeOrderId,
      rejectionReason: rejectionReasonController.text.trim(),
    );
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        overtimeValueController.clear();
        loanValueController.clear();
        rejectionReasonController.clear();
        extraWorkHoursController.clear();
        loanValue.value = false;
        rejectOrder.value = false;
        extraWorkHours.value = false;
        overtimeValue.value = false;
        Get.back();
        getOvertimeAndLoan();
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
    isPaymentLoading(false);
  }

  // approve Employee Order
  void approveEmployeeOrder({
    required BuildContext context,
    required String employeeOrderId,
  }) async {
    final selectedBox = selectedLoanApprovalBox.value;
    final selectedBoxId = selectedLoanApprovalBoxId;
    if (loanValue.value && selectedBox != null && (selectedBoxId ?? 0) <= 0) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message:
            'تعذر قراءة رقم الصندوق المختار. أعد تحميل الصفحة وجرب مرة ثانية.',
      );
      return;
    }

    isPaymentLoading(true);
    final result = await approveEmployeeOrderUsecase.call(
      employeeOrderId: employeeOrderId,
      overtimeValue: overtimeValueController.text.isEmpty
          ? ''
          : overtimeValueController.text,
      loanValue:
          loanValueController.text.isEmpty ? '' : loanValueController.text,
      extraWorkHoursValue: extraWorkHoursController.text.isEmpty
          ? ''
          : extraWorkHoursController.text,
      boxId: selectedBoxId,
    );
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        overtimeValueController.clear();
        loanValueController.clear();
        rejectionReasonController.clear();
        extraWorkHoursController.clear();
        selectedLoanApprovalBox.value = null;
        loanValue.value = false;
        rejectOrder.value = false;
        extraWorkHours.value = false;
        overtimeValue.value = false;
        Get.back();
        getOvertimeAndLoan();
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
    isPaymentLoading(false);
  }

  // cancel Log
  void cancelLog({
    required BuildContext context,
    required String logId,
  }) async {
    isPaymentLoading(true);
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
          const Duration(milliseconds: 1000),
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
    isPaymentLoading(false);
    update();
  }

  //Get Employee
  Future<void> getEmployee() async {
    final showLoader = employeeService.employeeList.isEmpty;
    if (showLoader) isLoading(true);
    try {
      final result = await getAllEmployeeUsecase.call();
      employeeService.employeeList.assignAll(result);
      filteredEmployees.assignAll(employeeService.employeeList);
    } on Failure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoader) isLoading(false);
    }
  }

  Future<void> getSuspendedEmployees() async {
    try {
      final result = await getSuspendedEmployeesUsecase.call();
      employeeService.suspendedEmployeeList.assignAll(result);
      filteredSuspendedEmployees
          .assignAll(employeeService.suspendedEmployeeList);
    } on Failure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getAdminUsers() async {
    final showLoader = employeeService.adminList.isEmpty;
    if (showLoader) isLoading(true);
    try {
      final search = employeeNameController.text.trim();
      final result = await getAdminUsersUsecase.call(
        search: search.isEmpty ? null : search,
      );
      employeeService.adminList.assignAll(result);
      filteredAdmins.assignAll(employeeService.adminList);
    } on Failure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoader) isLoading(false);
      update();
    }
  }

  Future<void> deleteAdmin(String adminId) async {
    isLoading(true);
    update();
    final result = await manageAdminUserUsecase.delete(adminId: adminId);
    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      ),
      (success) async {
        Get.snackbar('success'.tr, success,
            snackPosition: SnackPosition.BOTTOM);
        await getAdminUsers();
      },
    );
    isLoading(false);
    update();
  }

  Future<void> toggleAdminBlock(String adminId) async {
    isLoading(true);
    update();
    final result = await manageAdminUserUsecase.toggleBlock(adminId: adminId);
    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      ),
      (success) async {
        Get.snackbar('success'.tr, success,
            snackPosition: SnackPosition.BOTTOM);
        await getAdminUsers();
      },
    );
    isLoading(false);
    update();
  }

  Future<void> updateAdminDevelopmentRole({
    required AdminUserModel admin,
    required String developmentRole,
  }) async {
    isLoading(true);
    update();
    final result = await manageAdminUserUsecase.updateDevelopmentRole(
      adminId: admin.id.toString(),
      developmentRole: developmentRole,
    );
    result.fold(
      (failure) => Get.snackbar(
        'error'.tr,
        failure.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      ),
      (success) async {
        Get.snackbar('success'.tr, success,
            snackPosition: SnackPosition.BOTTOM);
        await getAdminUsers();
      },
    );
    isLoading(false);
    update();
  }

  final RxBool isDeletingEmployee = false.obs;
  final RxBool isSuspendingEmployee = false.obs;
  final RxBool isChangingEmployeePassword = false.obs;
  final TextEditingController employeePasswordController =
      TextEditingController();
  final TextEditingController employeePasswordConfirmationController =
      TextEditingController();

  /// Soft-deletes an employee on the backend and removes them from the
  /// local cached lists so the UI reflects the change immediately.
  Future<bool> deleteEmployee(String employeeId) async {
    isDeletingEmployee.value = true;
    try {
      final result = await deleteEmployeeUsecase.call(employeeId: employeeId);
      return result.fold(
        (failure) {
          Get.snackbar(
            'error'.tr,
            failure.errMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        },
        (message) {
          final int? id = int.tryParse(employeeId);
          if (id != null) {
            employeeService.employeeList.removeWhere((e) => e.id == id);
            employeeService.suspendedEmployeeList
                .removeWhere((e) => e.id == id);
            employeeService.workingTimesList.removeWhere((e) => e.id == id);
            employeeService.financialDuesList.removeWhere((e) => e.id == id);
            filteredEmployees.removeWhere((e) => e.id == id);
            filteredSuspendedEmployees.removeWhere((e) => e.id == id);
            filteredWorkingTimes.removeWhere((e) => e.id == id);
            filteredFinancialDues.removeWhere((e) => e.id == id);
          }
          Get.snackbar(
            'success'.tr,
            message.isNotEmpty ? message : 'employeeDeletedSuccess'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F5E9),
            colorText: const Color(0xFF1B5E20),
          );
          return true;
        },
      );
    } finally {
      isDeletingEmployee.value = false;
    }
  }

  Future<bool> suspendEmployee(String employeeId, {String? reason}) async {
    isSuspendingEmployee.value = true;
    try {
      final result = await suspendEmployeeUsecase.call(
        employeeId: employeeId,
        reason: reason,
      );
      return result.fold(
        (failure) {
          Get.snackbar(
            'error'.tr,
            failure.errMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        },
        (message) async {
          await _refreshEmployeesAfterStatusChange();
          Get.snackbar(
            'success'.tr,
            message.isNotEmpty ? message : 'employeeSuspendedSuccess'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFFFF7ED),
            colorText: const Color(0xFF9A3412),
          );
          return true;
        },
      );
    } finally {
      isSuspendingEmployee.value = false;
    }
  }

  Future<bool> restoreSuspendedEmployee(String employeeId) async {
    isSuspendingEmployee.value = true;
    try {
      final result = await restoreSuspendedEmployeeUsecase.call(
        employeeId: employeeId,
      );
      return result.fold(
        (failure) {
          Get.snackbar(
            'error'.tr,
            failure.errMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        },
        (message) async {
          await _refreshEmployeesAfterStatusChange();
          Get.snackbar(
            'success'.tr,
            message.isNotEmpty ? message : 'employeeRestoredSuccess'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F5E9),
            colorText: const Color(0xFF1B5E20),
          );
          return true;
        },
      );
    } finally {
      isSuspendingEmployee.value = false;
    }
  }

  Future<void> _refreshEmployeesAfterStatusChange() async {
    if (canViewEmployees) {
      await getEmployee();
      await getSuspendedEmployees();
    }
    if (canViewEmployeesAttendance) {
      getWorkingTimes();
    }
    if (canViewEmployeesFinancial) {
      getFinancialDues();
    }
  }

  Future<bool> changeEmployeePassword(String employeeId) async {
    isChangingEmployeePassword.value = true;
    try {
      final result = await changeEmployeePasswordUsecase.call(
        employeeId: employeeId,
        password: employeePasswordController.text,
        passwordConfirmation: employeePasswordConfirmationController.text,
      );
      return result.fold(
        (failure) {
          Get.snackbar(
            'error'.tr,
            failure.errMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        },
        (message) {
          employeePasswordController.clear();
          employeePasswordConfirmationController.clear();
          Get.snackbar(
            'success'.tr,
            message.isNotEmpty
                ? message
                : 'employeePasswordChangedSuccessfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE8F5E9),
            colorText: const Color(0xFF1B5E20),
          );
          return true;
        },
      );
    } finally {
      isChangingEmployeePassword.value = false;
    }
  }

  final RxBool isManualCheckoutLoading = false.obs;

  Future<void> manualCheckoutEmployee(BuildContext context) async {
    final details = employeeService.employeeDetails.value;
    if (details == null || isManualCheckoutLoading.value) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('manualCheckout'.tr),
        content: Text('manualCheckoutConfirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
    if (ok != true) return;

    isManualCheckoutLoading.value = true;
    try {
      final raw = await Get.find<EmployeeDatasource>()
          .manualEmployeeCheckout(employeeId: details.id.toString());
      if (raw['status']?.toString() != 'success') {
        if (!context.mounted) return;
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: raw['message']?.toString() ?? 'error'.tr,
        );
        return;
      }
      await employeeDetailsUsecase.call(employeeId: details.id.toString());
      if (!context.mounted) return;
      Get.snackbar(
        'success'.tr,
        raw['message']?.toString() ?? 'manualCheckoutSuccess'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ServerException catch (e) {
      if (!context.mounted) return;
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: e.errorModel.errorMessage,
      );
    } catch (e) {
      if (!context.mounted) return;
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: e.toString(),
      );
    } finally {
      isManualCheckoutLoading.value = false;
    }
  }

  /// Employee row id currently loading for impersonation (0 = none).
  final RxInt impersonatingEmployeeId = 0.obs;
  final RxInt currentEmployeeRecordId = 0.obs;

  bool canShowImpersonateFor(int targetEmployeeId) {
    if (!ImpersonationService.canImpersonateEmployees) return false;
    if (userType == 'employee' &&
        currentEmployeeRecordId.value != 0 &&
        currentEmployeeRecordId.value == targetEmployeeId) {
      return false;
    }
    return true;
  }

  Future<void> _resolveCurrentEmployeeRecordId() async {
    if (userType != 'employee') return;
    final user = await UserData.getSavedUser();
    currentEmployeeRecordId.value = user?.user.employee.id ?? 0;
  }

  Future<void> impersonateEmployee(
    BuildContext context,
    EmployeeEntity employee,
  ) async {
    if (!canShowImpersonateFor(employee.id)) return;
    if (await ImpersonationService.isActive) {
      if (!context.mounted) return;
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'impersonationAlreadyActive'.tr,
      );
      return;
    }

    impersonatingEmployeeId.value = employee.id;
    try {
      final raw =
          await Get.find<EmployeeDatasource>().impersonateEmployee(employee.id);
      await ImpersonationService.startFromLoginResponse(raw);
    } on ServerException catch (e) {
      if (!context.mounted) return;
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: e.errorModel.errorMessage,
      );
    } catch (e) {
      if (!context.mounted) return;
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'impersonationFailed'.tr,
      );
    } finally {
      impersonatingEmployeeId.value = 0;
    }
  }

  //Get Working Times
  void getWorkingTimes() async {
    final showLoader = employeeService.workingTimesList.isEmpty;
    if (showLoader) isLoading(true);
    try {
      final result = await workingTimesUsecase.call();
      employeeService.workingTimesList.assignAll(result);
      filteredWorkingTimes.assignAll(employeeService.workingTimesList);
    } on Failure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoader) isLoading(false);
    }
  }

  //Get Financial Dues
  void getFinancialDues() async {
    final showLoader = employeeService.financialDuesList.isEmpty;
    if (showLoader) isLoading(true);
    try {
      final result = await financialDuesUsecase.call();
      employeeService.financialDuesList.assignAll(result);
      filteredFinancialDues.assignAll(employeeService.financialDuesList);
    } on Failure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoader) isLoading(false);
    }
  }

  RxBool isDialogLoading = false.obs;
  RxBool isAdvancesLoading = false.obs;
  RxString advancesError = ''.obs;

  /// تحميل شاشة سجل QR (منفصل عن [isDialogLoading] حتى لا يتعارض مع المودال)
  RxBool isQrHistoryLoading = false.obs;

  // Get Financial Details
  Rxn<FinancialDetailsModel> financialDetailsList =
      Rxn<FinancialDetailsModel>();
  Rxn<EmployeeAdvancesResult> employeeAdvances = Rxn<EmployeeAdvancesResult>();

  String formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _syncFinancialPeriodContext() {
    final d = selectedFinancialDate.value;
    selectedFinancialMonth.value = DateTime(d.year, d.month, 1);
    dateTimeList = [
      DateTime(d.year, d.month, 1),
      DateTime(d.year, d.month + 1, 0),
    ];
  }

  String formatMonthLabel(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void openFinancialDetails(String employeeId) {
    final now = DateTime.now();
    selectedFinancialDate.value = DateTime(now.year, now.month, now.day);
    _syncFinancialPeriodContext();
    financialDetailsList.value = null;
    getFinancialDetails(employeeId);
  }

  void getFinancialDetails(String employeeId) async {
    employeeId == financialDetailsList.value?.employeeId.toString()
        ? isDialogLoading(false)
        : isDialogLoading(true);
    final result = await financialDetailsUsecase.call(
      employeeId: employeeId,
      month: formatMonthKey(selectedFinancialDate.value),
      date: formatDateKey(selectedFinancialDate.value),
    );
    financialDetailsList.value = result;
    isDialogLoading(false);
  }

  void setFinancialDate(DateTime date) {
    selectedFinancialDate.value = DateTime(date.year, date.month, date.day);
    _syncFinancialPeriodContext();
    final employeeId = financialDetailsList.value?.employeeId;
    if (employeeId != null) {
      getFinancialDetails(employeeId.toString());
    }
  }

  void shiftFinancialDay(int deltaDays) {
    setFinancialDate(
      selectedFinancialDate.value.add(Duration(days: deltaDays)),
    );
  }

  Future<void> loadEmployeeAdvancesFor(int employeeId, String monthKey) async {
    isAdvancesLoading(true);
    advancesError.value = '';
    try {
      employeeAdvances.value = await employeeAdvancesUsecase.call(
        employeeId: employeeId,
        month: monthKey,
      );
    } catch (e) {
      employeeAdvances.value = null;
      advancesError.value = e.toString();
    } finally {
      isAdvancesLoading(false);
    }
  }

  // Get Employee Details
  Future<void> getEmployeeDetails(String employeeId) async {
    employeeId == employeeService.employeeDetails.value?.id.toString()
        ? isDialogLoading(false)
        : isDialogLoading(true);
    final result = await employeeDetailsUsecase.call(employeeId: employeeId);
    employeeService.employeeDetails.value = result;
    isDialogLoading(false);
  }

  // Get Overtime And Loan
  void getOvertimeAndLoan() async {
    final showLoader = employeeService.overtimeList.isEmpty &&
        employeeService.loanList.isEmpty;
    if (showLoader) isLoading(true);
    try {
      final attendanceFuture = loadAttendanceOvertimeRequests();
      final overtimeResult =
          await overtimeAndLoanUsecase.call(isOvertime: true);
      employeeService.overtimeList.assignAll(overtimeResult);
      filteredOvertimeList.assignAll(employeeService.overtimeList);
      final loanResult = await overtimeAndLoanUsecase.call(isOvertime: false);
      employeeService.loanList.assignAll(loanResult);
      filteredLoanList.assignAll(employeeService.loanList);
      await attendanceFuture;
    } on Failure catch (e) {
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoader) isLoading(false);
    }
  }

  Future<void> loadAttendanceOvertimeRequests() async {
    try {
      final rows =
          await Get.find<EmployeeDatasource>().getAttendanceOvertimeRequests();
      attendanceOvertimeRequests.assignAll(rows);
    } catch (_) {
      attendanceOvertimeRequests.clear();
    }
  }

  Future<void> approveAttendanceOvertimeRequest(
    int requestId, {
    int? approvedMinutes,
  }) async {
    try {
      final raw =
          await Get.find<EmployeeDatasource>().reviewAttendanceOvertimeRequest(
        requestId: requestId,
        approve: true,
        approvedMinutes: approvedMinutes,
      );
      if (raw['status']?.toString() != 'success') {
        Get.snackbar('error'.tr, raw['message']?.toString() ?? 'error'.tr);
        return;
      }
      Get.snackbar('success'.tr, raw['message']?.toString() ?? 'success'.tr);
      await loadAttendanceOvertimeRequests();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> rejectAttendanceOvertimeRequest(int requestId) async {
    try {
      final raw =
          await Get.find<EmployeeDatasource>().reviewAttendanceOvertimeRequest(
        requestId: requestId,
        approve: false,
      );
      if (raw['status']?.toString() != 'success') {
        Get.snackbar('error'.tr, raw['message']?.toString() ?? 'error'.tr);
        return;
      }
      Get.snackbar('success'.tr, raw['message']?.toString() ?? 'success'.tr);
      await loadAttendanceOvertimeRequests();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  // Get Logs
  void getLogs() async {
    isLoading(true);
    employeeService.logsMap.clear();

    final result = await getLogsUsecase.call();
    for (var task in result) {
      String dateKey =
          "${task.createdAt.year}-${task.createdAt.month}-${task.createdAt.day}";
      if (employeeService.logsMap.containsKey(dateKey)) {
        if (!employeeService.logsMap[dateKey]!.any((t) => t.id == task.id)) {
          employeeService.logsMap[dateKey]!.add(task);
        }
      } else {
        employeeService.logsMap[dateKey] = [task];
      }
    }
    isLoading(false);
    update();
  }

  // generate QR code
  void generateQrCode(bool isrefresh) async {
    isDialogLoading(true);
    if (isrefresh || employeeService.qrGeneration.value == null) {
      final result = await qrGenerationUsecase.call();
      employeeService.qrGeneration.value = result;
    }
    isDialogLoading(false);
  }

  Future<void> loadQrHistory({int page = 1, int perPage = 20}) async {
    try {
      isQrHistoryLoading(true);
      final result = await qrHistoryUsecase.call(page: page, perPage: perPage);
      employeeService.qrHistory.assignAll(result.items);
    } on Failure catch (e) {
      employeeService.qrHistory.clear();
      Get.snackbar(
        'error'.tr,
        e.errMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      employeeService.qrHistory.clear();
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isQrHistoryLoading(false);
    }
  }

  final RxList<EmployeeEntity> filteredEmployees = <EmployeeEntity>[].obs;
  final RxList<EmployeeEntity> filteredSuspendedEmployees =
      <EmployeeEntity>[].obs;
  final RxList<AdminUserModel> filteredAdmins = <AdminUserModel>[].obs;
  final RxList<WorkingTimesEntity> filteredWorkingTimes =
      <WorkingTimesEntity>[].obs;
  final RxList<FinancialDuesModel> filteredFinancialDues =
      <FinancialDuesModel>[].obs;
  final RxList<OvertimeAndLoanModel> filteredOvertimeList =
      <OvertimeAndLoanModel>[].obs;
  final RxList<Map<String, dynamic>> attendanceOvertimeRequests =
      <Map<String, dynamic>>[].obs;
  final RxList<OvertimeAndLoanModel> filteredLoanList =
      <OvertimeAndLoanModel>[].obs;

  void filterLists() {
    if (employeeNameController.text.isEmpty) {
      // رجع القوائم الأصلية
      filteredEmployees.assignAll(employeeService.employeeList);
      filteredSuspendedEmployees.assignAll(
        employeeService.suspendedEmployeeList,
      );
      filteredWorkingTimes.assignAll(employeeService.workingTimesList);
      filteredFinancialDues.assignAll(employeeService.financialDuesList);
      filteredOvertimeList.assignAll(employeeService.overtimeList);
      filteredLoanList.assignAll(employeeService.loanList);
      filteredAdmins.assignAll(employeeService.adminList);
    } else {
      final lowerQuery = employeeNameController.text..toLowerCase();

      filteredEmployees.assignAll(
        employeeService.employeeList
            .where((e) => e.employeeName.toLowerCase().contains(lowerQuery)),
      );
      filteredSuspendedEmployees.assignAll(
        employeeService.suspendedEmployeeList
            .where((e) => e.employeeName.toLowerCase().contains(lowerQuery)),
      );

      filteredAdmins.assignAll(
        employeeService.adminList.where(
          (a) =>
              a.name.toLowerCase().contains(lowerQuery) ||
              a.email.toLowerCase().contains(lowerQuery),
        ),
      );

      filteredWorkingTimes.assignAll(
        employeeService.workingTimesList
            .where((w) => w.employeeName.toLowerCase().contains(lowerQuery)),
      );

      filteredFinancialDues.assignAll(
        employeeService.financialDuesList
            .where((f) => f.employeeName.toLowerCase().contains(lowerQuery)),
      );
      filteredOvertimeList.assignAll(
        employeeService.overtimeList
            .where((o) => o.employeeName.toLowerCase().contains(lowerQuery)),
      );
      filteredLoanList.assignAll(
        employeeService.loanList
            .where((l) => l.employeeName.toLowerCase().contains(lowerQuery)),
      );
    }
    Get.back();
  }

  Future<void> pullToRefresh() async {
    isLoading(true);
    update();
    syncVisibleTabs();
    if (canViewEmployees) {
      final result = await getAllEmployeeUsecase.call();
      employeeService.employeeList.assignAll(result);
      filteredEmployees.assignAll(employeeService.employeeList);
      final suspended = await getSuspendedEmployeesUsecase.call();
      employeeService.suspendedEmployeeList.assignAll(suspended);
      filteredSuspendedEmployees
          .assignAll(employeeService.suspendedEmployeeList);
    }
    if (canViewEmployeesAttendance) {
      getWorkingTimes();
    }
    if (canViewEmployeesFinancial) {
      getFinancialDues();
    }
    if (canManageEmployeesOrders) {
      getOvertimeAndLoan();
    }
    if (canViewEmployeesLogs) {
      getLogs();
    }
    if (userType == 'admin') {
      await getAdminUsers();
    }
    isLoading(false);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    syncVisibleTabs();
    _resolveCurrentEmployeeRecordId();
    if (canViewEmployees) {
      getEmployee();
      getSuspendedEmployees();
      filteredEmployees.assignAll(employeeService.employeeList);
      filteredSuspendedEmployees
          .assignAll(employeeService.suspendedEmployeeList);
    }
    if (canViewEmployeesAttendance) {
      getWorkingTimes();
    }
    if (canViewEmployeesFinancial) {
      getFinancialDues();
    }
    if (canManageEmployeesOrders) {
      getOvertimeAndLoan();
    }
    if (canViewEmployeesLogs) {
      getLogs();
    }
    if (userType == 'admin') {
      getAdminUsers();
    }
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

  final GlobalKey qrKey = GlobalKey();
  Future<void> downloadQr() async {
    try {
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 4.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "employee_qr_${DateTime.now().millisecondsSinceEpoch}",
      );

      Get.snackbar("نجاح ✅", "تم حفظ الكود في المعرض");
    } catch (e) {
      Get.snackbar("خطأ ❌", "فشل حفظ الكود");
    }
  }

  // download report
  Future<void> downloadReport({
    required String type,
    required BuildContext context,
    String? employeeId,
    String? employeeName,
  }) async {
    try {
      Get.back();
      Get.snackbar(
        "info".tr,
        "جار تحميل الملف. سيتم اعلامك عند الانتهاء".tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2500),
      );
      final response = await getReportByType.call(
        type: type,
        employeeId: employeeId,
        fromDate: DateTime(
          dateTimeList?.first.year ?? DateTime.now().year,
          dateTimeList?.first.month ?? DateTime.now().month,
          dateTimeList?.first.day ?? DateTime.now().day,
        ),
        toDate: DateTime(
          dateTimeList?.last.year ?? DateTime.now().year,
          dateTimeList?.last.month ?? DateTime.now().month,
          dateTimeList?.last.day ?? DateTime.now().day,
        ),
      );

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
            "${directory.path}/${p.basename(type)}_تقرير_$employeeName${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.pdf";
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
      Get.snackbar("error".tr, e.toString());
    }
  }

  @override
  void onClose() {
    employeeNameController.dispose();
    employeePasswordController.dispose();
    employeePasswordConfirmationController.dispose();
    paySalaryController.dispose();
    rejectionReasonController.dispose();
    addRegularWorkingHoursController.dispose();
    addWorkHoursController.dispose();
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    super.onClose();
  }
}
