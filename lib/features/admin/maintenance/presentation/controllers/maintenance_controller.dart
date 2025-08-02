import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/assets_manger.dart';

class MaintenanceController extends GetxController {
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  TextEditingController customerNameController = TextEditingController();

  TextEditingController detailsController = TextEditingController();

  RxInt currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
  }

  List<String> tabs = ['newRequest', 'inProgress', 'readyToDeliver', 'archive'];

  final RxList<Map<String, dynamic>> maintenanceList =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  @override
  void dispose() {
    employeeNameController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    customerNameController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  void fetchOrders() {
    // Simulate fetching orders based on the current tab
    maintenanceList.clear();
    if (currentTab.value == 0) {
      maintenanceList.addAll(
        [
          {
            'id': '1',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '2',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '2',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '1',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '3',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الاربعاء',
            'time': '-3',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    } else if (currentTab.value == 1) {
      maintenanceList.addAll(
        [
          {
            'id': '1',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '2',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '2',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '1',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '3',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الاربعاء',
            'time': '-3',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    } else if (currentTab.value == 2) {
      maintenanceList.addAll(
        [
          {
            'id': '1',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '2',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '2',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '1',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '3',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الاربعاء',
            'time': '-3',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    } else if (currentTab.value == 3) {
      maintenanceList.addAll(
        [
          {
            'id': '1',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '2',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '2',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الثلاثاء',
            'time': '1',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
          {
            'id': '3',
            'name': 'محمد على',
            'date': '2025/07/25',
            'days': 'الاربعاء',
            'time': '-3',
            'archive': 'تم التسليم',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    }
  }

  // متغير لاظهار الخطوات
  final RxInt selectedStep = 1.obs;

  final List<Map<int, String>> timeLineSteps = [
    {1: 'newMaintenance'},
    {2: 'inProgress'},
    {3: 'readyToDeliver'},
  ];

  void changeSelected(int index) => selectedStep.value = index;

  void nextStep() {
    if (selectedStep.value < 3) {
      selectedStep.value += 1;
    } else {
      Get.back();
      selectedStep.value = 1;
    }
  }

  void prevStep() => selectedStep.value -= 1;

  List<String> customersNameList = [
    'محمد على',
    'محمد على',
    'محمد على',
  ];
  // متغير لاظهار التكرار
  RxBool isRecurrenceVisible = false.obs;

  void toggleRecurrence() {
    isRecurrenceVisible.value = !isRecurrenceVisible.value;
  }

  RxList<String> selectedDaysList = <String>[].obs;

  // متغير لاظهار الساعة
  RxBool isTimeVisible = false.obs;

  final startTime = TimeOfDay.now().obs;

  void toggleTime() {
    isTimeVisible.value = !isTimeVisible.value;
  }

  // final Rx<File?> selectedImage = Rx<File?>(null);
  List<File> selectedMedia = [];
}
