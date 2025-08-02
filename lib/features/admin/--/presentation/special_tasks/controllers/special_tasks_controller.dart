import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SpecialTasksController extends GetxController {
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> list = <Map<String, dynamic>>[].obs;

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
    list.clear();
    if (currentTab.value == 0) {
      list.addAll([
        {
          'taskName': 'ترتيب  رفوف   رفوف رفوف رفوف رفوف رفوف رفوف المحل',
          'startDate': '2025/02/25',
          'endDate': '2025/02/27',
        },
        {
          'taskName': 'ترتيب رفوف المحل',
          'startDate': '2025/02/25',
          'endDate': '2025/02/27',
        },
      ]);
    } else if (currentTab.value == 1) {
      list.addAll([
        {
          'taskName': 'ترتيب رفوف المحل',
          'startDate': '2025/02/25',
          'endDate': '2025/02/27',
        },
        {
          'taskName': 'ترتيب رفوف المحل',
          'startDate': '2025/02/25',
          'endDate': '2025/02/27',
        },
      ]);
    }
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }
}
