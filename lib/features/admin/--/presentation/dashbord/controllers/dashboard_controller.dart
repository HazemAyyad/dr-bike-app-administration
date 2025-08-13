import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';

class DashboardController extends GetxController
    with GetTickerProviderStateMixin {
  List<Map<String, dynamic>> buttons = [
    {'title': 'employeeTasks', 'route': AppRoutes.EMPLOYEETASKSSCREEN},
    {'title': 'privateTasks', 'route': AppRoutes.PRIVATETASKSSCREEN},
    {'title': 'employeeDepartment', 'route': AppRoutes.EMPLOYEESECTIONSCREEN},
    {'title': 'projectManagement', 'route': AppRoutes.PROJECTMANAGEMENTSCREEN},
    {'title': 'messagesDepartment', 'route': ''},
    {'title': 'infoCompletion', 'route': ''},
    {'title': 'targetSetting', 'route': AppRoutes.TARGETSECTIONSCREEN},
    {'title': 'followUpDepartment', 'route': AppRoutes.CURRENTFOLLOWUPSCREEN},
    {'title': 'debts', 'route': AppRoutes.DEBTSSCREEN},
    {'title': 'sales', 'route': AppRoutes.SALESSCREEN},
    {'title': 'generalData', 'route': AppRoutes.GENERALDATALISTSCREEN},
    {'title': 'partnersDepartment', 'route': ''},
    {'title': 'inventory', 'route': ''},
    {'title': 'boxes', 'route': AppRoutes.BOXESSCREEN},
    {'title': 'purchasingDepartment', 'route': ''},
    {'title': 'maintenance', 'route': AppRoutes.MAINTENANCESCREEN},
    {'title': 'checksandCommitments', 'route': AppRoutes.CHECKSSCREEN},
  ];

  // متغيرات للإحصائيات
  final RxInt debtToUs = 100.obs;
  final RxInt debtOnUs = 20.obs;
  final RxInt products = 150.obs;
  final RxInt employees = 40.obs;
  final RxInt completedTasks = 30.obs;
  final RxInt pendingTasks = 5.obs;
  final RxInt expenses = 1200.obs;

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  @override
  void onInit() {
    super.onInit();

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

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> addList = [
    {
      'title': 'newInvoice',
      'icon': AssetsManger.invoiceIcon,
      'route': AppRoutes.ADDNEWEMPLOYEESCREEN
    },
    {
      'title': 'newEmployee',
      'icon': AssetsManger.userIcon,
      'route': AppRoutes.ADDNEWEMPLOYEESCREEN,
    },
    {
      'title': 'newExpense',
      'icon': AssetsManger.moneyIcon,
      'route': AppRoutes.ADDNEWEMPLOYEESCREEN,
    },
    {
      'title': 'newCustomer',
      'icon': AssetsManger.userIcon,
      'route': AppRoutes.ADDNEWCUSTOMERSCREEN,
    },
  ];

  @override
  void onClose() {
    animController.dispose();
    super.onClose();
  }
}
