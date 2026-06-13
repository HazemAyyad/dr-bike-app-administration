import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../data/models/suspended_instant_sale_model.dart';
import '../../data/repositories/sales_implement.dart';
import '../widgets/suspended_invoice_dialog.dart';
import 'sales_controller.dart';

class SuspendedInvoicesController extends GetxController {
  final SalesImplement salesRepository = Get.find<SalesImplement>();

  final RxBool isLoading = false.obs;
  final RxList<SuspendedInstantSaleModel> items =
      <SuspendedInstantSaleModel>[].obs;
  final TextEditingController searchController = TextEditingController();

  bool get isAdmin => userType == 'admin';

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadItems() async {
    isLoading(true);
    try {
      final list = await salesRepository.getSuspendedInstantSales(
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
      );
      items.assignAll(list);
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().loadSuspendedInvoicesCount();
      }
    } catch (e) {
      items.clear();
      final ctx = Get.context;
      if (ctx != null) {
        Helpers.showCustomDialogError(
          context: ctx,
          title: 'error'.tr,
          message: e.toString(),
        );
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> resumeItem(SuspendedInstantSaleModel item) async {
    if (!Get.isRegistered<SalesController>()) return;

    isLoading(true);
    try {
      final sales = Get.find<SalesController>();
      await sales.resumeSuspendedInstantSale(item);
    } finally {
      isLoading(false);
    }
  }

  Future<void> cancelItem(
    BuildContext context,
    SuspendedInstantSaleModel item,
  ) async {
    final confirmed = await SuspendedInvoiceDialog.showConfirm(
      context: context,
      titleKey: 'suspendedInvoiceCancelTitle',
      messageKey: 'suspendedInvoiceCancelMessage',
    );
    if (confirmed != true) return;

    isLoading(true);
    try {
      final result = await salesRepository.cancelSuspendedInstantSale(
        suspendedInstantSaleId: item.id,
      );
      await result.fold(
        (failure) async {
          if (!context.mounted) return;
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: failure.errMessage,
          );
        },
        (message) async {
          await loadItems();
          if (!context.mounted) return;
          Helpers.showCustomDialogSuccess(
            context: context,
            title: 'success'.tr,
            message: message,
          );
        },
      );
    } finally {
      isLoading(false);
    }
  }
}
