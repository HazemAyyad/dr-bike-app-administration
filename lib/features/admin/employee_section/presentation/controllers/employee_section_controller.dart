import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class EmployeeSectionController extends GetxController {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  String employeeJobTitle = '';
  final TextEditingController overTimeRateController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> employeeList = <Map<String, dynamic>>[].obs;
  final tabs =
      ['employeeList', 'workHours', 'earnings', 'loans', 'overtime'].obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

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
            'salary': '3000',
            'debts': '1500',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'salary': '3000',
            'debts': '250',
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
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'debts': '250',
            'stuts': 'طلب مرفوض',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'debts': '250',
            'stuts': 'طلب تحت المتابعة',
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
            'stuts': 'طلب مقبول',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'overtime': '3',
            'stuts': 'طلب مرفوض',
            'warkDay': 'الاثنين',
          },
          {
            'employeeName': 'شادي أحمد',
            'image': AssetsManger.noImageNet,
            'overtime': '15',
            'stuts': 'طلب تحت المتابعة',
            'warkDay': 'الاثنين',
          },
        ],
      );
    }
  }

  List<String> jobTitles = ['jobTitle1', 'jobTitle2', 'jobTitle3'];

  void addNewEmployee() {
    Get.snackbar(
      'success'.tr,
      'employeeAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    overTimeRateController.dispose();
    employeeJobTitle = '';
    hourlyRateController.dispose();
    employeeNameController.dispose();
    super.dispose();
  }
}
