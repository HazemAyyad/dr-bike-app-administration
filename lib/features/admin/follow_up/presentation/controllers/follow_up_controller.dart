import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/followup_modle.dart';
import '../../domain/usecases/get_followup_usecase.dart';

class FollowUpController extends GetxController {
  final GetFollowupUsecase getFollowupUsecase;

  FollowUpController({required this.getFollowupUsecase});

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();

  final customerNameController = TextEditingController();
  final customerphoneNumberController = TextEditingController();
  final customerNotesController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> tasks = <Map<String, dynamic>>[].obs;
  final tabs = [
    'initialFollowUp',
    'notify_customer',
    'completion_and_agreement',
    'archive',
  ].obs;

  void changeTab(int index) {
    currentTab.value = index;
    fetchOrders();
  }

  void fetchOrders() {
    // Simulate fetching orders based on the current tab
    tasks.clear();
    if (currentTab.value == 0) {
      tasks.addAll([
        {
          'customerName': 'ماجد محمد محمود احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
        {
          'customerName': 'ماجد احمد',
          'productDetails': 'موتور m1',
          'startDate': '01/03/2025',
        },
      ]);
    } else if (currentTab.value == 1) {
      tasks.addAll(
        [
          {
            'customerName': 'ماجد احمد',
            'productDetails': 'موتور m1',
            'startDate': '01/03/2025',
          },
          {
            'customerName': 'ماجد احمد',
            'productDetails': 'موتور m1',
            'startDate': '01/03/2025',
          },
        ],
      );
    }
  }

  String selectedCustomerName = '';
  List<String> customerNameList = [
    'محمد رفعت',
    'محمد احمد',
    'محمود محمد',
  ];
  void addNewFollowUp() {
    Get.snackbar(
      'success'.tr,
      'followUpAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String selectedCustomerType = '';
  List<String> customerTypeList = ['جملة', 'قطاعي'];

  void addNewCustomer() {
    Get.snackbar(
      'success'.tr,
      'customerAddedSuccessfully'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  final RxBool isLoading = false.obs;
  final List<FollowupModel> followups = [];
  // get all Follow ups
  void getAllFollowUps() async {
    isLoading(true);
    final result = await getFollowupUsecase.call();
    followups.assignAll(result.where((e) => e.followupStatus == 'initial'));
    isLoading(false);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getAllFollowUps();
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    customerNameController.dispose();
    customerphoneNumberController.dispose();
    customerNotesController.dispose();
    selectedCustomerName = '';
    super.onClose();
  }
}
