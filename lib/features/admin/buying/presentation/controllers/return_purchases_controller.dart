import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../data/models/return_purchases_models/return_products_model.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/purchase_workflow_usecase.dart';
import '../../domain/usecases/return_purchases_usecases/change_return_to_delivered_usecase.dart';

class ReturnPurchasesController extends GetxController {
  ReturnPurchasesController({
    required this.getBillsUsecase,
    required this.changeReturnToDeliveredUsecase,
    required this.purchaseWorkflowUsecase,
  });

  final GetBillsUsecase getBillsUsecase;
  final ChangeReturnToDeliveredUsecase changeReturnToDeliveredUsecase;
  final PurchaseWorkflowUsecase purchaseWorkflowUsecase;

  final tabs = const [
    'مسودات',
    'بانتظار التسليم',
    'بانتظار التسوية',
    'مكتملة',
    'ملغاة'
  ];
  final statuses = const [
    'draft',
    'confirmed',
    'delivered',
    'settled',
    'cancelled'
  ];
  final currentTab = 0.obs;
  final isLoading = false.obs;
  final movedToDelivered = false.obs;
  final search = ''.obs;
  final allReturns = <ReturnProduct>[].obs;
  final returnableBills = <Map<String, dynamic>>[].obs;
  final availableItems = <PurchaseReturnDraftLine>[].obs;
  final selectedBill = Rxn<Map<String, dynamic>>();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();

  // Kept for the existing list widget while the new five-state tabs use one source.
  final returnPurchasesSearch = <String, List<ReturnProduct>>{}.obs;
  final deliveredPurchasesSearch = <String, List<ReturnProduct>>{}.obs;

  void changeTab(int index) {
    currentTab.value = index;
    _rebuildGroups();
    update();
  }

  Future<void> getReturnBills() async {
    isLoading.value = true;
    update();
    try {
      final response = asMap(await purchaseWorkflowUsecase.purchaseReturns());
      final envelope = asMap(response['purchase_returns']);
      allReturns.assignAll(mapList(
        envelope['data'],
        (Map<String, dynamic> row) => ReturnProduct.fromJson(row),
      ));
      _rebuildGroups();
    } catch (_) {
      allReturns.clear();
      _rebuildGroups();
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> loadReturnableBills() async {
    isLoading.value = true;
    update();
    try {
      final response =
          asMap(await purchaseWorkflowUsecase.returnablePurchaseBills());
      returnableBills.assignAll(mapList(response['bills'], (m) => m));
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> selectBill(Map<String, dynamic>? bill) async {
    selectedBill.value = bill;
    availableItems.clear();
    if (bill == null) return;
    isLoading.value = true;
    update();
    try {
      final response = asMap(await purchaseWorkflowUsecase
          .purchaseReturnAvailableItems(asString(bill['id'])));
      availableItems.assignAll(mapList(
        response['items'],
        (m) => PurchaseReturnDraftLine.fromJson(m),
      ));
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> saveDraft(BuildContext context, {bool confirm = false}) async {
    final bill = selectedBill.value;
    final lines = availableItems.where((line) => line.quantity > 0).toList();
    if (bill == null || lines.isEmpty) {
      Helpers.showCustomDialogError(
          context: context,
          title: 'تنبيه',
          message: 'اختر فاتورة وكمية لصنف واحد على الأقل');
      return false;
    }
    isLoading.value = true;
    update();
    try {
      final result = asMap(await purchaseWorkflowUsecase.createReturnDraft(
        billId: asString(bill['id']),
        items: lines.map((line) => line.toRequest()).toList(),
        reason: reasonController.text.trim(),
        notes: notesController.text.trim(),
      ));
      final row = asMap(result['purchase_return']);
      if (confirm) {
        await purchaseWorkflowUsecase.runPurchaseReturnAction(
            returnId: asString(row['id']), action: 'confirm');
      }
      await getReturnBills();
      if (!context.mounted) return true;
      Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: confirm
              ? 'تم اعتماد المرتجع وإخراجه من المخزون'
              : 'تم حفظ المسودة');
      return true;
    } catch (error) {
      if (!context.mounted) return false;
      Helpers.showCustomDialogError(
          context: context, title: 'تعذر الحفظ', message: error.toString());
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> runAction(BuildContext context, ReturnProduct row, String action,
      {Map<String, dynamic> data = const {}}) async {
    isLoading.value = true;
    update();
    try {
      await purchaseWorkflowUsecase.runPurchaseReturnAction(
          returnId: row.id.toString(), action: action, data: data);
      await getReturnBills();
      if (Get.isDialogOpen == true) Get.back();
      if (!context.mounted) return;
      Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: 'تم تنفيذ العملية بنجاح');
    } catch (error) {
      if (!context.mounted) return;
      Helpers.showCustomDialogError(
          context: context,
          title: 'تعذر تنفيذ العملية',
          message: error.toString());
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void changeReturnToDelivered(
      {required BuildContext context, required String returnPurchaseId}) {
    final row = allReturns
        .firstWhereOrNull((item) => item.id.toString() == returnPurchaseId);
    if (row != null) runAction(context, row, 'deliver');
  }

  void searchBar(String value) {
    search.value = value.trim().toLowerCase();
    _rebuildGroups();
    update();
  }

  void _rebuildGroups() {
    final status = statuses[currentTab.value];
    final rows = allReturns.where((row) {
      final matchesStatus = row.status == status ||
          (status == 'confirmed' && row.status == 'pending');
      final query = search.value;
      return matchesStatus &&
          (query.isEmpty ||
              row.number.toLowerCase().contains(query) ||
              row.billId.contains(query) ||
              row.seller.name.toLowerCase().contains(query));
    }).toList();
    final grouped = <String, List<ReturnProduct>>{};
    for (final row in rows) {
      final key = DateFormat('yyyy-MM-dd').format(row.createdAt);
      grouped.putIfAbsent(key, () => []).add(row);
    }
    returnPurchasesSearch.assignAll(grouped);
    deliveredPurchasesSearch.assignAll(grouped);
  }

  @override
  void onInit() {
    super.onInit();
    getReturnBills();
  }

  @override
  void onClose() {
    reasonController.dispose();
    notesController.dispose();
    for (final line in availableItems) {
      line.dispose();
    }
    super.onClose();
  }
}

class PurchaseReturnDraftLine {
  PurchaseReturnDraftLine(
      {required this.billItemId,
      required this.productName,
      required this.variant,
      required this.available,
      required this.unitPrice});
  final int billItemId;
  final String productName;
  final String variant;
  final double available;
  final double unitPrice;
  final quantityController = TextEditingController(text: '0');
  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get total => quantity * unitPrice;
  factory PurchaseReturnDraftLine.fromJson(Map<String, dynamic> json) =>
      PurchaseReturnDraftLine(
        billItemId: asInt(json['bill_item_id']),
        productName: asString(json['product_name']),
        variant: [asString(json['size_label']), asString(json['color_label'])]
            .where((v) => v.isNotEmpty)
            .join(' / '),
        available: asDouble(json['available_quantity']),
        unitPrice: asDouble(json['unit_price']),
      );
  Map<String, dynamic> toRequest() =>
      {'bill_item_id': billItemId, 'quantity': quantity};
  void dispose() => quantityController.dispose();
}
