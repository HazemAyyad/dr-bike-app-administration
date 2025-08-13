import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/user_data.dart';
import '../../../../../routes/app_routes.dart';
import '../../domain/usecases/pay_salary_to_employee_usecase.dart';

class EmployeeSectionController extends GetxController
    with GetTickerProviderStateMixin {
  PaySalaryToEmployeeUsecase paySalaryEmployee;

  EmployeeSectionController({required this.paySalaryEmployee});

  final GlobalKey formKey = GlobalKey<FormState>();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> employeeList = <Map<String, dynamic>>[].obs;
  final tabs =
      ['employeeList', 'workHours', 'entitlements', 'loans', 'overtime'].obs;

  final RxBool isLoading = false.obs;

  void changeTab(int index) {
    currentTab.value = index;
    fetchOrders();
  }

  void fetchOrders() {
    // Simulate fetching orders based on the current tab
    employeeList.clear();
    if (currentTab.value == 0) {
      employeeList.addAll([
        {
          'employeeName': 'شادي  أحمد أحمد أحمد أحمد أحمد أحمد أحمد أحمدأحمد',
          'image': AssetsManger.noImageNet,
          'hourlyRate': '1000',
          'points': '70',
          'warkDay': 'الاثنين',
        },
        {
          'employeeName': 'شادي أحمد أحمد',
          'image': AssetsManger.noImageNet,
          'hourlyRate': '100',
          'points': '70',
          'warkDay': 'الاثنين',
        },
        {
          'employeeName': 'شادي أحمد',
          'image': AssetsManger.noImageNet,
          'hourlyRate': '100',
          'points': '70',
          'warkDay': 'الاثنين',
        },
        {
          'employeeName': 'شادي أحمد',
          'image': AssetsManger.noImageNet,
          'hourlyRate': '100',
          'points': '70',
          'warkDay': 'الاثنين',
        },
      ]);
    } else if (currentTab.value == 1) {
      employeeList.addAll(
        [
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'workStartTime': '8 ص',
            'workEndTime': '4 م',
            'workHoursOfDay': '8',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'workStartTime': '8 ص',
            'workEndTime': '4 م',
            'workHoursOfDay': '8',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'workStartTime': '8 ص',
            'workEndTime': '4 م',
            'workHoursOfDay': '8',
            'warkDay': 'الاحد',
          },
        ],
      );
    } else if (currentTab.value == 2) {
      employeeList.addAll(
        [
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'salary': '1700',
            'debts': '200',
            'points': '30',
            'hourlyRate': '50',
            'workHoursOfDay': '7',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'salary': '3000',
            'debts': '250',
            'points': '70',
            'hourlyRate': '50',
            'workHoursOfDay': '8',
            'warkDay': 'الاثنين',
          },
        ],
      );
    } else if (currentTab.value == 3) {
      employeeList.addAll(
        [
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'debts': '750',
            'stuts': 'طلب مقبول',
            'date': '20/7/2025',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'debts': '250',
            'stuts': 'طلب مرفوض',
            'date': '20/7/2025',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'debts': '250',
            'stuts': 'طلب تحت المتابعة',
            'date': '20/7/2025',
            'warkDay': 'الاثنين',
          },
        ],
      );
    } else if (currentTab.value == 4) {
      employeeList.addAll(
        [
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'overtime': '2',
            'debts': '250',
            'date': '20/7/2025',
            'stuts': 'طلب مقبول',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'overtime': '3',
            'debts': '250',
            'date': '20/7/2025',
            'stuts': 'طلب مرفوض',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'overtime': '15',
            'debts': '250',
            'date': '20/7/2025',
            'stuts': 'طلب تحت المتابعة',
            'warkDay': 'الاثنين',
          },
        ],
      );
    }
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
    // {
    //   'title': 'barcode',
    //   'icon': AssetsManger.qrcode,
    //   'route': AppRoutes.NEWCASHPROFITSCREEN,
    // },
  ];
  @override
  void onInit() {
    super.onInit();
    fetchOrders();

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
  }

  final RxBool isPaymentLoading = false.obs;
  //pay Salary To Employee
  void paySalaryToEmployee(BuildContext context, String employeeId) async {
    if ((formKey.currentState as FormState).validate()) {
      isPaymentLoading(true);
      final token = await UserData.getUserToken();
      final result = await paySalaryEmployee.call(
        token: token,
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

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
    paySalaryController.dispose();
    addRegularWorkingHoursController.dispose();
    addWorkHoursController.dispose();
    animController.dispose();
    super.dispose();
  }
}
