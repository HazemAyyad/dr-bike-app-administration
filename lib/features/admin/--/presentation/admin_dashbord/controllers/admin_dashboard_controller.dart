import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../auth/data/models/user_model.dart';
import '../../../../employee_section/domain/usecases/get_all_employee.dart';

class DashboardController extends GetxController
    with GetTickerProviderStateMixin {
  GetAllEmployeeUsecase getAllEmployeeUsecase;
  DashboardController({
    required this.getAllEmployeeUsecase,
  });

  List<Map<String, dynamic>> buttons = [
    {
      'id': '21',
      'title': 'employeeTasks',
      'route': AppRoutes.EMPLOYEETASKSSCREEN
    },
    {
      'id': '22',
      'title': 'privateTasks',
      'route': AppRoutes.PRIVATETASKSSCREEN
    },
    {
      'id': '23',
      'title': 'employeeDepartment',
      'route': AppRoutes.EMPLOYEESECTIONSCREEN
    },
    {
      'id': '24',
      'title': 'projectManagement',
      'route': AppRoutes.PROJECTMANAGEMENTSCREEN
    },
    {'id': '25', 'title': 'messagesDepartment', 'route': ''},
    {'id': '26', 'title': 'infoCompletion', 'route': ''},
    {
      'id': '27',
      'title': 'targetSetting',
      'route': AppRoutes.TARGETSECTIONSCREEN
    },
    {
      'id': '28',
      'title': 'followUpDepartment',
      'route': AppRoutes.CURRENTFOLLOWUPSCREEN
    },
    {'id': '29', 'title': 'debts', 'route': AppRoutes.DEBTSSCREEN},
    {'id': '30', 'title': 'sales', 'route': AppRoutes.SALESSCREEN},
    {
      'id': '31',
      'title': 'generalData',
      'route': AppRoutes.GENERALDATALISTSCREEN
    },
    {'id': '32', 'title': 'partnersDepartment', 'route': ''},
    {'id': '33', 'title': 'stock', 'route': AppRoutes.STOCKSCREEN},
    {'id': '34', 'title': 'boxes', 'route': AppRoutes.BOXESSCREEN},
    {'id': '35', 'title': 'purchasingDepartment', 'route': ''},
    {'id': '36', 'title': 'financialMatters', 'route': ''},
    {
      'id': '37',
      'title': 'checksandCommitments',
      'route': AppRoutes.CHECKSSCREEN
    },
    {'id': '38', 'title': 'maintenance', 'route': AppRoutes.MAINTENANCESCREEN},
  ];

  // متغيرات للإحصائيات
  final RxInt debtToUs = 100.obs;
  final RxInt debtOnUs = 20.obs;
  final RxInt products = 150.obs;
  final RxInt completedTasks = 30.obs;
  final RxInt pendingTasks = 5.obs;
  final RxInt expenses = 1200.obs;

  // متغير للتحكم في قائمة الإضافة
  final RxBool isAddMenuOpen = false.obs;

  late AnimationController animController;
  late Animation<double> opacityAnimation;
  late Animation<double> sizeAnimation;

  // final Rxn<UserModel> userData = Rxn<UserModel>();

  // void getUserData() async {
  // userData.value = await UserData.getSavedUser();
  // update();
  // }

  @override
  void onInit() async {
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
    // getEmployee();
    // getUserData();
  }

  void toggleAddMenu() {
    isAddMenuOpen.value = !isAddMenuOpen.value;
  }

  List<Map<String, String>> adminAddList = [
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
    opacityAnimation.isDismissed;
    sizeAnimation.isDismissed;
    super.onClose();
  }
}
