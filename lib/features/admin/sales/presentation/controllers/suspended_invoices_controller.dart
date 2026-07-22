import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../data/models/suspended_instant_sale_model.dart';
import '../../data/repositories/sales_implement.dart';
import '../widgets/suspended_invoice_dialog.dart';
import 'sales_controller.dart';

void _suspendedInvoiceDebug(String message, [Object? details]) {
  assert(() {
    debugPrint(
      details == null
          ? '[InstantSaleDebug][SuspendedInvoices] $message'
          : '[InstantSaleDebug][SuspendedInvoices] $message | $details',
    );
    return true;
  }());
}

void _suspendedInstantSaleDebug(String message, [Object? details]) {
  assert(() {
    debugPrint(
      details == null
          ? '[SuspendedInstantSaleDebug][SuspendedInvoices] $message'
          : '[SuspendedInstantSaleDebug][SuspendedInvoices] $message | $details',
    );
    return true;
  }());
}

List<Map<String, dynamic>> _suspendedPayloadLinesDebugSnapshot(
  Map<String, dynamic> payload,
) {
  final rows = <Map<String, dynamic>>[];
  void addLine(Map<String, dynamic> line) {
    rows.add({
      'product_id': line['product_id'],
      'product_name': line['product_name'],
      'product_image': line['product_image'],
      'image_url': line['image_url'],
      'size_color_id': line['size_color_id'],
      'size_id': line['size_id'],
      'size_label': line['size_label'],
      'color_label': line['color_label'],
      'quantity': line['quantity'],
      'cost': line['cost'],
      'type': line['type'],
      'project_id': line['project_id'],
    });
  }

  if (payload['product_id'] != null) {
    addLine({
      'product_id': payload['product_id'],
      'product_name': payload['product_name'],
      'product_image': payload['product_image'],
      'image_url': payload['image_url'],
      'size_color_id': payload['size_color_id'],
      'size_id': payload['size_id'],
      'size_label': payload['size_label'],
      'color_label': payload['color_label'],
      'quantity': payload['quantity'],
      'cost': payload['cost'],
      'type': payload['type'],
      'project_id': payload['project_id'],
    });
  }
  final otherProducts = payload['other_products'];
  if (otherProducts is List) {
    for (final raw in otherProducts) {
      if (raw is Map) addLine(Map<String, dynamic>.from(raw));
    }
  }
  return rows;
}

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
      _suspendedInvoiceDebug('load requested', {
        'search': searchController.text.trim(),
        'isAdmin': isAdmin,
      });
      final list = await salesRepository.getSuspendedInstantSales(
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
      );
      _suspendedInvoiceDebug('load success', {'count': list.length});
      _suspendedInstantSaleDebug('load success', {
        'count': list.length,
        'items': list
            .map((item) => {
                  'id': item.id,
                  'referenceCode': item.referenceCode,
                  'currentStep': item.currentStep,
                  'summaryLabel': item.summaryLabel,
                  'payloadLines':
                      _suspendedPayloadLinesDebugSnapshot(item.payload),
                })
            .toList(),
      });
      items.assignAll(list);
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().loadSuspendedInvoicesCount();
      }
    } catch (e) {
      _suspendedInvoiceDebug('load failed', e);
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
      _suspendedInvoiceDebug('resume item requested', {
        'id': item.id,
        'currentStep': item.currentStep,
        'payloadKeys': item.payload.keys.toList(),
      });
      _suspendedInstantSaleDebug('resume item requested', {
        'id': item.id,
        'referenceCode': item.referenceCode,
        'currentStep': item.currentStep,
        'summaryLabel': item.summaryLabel,
        'payloadKeys': item.payload.keys.toList(),
        'payloadLines': _suspendedPayloadLinesDebugSnapshot(item.payload),
        'rawOtherProducts': item.payload['other_products'],
      });
      final sales = Get.find<SalesController>();
      await sales.resumeSuspendedInstantSale(item);
      _suspendedInvoiceDebug('resume item finished', item.id);
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
      _suspendedInvoiceDebug('cancel item requested', {'id': item.id});
      final result = await salesRepository.cancelSuspendedInstantSale(
        suspendedInstantSaleId: item.id,
      );
      await result.fold(
        (failure) async {
          _suspendedInvoiceDebug('cancel item failed', {
            'message': failure.errMessage,
            'data': failure.data,
          });
          if (!context.mounted) return;
          Helpers.showCustomDialogError(
            context: context,
            title: 'error'.tr,
            message: failure.errMessage,
          );
        },
        (message) async {
          _suspendedInvoiceDebug('cancel item success', message);
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

  Future<void> openNotesDialog(
    BuildContext context,
    SuspendedInstantSaleModel item,
  ) async {
    final note = await SuspendedInvoiceDialog.showNotes(
      context: context,
    );
    if (note == null || note.trim().isEmpty) return;

    isLoading(true);
    try {
      final result = await salesRepository.addSuspendedInstantSaleNote(
        suspendedInstantSaleId: item.id,
        note: note,
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
        (updated) async {
          final index = items.indexWhere((row) => row.id == updated.id);
          if (index >= 0) {
            items[index] = updated;
          } else {
            await loadItems();
          }
        },
      );
    } finally {
      isLoading(false);
    }
  }
}
