import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:open_filex/open_filex.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import 'package:doctorbike/core/utils/assets_manger.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../counters/domain/usecases/get_report_by_type_usecase.dart';
import '../../data/models/financial_details_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../data/models/overtime_and_loan_model.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/working_times_entity.dart';
import '../../domain/usecases/approve_employee_order_usecase.dart';
import '../../domain/usecases/cancel_log_usecase.dart';
import '../../domain/usecases/employee_details_usecase.dart';
import '../../domain/usecases/financial_details_usecase.dart';
import '../../domain/usecases/financial_dues.usecase.dart';
import '../../domain/usecases/get_all_employee.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../../domain/usecases/overtime_and_loan_usecase.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';
import '../../domain/usecases/qr_generation_usecase.dart';
import '../../domain/usecases/reject_order_usecase.dart';
import '../../domain/usecases/working_times_usecase.dart';
import 'employee_service.dart';

class EmployeeSectionController extends GetxController
    with GetTickerProviderStateMixin {
  final PaySalaryToEmployeeUsecase paySalaryEmployee;
  final GetAllEmployeeUsecase getAllEmployeeUsecase;
  final WorkingTimesUsecase workingTimesUsecase;
  final FinancialDuesUsecase financialDuesUsecase;
  final FinancialDetailsUsecase financialDetailsUsecase;
  final EmployeeDetailsUsecase employeeDetailsUsecase;
  final QrGenerationUsecase qrGenerationUsecase;
  final OvertimeAndLoanUsecase overtimeAndLoanUsecase;
  final RejectOrderUsecase rejectOrderUsecase;
  final ApproveEmployeeOrderUsecase approveEmployeeOrderUsecase;
  final GetLogsUsecase getLogsUsecase;
  final CancelLogUsecase cancelLogUsecase;
  final EmployeeService employeeService;
  final GetReportByTypeUsecase getReportByType;

  EmployeeSectionController({
    required this.paySalaryEmployee,
    required this.getAllEmployeeUsecase,
    required this.workingTimesUsecase,
    required this.financialDuesUsecase,
    required this.financialDetailsUsecase,
    required this.employeeDetailsUsecase,
    required this.qrGenerationUsecase,
    required this.overtimeAndLoanUsecase,
    required this.rejectOrderUsecase,
    required this.approveEmployeeOrderUsecase,
    required this.getLogsUsecase,
    required this.cancelLogUsecase,
    required this.employeeService,
    required this.getReportByType,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // final TextEditingController fromDateController = TextEditingController();
  // final TextEditingController toDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();

  RxInt currentTab = 0.obs;
  final tabs =
      ['employeeList', 'workHours', 'entitlements', 'loans', 'overtime'].obs;

  final RxBool isLoading = false.obs;

  List<DateTime>? dateTimeList;

  void changeTab(int index) {
    currentTab.value = index;
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
    employeeService.employeeList.isEmpty ? isLoading(true) : isLoading(false);
    final result = await getAllEmployeeUsecase.call();
    employeeService.employeeList.assignAll(result);
    filteredEmployees.assignAll(employeeService.employeeList);
    isLoading(false);
  }

  //Get Working Times
  void getWorkingTimes() async {
    employeeService.workingTimesList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    final result = await workingTimesUsecase.call();
    employeeService.workingTimesList.assignAll(result);
    filteredWorkingTimes.assignAll(employeeService.workingTimesList);
    isLoading(false);
  }

  //Get Financial Dues
  void getFinancialDues() async {
    employeeService.financialDuesList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    final result = await financialDuesUsecase.call();
    employeeService.financialDuesList.assignAll(result);
    filteredFinancialDues.assignAll(employeeService.financialDuesList);
    isLoading(false);
  }

  RxBool isDialogLoading = false.obs;

  // Get Financial Details
  Rxn<FinancialDetailsModel> financialDetailsList =
      Rxn<FinancialDetailsModel>();

  void getFinancialDetails(String employeeId) async {
    employeeId == financialDetailsList.value?.employeeId.toString()
        ? isDialogLoading(false)
        : isDialogLoading(true);
    final result = await financialDetailsUsecase.call(employeeId: employeeId);
    financialDetailsList.value = result;
    isDialogLoading(false);
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
    employeeService.financialDuesList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    final overtimeResult = await overtimeAndLoanUsecase.call(isOvertime: true);
    employeeService.overtimeList.assignAll(overtimeResult);
    filteredOvertimeList.assignAll(employeeService.overtimeList);
    final loanResult = await overtimeAndLoanUsecase.call(isOvertime: false);
    employeeService.loanList.assignAll(loanResult);
    filteredLoanList.assignAll(employeeService.loanList);
    isLoading(false);
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
    if (employeeService.qrGeneration.value == null) {
      final result = await qrGenerationUsecase.call();
      employeeService.qrGeneration.value = result;
    }
    if (isrefresh) {
      final result = await qrGenerationUsecase.call();
      employeeService.qrGeneration.value = result;
    }
    isDialogLoading(false);
  }

  final RxList<EmployeeEntity> filteredEmployees = <EmployeeEntity>[].obs;
  final RxList<WorkingTimesEntity> filteredWorkingTimes =
      <WorkingTimesEntity>[].obs;
  final RxList<FinancialDuesModel> filteredFinancialDues =
      <FinancialDuesModel>[].obs;
  final RxList<OvertimeAndLoanModel> filteredOvertimeList =
      <OvertimeAndLoanModel>[].obs;
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
    } else {
      final lowerQuery = employeeNameController.text..toLowerCase();

      filteredEmployees.assignAll(
        employeeService.employeeList
            .where((e) => e.employeeName.toLowerCase().contains(lowerQuery)),
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

  @override
  void onInit() {
    super.onInit();
    getEmployee();
    filteredEmployees.assignAll(employeeService.employeeList);
    getWorkingTimes();
    getFinancialDues();
    getOvertimeAndLoan();
    getLogs();
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
        final directory =
            Directory("/storage/emulated/0/Download/Doctor Bike/PDF");
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
