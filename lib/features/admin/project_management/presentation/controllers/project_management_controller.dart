import 'dart:io';

import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ProjectManagementController extends GetxController {
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  final projectNameController = TextEditingController();

  final partnerShareController = TextEditingController();
  final partnerPercentageController = TextEditingController();

  final currentTab = 0.obs;
  RxList<Map<String, dynamic>> projectList = <Map<String, dynamic>>[].obs;

  final tabs = ['projectList', 'completedProjects'].obs;

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
    projectList.clear();
    if (currentTab.value == 0) {
      projectList.addAll(
        [
          {
            'projectName': 'عمل صفقة موتور',
            'completionPercentage': '50',
            'projectCost': '2000',
            'paymentMethod': 'كاش',
            'projectPartners': 'احمدعلي',
            'partnerShare': '500',
            'partnerPercentage': '%50',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'projectDocuments': 'اوراق الشركة',
            'totalSales': '20',
            'projectStatus': '',
            'projectOrProductsImages': AssetsManager.rectangle,
          },
          {
            'projectName': 'عمل صفقة موتور',
            'completionPercentage': '50',
            'projectCost': '2000',
            'paymentMethod': 'كاش',
            'projectPartners': '',
            'partnerShare': '0',
            'partnerPercentage': '%0',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'projectDocuments': 'اوراق الشركة',
            'totalSales': '20',
            'projectStatus': '',
            'projectOrProductsImages': AssetsManager.rectangle,
          },
        ],
      );
    } else if (currentTab.value == 1) {
      projectList.addAll(
        [
          {
            'projectName': 'عمل صفقة موتور',
            'completionPercentage': '100',
            'projectCost': '2000',
            'paymentMethod': 'cash',
            'projectPartners': 'لا احد',
            'partnerShare': '0',
            'partnerPercentage': '%0',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'projectDocuments': 'اوراق الشركة',
            'totalSales': '20',
            'projectStatus': '',
            'projectOrProductsImages': AssetsManager.rectangle,
          },
          {
            'projectName': 'عمل صفقة موتور',
            'completionPercentage': '100',
            'projectCost': '2000',
            'paymentMethod': 'cash',
            'projectPartners': 'لا احد',
            'partnerShare': '0',
            'partnerPercentage': '0%',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'projectDocuments': 'اوراق الشركة',
            'totalSales': '20',
            'projectStatus': '1',
            'projectOrProductsImages': AssetsManager.rectangle,
          },
          {
            'projectName': 'عمل صفقة موتور',
            'completionPercentage': '100',
            'projectCost': '2000',
            'paymentMethod': 'cash',
            'projectPartners': 'لا احد',
            'partnerShare': '0',
            'partnerPercentage': '0%',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'projectDocuments': 'اوراق الشركة',
            'totalSales': '20',
            'projectStatus': '1',
            'projectOrProductsImages': AssetsManager.rectangle,
          },
          {
            'projectName': 'عمل صفقة موتور',
            'completionPercentage': '100',
            'projectCost': '2000',
            'paymentMethod': 'cash',
            'projectPartners': 'لا احد',
            'partnerShare': '0',
            'partnerPercentage': '0%',
            'notes': 'وجد بعض الملاحظات علي المشروع مثل ....',
            'projectDocuments': 'اوراق الشركة',
            'totalSales': '20',
            'projectStatus': '1',
            'projectOrProductsImages': AssetsManager.rectangle,
          },
        ],
      );
    }
  }

  String projectCost = '';

  List<String> projectCostList = ['cash'.tr, 'visa'.tr];

  RxString projectPartners = ''.obs;

  List<String> projectPartnersList = [
    'noPartners'.tr,
    'محمد احمد',
    'احمد محمد'
  ];
  final List<String> noPartnerValues = ['بدون', 'No Partners'];

  void createProject() {
    Get.snackbar(
      'success'.tr,
      'projectAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // final Rx<File?> selectedFile = Rx<File?>(null);
  List<File> selectedFile = [];

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    projectNameController.dispose();
    projectPartners == ''.obs;
    projectCost == '';
    super.onClose();
  }
}
