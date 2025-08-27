import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../domain/usecases/add_debt_usecase.dart';
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
  final AddDebtUsecase addDebtUsecase;
  final DebtsWeOweUsecase debtsWeOwe;

  final UserTransactionsUsecase userTransactionsData;

  final DebtsDataService dataService;

  DebtsController({
    required this.totalDebtsOwedToUs,
    required this.totalDebtsWeOwe,
    required this.debtsOwedToUs,
    required this.userTransactionsData,
    required this.debtsWeOwe,
    required this.addDebtUsecase,
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

  void changeTab(int index) {
    currentTab.value = index;
  }

  void getTotalDebtsOwedToUs() async {
    final result = await totalDebtsOwedToUs.call();

    result.fold((failure) {}, (success) {
      dataService.totalDebtsOwedToUsModel.value = success;
    });
  }

  void getTotalDebtsWeOwe() async {
    final result = await totalDebtsWeOwe.call();
    result.fold((failure) {}, (success) {
      dataService.totalDebtsWeOweModel.value = success;
    });
  }

  void getDebtsOwedToUs() async {
    dataService.debtsWeOweModel.value == null
        ? isDebtsWeOweLoading(true)
        : isDebtsWeOweLoading(false);
    // if (dataService.totalDebtsWeOweModel.value != null) return;
    final result = await debtsOwedToUs.call();
    result.fold((failure) {}, (success) {
      dataService.debtsOwedToUsModel.value = success;
    });
    isDebtsWeOweLoading(false);
  }

  void getDebtsWeOwe() async {
    dataService.debtsWeOweModel.value == null
        ? isDebtsWeOweLoading(true)
        : isDebtsWeOweLoading(false);
    final result = await debtsWeOwe.call();
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

    final result = await userTransactionsData.call(customerId: customerId);
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

  final RxBool isLoading = false.obs;

  // add Debts
  void addDebts(BuildContext context, String customerId, String type) async {
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
      isLoading(true);
      final result = await addDebtUsecase.call(
        customerId: customerId,
        dueDate: dueDateController.text,
        total: totalDebtController.text,
        receiptImage: selectedFile,
        type: type,
        notes: moreDetailsController.text,
      );
      result.fold(
        (failure) {
          final errors = failure.data['errors'];
          String errorMessage = '';

          if (errors is Map) {
            errorMessage = errors.entries
                .map((e) => "${e.key}: ${(e.value as List).join(', ')}")
                .join("\n");
          } else {
            errorMessage = errors.toString();
          }

          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessage,
          );
        },
        (success) {
          getDebtsWeOwe();
          getDebtsOwedToUs();
          getTotalDebtsWeOwe();
          getTotalDebtsOwedToUs();
          Get.back();

          Future.delayed(
            Duration(milliseconds: 1500),
            () {
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: success,
          );
        },
      );
      isLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    getDebtsWeOwe();
  }

  @override
  void dispose() {
    totalDebtController.dispose();
    moreDetailsController.dispose();
    dueDateController.dispose();
    super.dispose();
  }
}
