import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TargetSectionController extends GetxController {
  final toDateController = TextEditingController();
  final fromDateController = TextEditingController();

  final targetNameController = TextEditingController();
  String targetType = '';
  final mainValueController = TextEditingController();
  final targetValueController = TextEditingController();
  final notesController = TextEditingController();

  String product = '';
  String personal = '';
  String employee = '';

  final RxInt selectedTypeIndex = 0.obs;

  final currentTab = 0.obs;
  final tabs = ['generalTarget', 'specialTarget', 'endedTarget'].obs;

  final targets = <Map<String, dynamic>>[].obs;

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
    targets.clear();
    if (currentTab.value == 0) {
      targets.addAll(
        [
          {
            'targetName': 'هدف هدف هدف 1',
            'targetType': 'خاص',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
          {
            'targetName': 'هدف 1',
            'targetType': 'عام',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
          {
            'targetName': 'هدف هدف هدف 1',
            'targetType': 'خاص',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
          {
            'targetName': 'هدف 1',
            'targetType': 'عام',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
        ],
      );
    } else if (currentTab.value == 1) {
      targets.addAll(
        [
          {
            'targetName': 'هدف هدف هدف 1',
            'targetType': 'خاص',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
          {
            'targetName': 'هدف 1',
            'targetType': 'عام',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
        ],
      );
    } else if (currentTab.value == 2) {
      targets.addAll(
        [
          {
            'targetName': 'هدف هدف هدف 1',
            'targetType': 'خاص',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
          {
            'targetName': 'هدف 1',
            'targetType': 'عام',
            'completionPercentage': '50',
            'targetValue': '50 الف',
            'mainValue': '50 الف',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'followUp': 'منتج',
          },
        ],
      );
    }
  }

  @override
  void onClose() {
    super.onClose();
    fromDateController.dispose();
    toDateController.dispose();
    targetNameController.dispose();
    targetValueController.dispose();
    mainValueController.dispose();
    notesController.dispose();
    targetType = '';
  }

  List<String> targetTypes = ['خاص', 'عام'];

  List<String> productsList = ['product1', 'product2', 'product3'];

  List<String> personalsList = ['personal1', 'personal2', 'personal3'];

  List<String> employeesList = ['employee1', 'employee2', 'employee3'];

  void createTarget() {
    Get.snackbar(
      'success'.tr,
      'targetAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
