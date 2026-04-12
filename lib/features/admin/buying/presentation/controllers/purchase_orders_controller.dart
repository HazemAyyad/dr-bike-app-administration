import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../data/models/bills_models/bills_model.dart';
import '../../domain/usecases/purchase_orders_usecases/cancel_bill_usecase.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/purchase_orders_usecases/change_one_status_usecase.dart';
import '../../domain/usecases/purchase_orders_usecases/change_status_usecase.dart';
import 'bills_controller.dart';
import 'buying_serves.dart';

class PurchaseOrdersController extends GetxController {
  final GetBillsUsecase getBillsUsecase;
  final CancelBillUsecase cancelBillUsecase;
  final ChangeStatusUsecase changeStatusUsecase;
  final ChangeOneStatusUsecase changeOneStatusUsecase;

  PurchaseOrdersController({
    required this.getBillsUsecase,
    required this.cancelBillUsecase,
    required this.changeStatusUsecase,
    required this.changeOneStatusUsecase,
  });

  final formKey = GlobalKey<FormState>();

  List<String> tabs = ['unprocessed', 'not_matched', 'completed', 'deposits'];

  RxInt currentTab = 0.obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  RxBool finished = false.obs;

  RxBool missing = false.obs;
  final TextEditingController missingController = TextEditingController();

  RxBool returnedExtra = false.obs;
  final TextEditingController returnedExtraController = TextEditingController();

  RxBool notCompatible = false.obs;
  final TextEditingController notCompatibleController = TextEditingController();
  final TextEditingController notCompatibleDescriptionController =
      TextEditingController();

  RxBool purchase = false.obs;

  RxBool deliverProduct = false.obs;

  RxBool purchaseNewPrice = false.obs;
  final TextEditingController purchaseNewPriceController =
      TextEditingController();

  void setOnlyOneTrue(String key) {
    finished.value = key == 'finished';
    missing.value = key == 'missing';
    returnedExtra.value = key == 'returnedExtra';
    notCompatible.value = key == 'notCompatible';
    purchase.value = key == 'purchase';
    deliverProduct.value = key == 'deliverProduct';
    purchaseNewPrice.value = key == 'purchaseNewPrice';
    update();
  }

  RxBool isLoading = false.obs;

  void getBills() async {
    BuyingServes().unprocessedTasks.isEmpty ? isLoading(true) : null;
    update();
    // دالة مساعدة للتجميع
    Map<String, List<BillDataModel>> groupByDate(List<BillDataModel> list) {
      final Map<String, List<BillDataModel>> grouped = {};

      for (var task in list) {
        final receiptDateObj = DateTime.parse(task.createdAt);
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
          final aDate = DateTime.parse(a.value.first.createdAt);
          final bDate = DateTime.parse(b.value.first.createdAt);
          return aDate.compareTo(bDate); // الأحدث الأول
        });
      return Map.fromEntries(sortedEntries);
    }

    final unprocessed = await getBillsUsecase.call(page: '2');
    final unprocessedList = mapListFromResponseKey(
      unprocessed,
      'bills',
      (Map<String, dynamic> m) => BillDataModel.fromJson(m),
      debugScope: 'PurchaseOrdersController.unprocessed',
    );
    BuyingServes().unprocessedTasks.value = groupByDate(unprocessedList);
    unprocessedSearch.assignAll(BuyingServes().unprocessedTasks);
    isLoading(false);
    update();

    final notMatched = await getBillsUsecase.call(page: '3');
    final notMatchedList = mapListFromResponseKey(
      notMatched,
      'bills',
      (Map<String, dynamic> m) => BillDataModel.fromJson(m),
      debugScope: 'PurchaseOrdersController.notMatched',
    );
    BuyingServes().notMatchedTasks.value = groupByDate(notMatchedList);
    notMatchedSearch.assignAll(BuyingServes().notMatchedTasks);

    final completed = await getBillsUsecase.call(page: '4');
    final completedList = mapListFromResponseKey(
      completed,
      'bills',
      (Map<String, dynamic> m) => BillDataModel.fromJson(m),
      debugScope: 'PurchaseOrdersController.completed',
    );
    BuyingServes().completedTasks.value = groupByDate(completedList);
    completedSearch.assignAll(BuyingServes().completedTasks);

    final deposits = await getBillsUsecase.call(page: '5');
    final depositsList = mapListFromResponseKey(
      deposits,
      'bills',
      (Map<String, dynamic> m) => BillDataModel.fromJson(m),
      debugScope: 'PurchaseOrdersController.deposits',
    );
    BuyingServes().depositsTasks.value = groupByDate(depositsList);
    depositsSearch.assignAll(BuyingServes().depositsTasks);

    isLoading(false);
    update();
  }

  RxBool isLoading2 = false.obs;
  void cancelBill({
    required BuildContext context,
    required String billId,
  }) async {
    isLoading2(true);
    final result = await cancelBillUsecase.call(billId: billId);

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
        getBills();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
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
    isLoading2(false);
    update();
  }

  // change Status
  void changeStatus({
    required BuildContext context,
    required String billId,
    required String productId,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (finished.value ||
        missing.value ||
        returnedExtra.value ||
        notCompatible.value) {
      isLoading2(true);
      final result = await changeStatusUsecase.call(
        billId: billId,
        productId: productId,
        status: finished.value
            ? 'finished'
            : missing.value
                ? 'missing'
                : returnedExtra.value
                    ? 'extra'
                    : notCompatible.value
                        ? 'not_compatible'
                        : '',
        extraAmount: returnedExtraController.text,
        missingAmount: missingController.text,
        notCompatibleAmount: notCompatibleController.text,
        notCompatibleDescription: notCompatibleDescriptionController.text,
      );
// [finished,missing.extra,not_compatible]
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
              title: 'error'.tr,
              message: failure.data['message'],
            );
          }
        },
        (success) {
          returnedExtraController.clear();
          missingController.clear();
          notCompatibleController.clear();
          notCompatibleDescriptionController.clear();
          getBills();
          Get.find<BillsController>()
              .getBillDetails(context: context, billId: billId);
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
    }
    isLoading2(false);
    update();
  }

  // change One Status
  void changeOneStatus({
    required BuildContext context,
    required String billId,
    required String productId,
  }) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (purchaseNewPrice.value || purchase.value || deliverProduct.value) {
      isLoading2(true);
      final result = await changeOneStatusUsecase.call(
        billId: billId,
        productId: productId,
        price: purchaseNewPriceController.text,
        isDeliver: deliverProduct.value,
      );
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
              title: 'error'.tr,
              message: failure.data['message'],
            );
          }
        },
        (success) {
          purchaseNewPriceController.clear();
          getBills();
          Get.find<BillsController>()
              .getBillDetails(context: context, billId: billId);
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
    }
    isLoading2(false);
    update();
  }

  final unprocessedSearch = <String, List<BillDataModel>>{}.obs;
  final notMatchedSearch = <String, List<BillDataModel>>{}.obs;
  final completedSearch = <String, List<BillDataModel>>{}.obs;
  final depositsSearch = <String, List<BillDataModel>>{}.obs;

  void searchBar(String value) {
    if (value.isNotEmpty) {
      unprocessedSearch.value = Map.fromEntries(
        BuyingServes().unprocessedTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );

      notMatchedSearch.value = Map.fromEntries(
        BuyingServes().notMatchedTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );

      completedSearch.value = Map.fromEntries(
        BuyingServes().completedTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );

      depositsSearch.value = Map.fromEntries(
        BuyingServes().depositsTasks.entries.map((entry) {
          final filteredBills = entry.value
              .where((bill) =>
                  bill.seller.toLowerCase().contains(value.toLowerCase()))
              .toList();
          return MapEntry(entry.key, filteredBills);
        }).where((entry) => entry.value.isNotEmpty),
      );
    } else {
      unprocessedSearch.assignAll(BuyingServes().unprocessedTasks);
      notMatchedSearch.assignAll(BuyingServes().notMatchedTasks);
      completedSearch.assignAll(BuyingServes().completedTasks);
      depositsSearch.assignAll(BuyingServes().depositsTasks);
    }
    update();
  }

  @override
  void onInit() {
    getBills();
    unprocessedSearch.assignAll(BuyingServes().unprocessedTasks);
    notMatchedSearch.assignAll(BuyingServes().notMatchedTasks);
    completedSearch.assignAll(BuyingServes().completedTasks);
    depositsSearch.assignAll(BuyingServes().depositsTasks);
    super.onInit();
  }
}
