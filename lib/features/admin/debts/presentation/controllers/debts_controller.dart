import 'dart:io';

import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/usecases/debts_owed_to_us_usecase.dart';
import '../../domain/usecases/debts_we_owe_usecase.dart';
import '../../domain/usecases/total_debts_owed_to_us_usecase.dart';
import '../../domain/usecases/total_debts_we_owe_usecase.dart';
import '../../domain/usecases/user_debts_data_usecase.dart';
import 'debts_data_service.dart';

class DebtsController extends GetxController {
  final TotalDebtsOwedToUsUsecase totalDebtsOwedToUs;
  final TotalDebtsWeOweUsecase totalDebtsWeOwe;
  final DebtsOwedToUsUsecase debtsOwedToUs;
  final DebtsWeOweUsecase debtsWeOwe;

  final UserTransactionsUsecase userTransactionsData;

  final DebtsDataService dataService;

  DebtsController({
    required this.totalDebtsOwedToUs,
    required this.totalDebtsWeOwe,
    required this.debtsOwedToUs,
    required this.debtsWeOwe,
    required this.userTransactionsData,
    required this.dataService,
  });

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> debts = <Map<String, dynamic>>[].obs;
  final RxString sortBy = 'all'.obs;

  final TextEditingController totalDebtController = TextEditingController();
  final TextEditingController moreDetailsController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  String customerName = '';
  // Rx<File?> selectedFile = Rx<File?>(null);
  List<File> selectedFile = [];

  // Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final RxBool isDataLoaded = false.obs;

  RxBool isDebtsWeOweLoading = false.obs;

  RxBool userTransactionsLoading = false.obs;

  final tabs = ['debtsForUs', 'debtsOnUs'].obs;

  @override
  void onInit() {
    super.onInit();
    getDebtsWeOwe();
  }

  void changeTab(int index) {
    currentTab.value = index;
  }

  void getTotalDebtsOwedToUs() async {
    String token = await UserData.getUserToken();
    final result = await totalDebtsOwedToUs.call(token: token);

    result.fold((failure) {}, (success) {
      dataService.totalDebtsOwedToUsModel.value = success;
    });
  }

  void getTotalDebtsWeOwe() async {
    String token = await UserData.getUserToken();
    final result = await totalDebtsWeOwe.call(token: token);
    result.fold((failure) {}, (success) {
      dataService.totalDebtsWeOweModel.value = success;
    });
  }

  void getDebtsOwedToUs() async {
    dataService.debtsWeOweModel.value == null
        ? isDebtsWeOweLoading(true)
        : isDebtsWeOweLoading(false);
    // if (dataService.totalDebtsWeOweModel.value != null) return;
    String token = await UserData.getUserToken();
    final result = await debtsOwedToUs.call(token: token);
    result.fold((failure) {}, (success) {
      dataService.debtsOwedToUsModel.value = success;
    });
    isDebtsWeOweLoading(false);
  }

  void getDebtsWeOwe() async {
    dataService.debtsWeOweModel.value == null
        ? isDebtsWeOweLoading(true)
        : isDebtsWeOweLoading(false);
    String token = await UserData.getUserToken();
    final result = await debtsWeOwe.call(token: token);
    result.fold((failure) {}, (success) {
      dataService.debtsWeOweModel.value = success;
    });
    isDebtsWeOweLoading(false);
  }

  void getUserTransactionsData(String customerId) async {
    if (dataService.customerId != customerId) {
      userTransactionsLoading(true);
      dataService.userTransactionsDataModel.value = null;
      dataService.customerId = customerId;
    } else {
      userTransactionsLoading(false);
    }

    String token = await UserData.getUserToken();
    final result =
        await userTransactionsData.call(token: token, customerId: customerId);
    result.fold((failure) {}, (success) {
      dataService.userTransactionsDataModel.value = success;
    });
    userTransactionsLoading(false);
  }

  List get filteredDebts {
    List filtered = (currentTab.value == 0
                ? dataService.debtsOwedToUsModel.value?.debts
                : dataService.debtsWeOweModel.value?.debts)
            ?.where((debt) =>
                debt.debtType ==
                (currentTab.value == 0 ? 'owed to us' : 'we owe'))
            .toList() ??
        [];

    switch (sortBy.value) {
      case 'ended':
        filtered = filtered.where((debt) => debt.status == 'paid').toList();
        break;
      case 'not_ended':
        filtered = filtered.where((debt) => debt.status != 'paid').toList();
        break;
      case 'new_transactions':
        filtered.sort((a, b) => b.debtCreatedAt.compareTo(a.debtCreatedAt));
        break;
      case 'old_transactions':
        filtered.sort((a, b) => a.debtCreatedAt.compareTo(b.debtCreatedAt));
        break;
      case 'largest_amount':
        filtered.sort(
            (a, b) => double.parse(a.total).compareTo(double.parse(b.total)));
        break;
      case 'smallest_amount':
        filtered.sort(
            (a, b) => double.parse(b.total).compareTo(double.parse(a.total)));
        break;
      case 'alphabetical':
        filtered.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      default:
        // 'all' - no additional filtering
        break;
    }

    return filtered;
  }

  void setSortBy(String sort) {
    sortBy.value = sort;
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dueDateController.text = picked.toIso8601String().split('T')[0];
    }
  }

  void createDebts() {
    if (formKey.currentState?.validate() ?? false) {
      if (totalDebtController.text.isEmpty ||
          dueDateController.text.isEmpty ||
          customerName.isEmpty) {
        Get.snackbar(
          'error'.tr,
          'debtCreatedSuccessfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final newDebt = {
        'isForUs': false,
        'debtsemployeeName': customerName,
        'debtsAmount': totalDebtController.text,
        // 'image': selectedFile..value?.path,
        'startDate': '2025-02-25',
        'endDate': dueDateController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'isDone': false,
      };

      debts.addAll([newDebt]);
      // fetchOrders(); // Refresh the debts list
      Get.back(); // Close the bottom sheet
      Get.snackbar(
        'success'.tr,
        'debtCreatedSuccessfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    totalDebtController.dispose();
    moreDetailsController.dispose();
    dueDateController.dispose();
    // selectedFile.value = null;
    customerName = '';
    super.dispose();
  }
}
