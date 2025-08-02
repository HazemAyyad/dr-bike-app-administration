import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmployeeTasksController extends GetxController {
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final employeeNameController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;

  final tabs = ['employeeActiveTasks', 'employeeCompletedTasks', 'archive'].obs;

  RxBool isLoading = false.obs;
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
    orders.clear();
    if (currentTab.value == 0) {
      orders.addAll([
        {
          'taskName': 'ترتيب  رفوف   رفوف رفوف رفوف رفوف رفوف رفوف المحل',
          'employeeName': 'شادي أحمد',
          'startDate': '2025/02/30',
          'endDate': '2025/02/26',
          'month': 'فبراير 2025',
          'time': '3',
          'image': AssetsManger.noImageNet,
        },
        {
          'taskName': 'ترتيب رفوف المحل',
          'employeeName': 'شادي أحمد',
          'startDate': '2025/02/20',
          'endDate': '2025/02/27',
          'month': 'يناير 2025',
          'time': '1',
          'image': AssetsManger.noImageNet,
        },
        {
          'taskName': 'ترتيب  رفوف   رفوف رفوف رفوف رفوف رفوف رفوف المحل',
          'employeeName': 'شادي أحمد',
          'startDate': '2025/02/25',
          'endDate': '2025/02/27',
          'month': 'فبراير 2025',
          'time': '-1',
          'image': AssetsManger.noImageNet,
        },
        {
          'taskName': 'ترتيب رفوف المحل',
          'employeeName': 'شادي أحمد',
          'startDate': '2025/02/25',
          'endDate': '2025/02/27',
          'month': 'فبراير 2025',
          'time': '3',
          'image': AssetsManger.noImageNet,
        },
      ]);
    } else if (currentTab.value == 1) {
      orders.addAll(
        [
          {
            'taskName': 'ترتيب رفوف المحل',
            'employeeName': 'شادي أحمد',
            'startDate': '2025/02/25',
            'endDate': '2025/02/27',
            'month': 'فبراير 2025',
            'time': '3',
            'image': AssetsManger.noImageNet,
          },
          {
            'taskName': 'ترتيب رفوف المحل',
            'employeeName': 'شادي أحمد',
            'startDate': '2025/02/25',
            'endDate': '2025/02/27',
            'month': 'فبراير 2025',
            'time': '3',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    } else if (currentTab.value == 2) {
      orders.addAll(
        [
          {
            'taskName': 'ترتيب رفوف المحل',
            'employeeName': 'شادي أحمد',
            'startDate': '2025/02/25',
            'endDate': '2025/02/27',
            'month': 'فبراير 2025',
            'time': '3',
            'image': AssetsManger.noImageNet,
          },
          {
            'taskName': 'ترتيب رفوف المحل',
            'employeeName': 'شادي أحمد',
            'startDate': '2025/02/25',
            'endDate': '2025/02/27',
            'month': 'فبراير 2025',
            'time': '11',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    employeeNameController.dispose();
  }
}
