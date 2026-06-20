import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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
  final tabs = [
    'employeeList',
    'workHours',
    'entitlements',
    'loans',
    'overtime',
    'admins',
  ].obs;

  final RxBool isLoading = false.obs;

  List<DateTime>? dateTimeList;
  final Rx<DateTime> selectedFinancialMonth = DateTime.now().obs;
  final Rx<DateTime> selectedFinancialDate = DateTime.now().obs;

  void changeTab(int index) {
    currentTab.value = index;
    if (index == 5) {
      getAdminUsers();
    }
  }

  final TextEditingController paySalaryController = TextEditingController();

  final TextEditingController overtimeValueController = TextEditingController();

  final TextEditingController loanValueController = TextEditingController();

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
      'title': 'reward',
      'icon': AssetsManager.moneyIcon,
      'route': AppRoutes.ADDPENALTYANDREWARDSCREEN,
    },
    {
      'title': 'penalty',
      'icon': AssetsManager.invoiceIcon,
      'route': AppRoutes.ADDPENALTYANDREWARDSCREEN,
    },
    {
      'title': 'newAdmin',
      'icon': AssetsManager.userIcon,
      'route': AppRoutes.ADDEDITADMINSCREEN,
    },
  ];

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
    final result =
        await rejectOrderUsecase.call(employeeOrderId: employeeOrderId);
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['message'],
        );
      },
      (success) {
        Get.back();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            getOvertimeAndLoan();
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

  // approve Employee Order
  void approveEmployeeOrder({
    required BuildContext context,
    required String employeeOrderId,
  }) async {
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
        extraWorkHoursController.clear();
        loanValue.value = false;
        rejectOrder.value = false;
        extraWorkHours.value = false;
        overtimeValue.value = false;
        Get.back();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            getOvertimeAndLoan();
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
  void getEmployee() async {
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
        Get.snackbar('success'.tr, success, snackPosition: SnackPosition.BOTTOM);
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
        Get.snackbar('success'.tr, success, snackPosition: SnackPosition.BOTTOM);
        await getAdminUsers();
      },
    );
    isLoading(false);
    update();
  }

  final RxBool isDeletingEmployee = false.obs;

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
            employeeService.workingTimesList.removeWhere((e) => e.id == id);
            employeeService.financialDuesList.removeWhere((e) => e.id == id);
            filteredEmployees.removeWhere((e) => e.id == id);
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

  Future<void> impersonateEmployee(
    BuildContext context,
    EmployeeEntity employee,
  ) async {
    impersonatingEmployeeId.value = employee.id;
    try {
      final raw = await Get.find<EmployeeDatasource>()
          .impersonateEmployee(employee.id);
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
    selectedFinancialDate.value =
        DateTime(date.year, date.month, date.day);
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
  void getEmployeeDetails(String employeeId) async {
    employeeId == employeeService.employeeDetails.value?.id.toString()
        ? isDialogLoading(false)
        : isDialogLoading(true);
    final result = await employeeDetailsUsecase.call(employeeId: employeeId);
    employeeService.employeeDetails.value = result;
    isDialogLoading(false);
  }

  // Get Overtime And Loan
  void getOvertimeAndLoan() async {
    final showLoader =
        employeeService.overtimeList.isEmpty && employeeService.loanList.isEmpty;
    if (showLoader) isLoading(true);
    try {
      final attendanceFuture = loadAttendanceOvertimeRequests();
      final overtimeResult = await overtimeAndLoanUsecase.call(isOvertime: true);
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
      final raw = await Get.find<EmployeeDatasource>().reviewAttendanceOvertimeRequest(
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
      final raw = await Get.find<EmployeeDatasource>().reviewAttendanceOvertimeRequest(
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
    final result = await getAllEmployeeUsecase.call();
    employeeService.employeeList.assignAll(result);
    filteredEmployees.assignAll(employeeService.employeeList);
    getWorkingTimes();
    getFinancialDues();
    getOvertimeAndLoan();
    getLogs();
    await getAdminUsers();
    isLoading(false);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getEmployee();
    filteredEmployees.assignAll(employeeService.employeeList);
    getWorkingTimes();
    getFinancialDues();
    getOvertimeAndLoan();
    getLogs();
    getAdminUsers();
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
    paySalaryController.dispose();
    addRegularWorkingHoursController.dispose();
    addWorkHoursController.dispose();
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    super.onClose();
  }
}
