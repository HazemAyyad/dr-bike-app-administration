import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/financial_details_model.dart';
import '../../data/models/financial_dues_model.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/working_times_entity.dart';
import '../../domain/usecases/employee_details_usecase.dart';
import '../../domain/usecases/financial_details_usecase.dart';
import '../../domain/usecases/financial_dues.usecase.dart';
import '../../domain/usecases/get_all_employee.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';
import '../../domain/usecases/qr_generation_usecase.dart';
import '../../domain/usecases/working_times_usecase.dart';
import 'employee_service.dart';

class EmployeeSectionController extends GetxController
    with GetTickerProviderStateMixin {
  PaySalaryToEmployeeUsecase paySalaryEmployee;
  GetAllEmployeeUsecase getAllEmployeeUsecase;
  WorkingTimesUsecase workingTimesUsecase;
  FinancialDuesUsecase financialDuesUsecase;
  FinancialDetailsUsecase financialDetailsUsecase;
  EmployeeDetailsUsecase employeeDetailsUsecase;
  QrGenerationUsecase qrGenerationUsecase;

  EmployeeService employeeService;

  EmployeeSectionController({
    required this.paySalaryEmployee,
    required this.getAllEmployeeUsecase,
    required this.workingTimesUsecase,
    required this.financialDuesUsecase,
    required this.financialDetailsUsecase,
    required this.employeeDetailsUsecase,
    required this.qrGenerationUsecase,
    required this.employeeService,
  });

  final GlobalKey formKey = GlobalKey<FormState>();

  // final TextEditingController fromDateController = TextEditingController();
  // final TextEditingController toDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();

  RxInt currentTab = 0.obs;
  final tabs = [
    'employeeList', 'workHours', 'entitlements',
    // 'loans', 'overtime'
  ].obs;

  final RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  final List<String> daysList = [
    "saturday".tr,
    "sunday".tr,
    "monday".tr,
    "tuesday".tr,
    "wednesday".tr,
    "thursday".tr,
    "friday".tr,
  ];

  final TextEditingController paySalaryController = TextEditingController();

  RxBool acceptOrder = false.obs;

  RxBool rejectOrder = false.obs;

  RxBool addRegularWorkingHours = false.obs;
  final TextEditingController addRegularWorkingHoursController =
      TextEditingController();

  RxBool addWorkHours = false.obs;
  final TextEditingController addWorkHoursController = TextEditingController();

  void setOnlyOneTrue(String key) {
    acceptOrder.value = key == 'acceptOrder';
    rejectOrder.value = key == 'rejectOrder';
    addRegularWorkingHours.value = key == 'addRegularWorkingHours';
    addWorkHours.value = key == 'addWorkHours';
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
      'icon': AssetsManger.userIcon,
      'route': AppRoutes.ADDNEWEMPLOYEESCREEN
    },
    {
      'title': 'penalty',
      'icon': AssetsManger.invoiceIcon,
      'route': AppRoutes.ADDPENALTYANDREWARDSCREEN,
    },
    {
      'title': 'reward',
      'icon': AssetsManger.moneyIcon,
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
          Get.back();
          Future.delayed(
            Duration(milliseconds: 1500),
            () {
              Get.back();
            },
          );
          paySalaryController.clear();
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

  //Get Employee
  void getEmployee() async {
    employeeService.employeeList.isEmpty ? isLoading(true) : isLoading(false);
    final result = await getAllEmployeeUsecase.call();
    employeeService.employeeList.assignAll(result);
    isLoading(false);
  }

  //Get Working Times
  void getWorkingTimes() async {
    employeeService.workingTimesList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    final result = await workingTimesUsecase.call();
    employeeService.workingTimesList.assignAll(result);
    isLoading(false);
  }

  //Get Financial Dues
  void getFinancialDues() async {
    employeeService.financialDuesList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    final result = await financialDuesUsecase.call();
    employeeService.financialDuesList.assignAll(result);
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

  void filterLists() {
    if (employeeNameController.text.isEmpty) {
      // رجع القوائم الأصلية
      filteredEmployees.assignAll(employeeService.employeeList);
      filteredWorkingTimes.assignAll(employeeService.workingTimesList);
      filteredFinancialDues.assignAll(employeeService.financialDuesList);
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
    }
    Get.back();
  }

  @override
  void onInit() {
    super.onInit();
    getEmployee();
    getWorkingTimes();
    getFinancialDues();
    animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
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
    filteredEmployees.assignAll(employeeService.employeeList);
    filteredWorkingTimes.assignAll(employeeService.workingTimesList);
    filteredFinancialDues.assignAll(employeeService.financialDuesList);
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

  @override
  void dispose() {
    // fromDateController.dispose();
    // toDateController.dispose();
    employeeNameController.dispose();
    paySalaryController.dispose();
    addRegularWorkingHoursController.dispose();
    addWorkHoursController.dispose();
    animController.dispose();
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    super.dispose();
  }
}
