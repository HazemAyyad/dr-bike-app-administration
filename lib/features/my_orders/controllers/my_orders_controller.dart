import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyOrdersController extends GetxController {
  var currentTab = 0.obs;
  List<String> tabs = ['completedOrders', 'activeOrders', 'cancelledOrders'];

  var orders = <Map<String, dynamic>>[].obs;

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
    if (currentTab.value == 2) {
      orders.addAll([
        {
          'products': 'منتج 1, منتج 2',
          'date': '2025-04-15',
          'status': 'cancelled',
          'statusColor': Colors.red,
          'textColor': AppColors.customRed,
        },
        {
          'products': 'منتج 3',
          'date': '2025-04-14',
          'status': 'cancelled',
          'statusColor': Colors.red,
          'textColor': AppColors.customRed,
        },
      ]);
    } else if (currentTab.value == 1) {
      orders.addAll([
        {
          'products': 'منتج 4',
          'date': '2025-04-16',
          'status': 'active',
          'statusColor': AppColors.customOrange,
          'textColor': AppColors.customOrange2
        },
      ]);
    } else if (currentTab.value == 0) {
      orders.addAll([
        {
          'products':
              '  fas as sd asd asdasdaasdasda asdasda asdasdaasdasda sad sdasdas das dasd منتج 5, منتج 6',
          'date': '2025-04-13',
          'status': 'completed',
          'statusColor': AppColors.customGreen2,
          'textColor': AppColors.customGreen,
        },
      ]);
    }
  }
}
