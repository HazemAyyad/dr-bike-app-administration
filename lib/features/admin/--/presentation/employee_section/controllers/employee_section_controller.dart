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
  RxList<Map<String, dynamic>> list = <Map<String, dynamic>>[].obs;
  final tabs = ['employeeList', 'workHours', 'earnings'].obs;

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
    list.clear();
    if (currentTab.value == 0) {
      list.addAll([
        {
          'employeeName': 'شادي أحمد',
          'hourlyRate': '100',
          'points': '70',
        },
        {
          'employeeName': 'شادي  أحمد أحمد أحمد أحمد أحمد أحمد',
          'hourlyRate': '100',
          'points': '70',
        },
        {
          'employeeName': 'شادي أحمد',
          'hourlyRate': '100',
          'points': '70',
        },
        {
          'employeeName': 'شادي أحمد',
          'hourlyRate': '100',
          'points': '70',
        },
      ]);
    } else if (currentTab.value == 1) {
      list.addAll(
        [
          {
            'employeeName': 'شادي أحمد',
            'workStartTime': '8 صباحا',
            'workEndTime': '4 مساءا',
            'workHoursOfDay': '8 ساعات',
          },
          {
            'employeeName': 'شادي أحمد',
            'workStartTime': '8 صباحا',
            'workEndTime': '4 مساءا',
            'workHoursOfDay': '8 ساعات',
          },
        ],
      );
    } else if (currentTab.value == 2) {
      list.addAll(
        [
          {
            'employeeName': 'شادي أحمد',
            'salaryHours': '3000',
            'debts': '250',
          },
          {
            'employeeName': 'شادي أحمد',
            'salaryHours': '3000',
            'debts': '250',
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
