import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CurrentFollowUpController extends GetxController {
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  final customerNameController = TextEditingController();
  final customerphoneNumberController = TextEditingController();
  final customerNotesController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> tasks = <Map<String, dynamic>>[].obs;
  final tabs = ['employeeActiveTasks', 'employeeCompletedTasks'].obs;

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
    tasks.clear();
    if (currentTab.value == 0) {
      tasks.addAll([
        {
          'customerName': 'ماجد محمد محمود احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
      ]);
    } else if (currentTab.value == 1) {
      tasks.addAll(
        [
          {
            'customerName': 'ماجد احمد',
            'productDetails': 'موتور m1',
            'startDate': '01/03/2025',
          },
          {
            'customerName': 'ماجد احمد',
            'productDetails': 'موتور m1',
            'startDate': '01/03/2025',
          },
        ],
      );
    }
  }

  String selectedCustomerName = '';
  List<String> customerNameList = [
    'محمد رفعت',
    'محمد احمد',
    'محمود محمد',
  ];
  void addNewFollowUp() {
    Get.snackbar(
      'success'.tr,
      'followUpAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String selectedCustomerType = '';
  List<String> customerTypeList = ['جملة', 'قطاعي'];

  void addNewCustomer() {
    Get.snackbar(
      'success'.tr,
      'customerAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    customerNameController.dispose();
    customerphoneNumberController.dispose();
    customerNotesController.dispose();
    selectedCustomerName = '';
    super.onClose();
  }
}
