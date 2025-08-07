import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SpecialTasksController extends GetxController {
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> list = <Map<String, dynamic>>[].obs;

  final tabs = ['weeklyTasks', 'noDateTasks', 'archive'].obs;

  final isLoading = false.obs;
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
          'id': '1',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'السبت 2025/02/25',
          'endDate': '2025/02/27',
        },
        {
          'id': '2',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'السبت 2025/02/25',
          'endDate': '2025/02/27',
        },
        {
          'id': '3',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'الاحد 2025/02/26',
          'endDate': '2025/02/27',
        },
      ]);
    } else if (currentTab.value == 1) {
      list.addAll([
        {
          'id': '4',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'السبت 2025/02/25',
          'endDate': '2025/02/27',
        },
        {
          'id': '5',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'الاحد 2025/02/26',
          'endDate': '2025/02/27',
        },
      ]);
    } else if (currentTab.value == 2) {
      list.addAll([
        {
          'id': '4',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'الاحد 2025/02/26',
          'endDate': '2025/02/27',
        },
        {
          'id': '5',
          'taskName': 'ترتيب رفوف المحل',
          'startDate': 'الاحد 2025/02/26',
          'endDate': '2025/02/27',
        },
      ]);
    }
  }

  final RxMap<String, RxBool> checkedMap = <String, RxBool>{}.obs;

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }
}
