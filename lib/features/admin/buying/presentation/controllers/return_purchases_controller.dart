import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../data/models/return_purchases_models/return_products_model.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/return_purchases_usecases/change_return_to_delivered_usecase.dart';
import 'buying_serves.dart';

class ReturnPurchasesController extends GetxController {
  final GetBillsUsecase getBillsUsecase;
  final ChangeReturnToDeliveredUsecase changeReturnToDeliveredUsecase;

  ReturnPurchasesController({
    required this.getBillsUsecase,
    required this.changeReturnToDeliveredUsecase,
  });

  List<String> tabs = ['return', 'delivered'];

  RxInt currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final RxBool movedToDelivered = false.obs;

  RxBool isLoading = false.obs;

  void getReturnBills() async {
    BuyingServes().returnPurchasesListTasks.isEmpty ? isLoading(true) : null;
    update();

    // دالة مساعدة للتجميع
    Map<String, List<ReturnProduct>> groupByDate(List<ReturnProduct> list) {
      final Map<String, List<ReturnProduct>> grouped = {};

      for (var task in list) {
        final receiptDateObj = task.createdAt;
        final dayName =
            DateFormat.EEEE(Get.locale!.languageCode).format(receiptDateObj);
        final dateKey =
            "$dayName ${receiptDateObj.year}-${receiptDateObj.month}-${receiptDateObj.day}";

        if (grouped.containsKey(dateKey)) {
          if (!grouped[dateKey]!.any((a) => a.id == task.id)) {
            grouped[dateKey]!.add(task);
          }
        } else {
          grouped[dateKey] = [task];
        }
      }

      // ✅ الترتيب من الأقرب للأبعد
      final sortedEntries = grouped.entries.toList()
        ..sort((a, b) {
          final aDate = a.value.first.createdAt;
          final bDate = b.value.first.createdAt;
          return aDate.compareTo(bDate); // الأحدث الأول
        });

      return Map.fromEntries(sortedEntries);
    }

    final returnPurchases = await getBillsUsecase.call(page: '6');
    final returnPurchasesList = mapListFromResponseKey(
      returnPurchases,
      'return_products',
      (Map<String, dynamic> m) => ReturnProduct.fromJson(m),
      debugScope: 'ReturnPurchasesController.pendingReturns',
    );
    BuyingServes().returnPurchasesListTasks.value =
        groupByDate(returnPurchasesList);
    returnPurchasesSearch.assignAll(BuyingServes().returnPurchasesListTasks);

    final deliveredPurchases = await getBillsUsecase.call(page: '7');
    final deliveredPurchasesList = mapListFromResponseKey(
      deliveredPurchases,
      'return_products',
      (Map<String, dynamic> m) => ReturnProduct.fromJson(m),
      debugScope: 'ReturnPurchasesController.deliveredReturns',
    );
    BuyingServes().deliveredPurchasesTasks.value =
        groupByDate(deliveredPurchasesList);
    deliveredPurchasesSearch.assignAll(BuyingServes().deliveredPurchasesTasks);
    isLoading(false);
    update();

    isLoading(false);
    update();
  }

  final returnPurchasesSearch = <String, List<ReturnProduct>>{}.obs;
  final deliveredPurchasesSearch = <String, List<ReturnProduct>>{}.obs;

  void searchBar(String value) {
    if (value.isNotEmpty) {
      returnPurchasesSearch.value = Map.fromEntries(
        BuyingServes().returnPurchasesListTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.name.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );

      deliveredPurchasesSearch.value = Map.fromEntries(
        BuyingServes().deliveredPurchasesTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.name.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );
    } else {
      returnPurchasesSearch.assignAll(BuyingServes().returnPurchasesListTasks);
      deliveredPurchasesSearch
          .assignAll(BuyingServes().deliveredPurchasesTasks);
    }
    update();
  }

  // changeReturnToDelivered
  void changeReturnToDelivered({
    required BuildContext context,
    required String returnPurchaseId,
  }) async {
    isLoading(true);
    final result = await changeReturnToDeliveredUsecase.call(
        returnPurchaseId: returnPurchaseId);

    result.fold(
      (failure) {
        final errors = failure.data != null ? failure.data['errors'] : null;

        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((list) => list)
              .cast<String>()
              .join('')
              .replaceAll('.', '- \n');

          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: messages,
          );
        } else {
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: "Unexpected error occurred",
          );
        }
      },
      (success) {
        getReturnBills();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
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
    update();
  }

  @override
  void onInit() async {
    getReturnBills();
    returnPurchasesSearch.assignAll(BuyingServes().returnPurchasesListTasks);
    deliveredPurchasesSearch.assignAll(BuyingServes().deliveredPurchasesTasks);
    super.onInit();
  }
}
