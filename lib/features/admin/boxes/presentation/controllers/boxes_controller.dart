import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/assets_manger.dart';

class BoxesController extends GetxController {
  final GlobalKey formKey = GlobalKey();

  TextEditingController employeeNameController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  final tabs = ['boxes', 'movements', 'archive'].obs;
  RxInt currentTab = 0.obs;
  final boxes = <Map<String, dynamic>>[].obs;

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
    boxes.clear();
    if (currentTab.value == 0) {
      boxes.addAll(
        [
          {
            'boxName': 'محل نوفل',
            'amount': '1200',
            'image': AssetsManger.noImageNet,
          },
          {
            'boxName': 'محل اخر',
            'amount': '1200',
            'image': AssetsManger.noImageNet,
          },
          {
            'boxName': 'محل الخليل',
            'amount': '1200',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    } else if (currentTab.value == 1) {
      boxes.addAll(
        [
          {
            'boxName': 'محل الخليل',
            'amount': '+5000',
            'image': AssetsManger.noImageNet,
            'note': 'اضافة رصيد',
          },
          {
            'boxName': 'محل الخليل',
            'amount': '-2000',
            'image': AssetsManger.noImageNet,
            'note': 'سحب رصيد',
            'from': '',
            'to': '',
          },
          {
            'boxName': 'محل الخليل',
            'amount': '15000',
            'image': AssetsManger.noImageNet,
            'note': 'نقل رصيد',
            'from': 'محل الخليل',
            'to': 'محل خان',
          },
        ],
      );
    } else if (currentTab.value == 2) {
      boxes.addAll(
        [
          {
            'boxName': 'محل الخليل',
            'image': AssetsManger.noImageNet,
            'note': 'ظاهر',
          },
          {
            'boxName': 'محل الخليل',
            'image': AssetsManger.noImageNet,
            'note': 'غير ظاهر',
          },
          {
            'boxName': 'محل الخليل',
            'image': AssetsManger.noImageNet,
            'note': 'ظاهر',
          },
        ],
      );
    }
  }

  // انشاء الصناديق

  TextEditingController createBoxNameController = TextEditingController();
  TextEditingController createStartBalanceController = TextEditingController();

  // تعديل الصناديق
  TextEditingController editBoxNameController = TextEditingController();
  TextEditingController editStartBalanceController = TextEditingController();
  TextEditingController appearController = TextEditingController();

  List<String> appears = ['visible', 'notVisible'];

  // اضافة رصيد
  TextEditingController addBalanceBoxNameController = TextEditingController();
  TextEditingController addBalanceValueController = TextEditingController();

  // نقل رصيد
  TextEditingController transferFromBoxNameController = TextEditingController();
  TextEditingController transferToBoxNameController = TextEditingController();
  TextEditingController transferTotalController = TextEditingController();

  @override
  void dispose() {
    employeeNameController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    createBoxNameController.dispose();
    createStartBalanceController.dispose();
    editBoxNameController.dispose();
    editStartBalanceController.dispose();
    appearController.dispose();
    addBalanceBoxNameController.dispose();
    addBalanceValueController.dispose();
    transferFromBoxNameController.dispose();
    transferToBoxNameController.dispose();
    transferTotalController.dispose();
    super.dispose();
  }
}
