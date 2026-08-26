import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../data/models/return_purchases_models/return_products_model.dart';
import '../../domain/usecases/get_bills_usecase.dart';
import '../../domain/usecases/purchase_workflow_usecase.dart';
import '../../domain/usecases/return_purchases_usecases/change_return_to_delivered_usecase.dart';
import 'bills_controller.dart';
import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';

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
  final isSearchVisible = false.obs;
  final searchController = TextEditingController();
  final allReturns = <ReturnProduct>[].obs;
  final returnableBills = <Map<String, dynamic>>[].obs;
  final availableItems = <PurchaseReturnDraftLine>[].obs;
  final selectedBill = Rxn<Map<String, dynamic>>();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  final pendingAttachments = <PlatformFile>[].obs;
  final returnDetails = <String, dynamic>{}.obs;
  final detailsLoading = false.obs;

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
      final returnId = asString(row['id']);
      if (pendingAttachments.isNotEmpty) {
        await _uploadFiles(returnId, pendingAttachments);
      }
      if (confirm) {
        await purchaseWorkflowUsecase.runPurchaseReturnAction(
            returnId: returnId, action: 'confirm');
      }
      await getReturnBills();
      if (!context.mounted) return true;
      Navigator.of(context).pop();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      Get.back();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      _showSaveSuccess(confirm);
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

  Future<void> pickAttachments() async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.any, withData: false);
    if (result == null) return;
    pendingAttachments
        .assignAll(result.files.where((file) => file.path != null).take(10));
    update();
  }

  void setPendingAttachmentFiles(List<File> files) {
    pendingAttachments.assignAll(files.take(10).map((file) => PlatformFile(
          name: file.path.split(Platform.pathSeparator).last,
          path: file.path,
          size: file.lengthSync(),
        )));
    update();
  }

  Future<File?> captureReturnMedia() async {
    final result = await Get.to<WhatsAppCapture>(
        () => const WhatsAppCameraScreen(),
        fullscreenDialog: true);
    return result == null ? null : File(result.path);
  }

  void removePendingAttachment(PlatformFile file) {
    pendingAttachments.remove(file);
    update();
  }

  Future<void> _uploadFiles(String returnId, List<PlatformFile> files) async {
    final multipart = <dio.MultipartFile>[];
    for (final file in files) {
      if (file.path == null) continue;
      multipart.add(
          await dio.MultipartFile.fromFile(file.path!, filename: file.name));
    }
    if (multipart.isNotEmpty) {
      await purchaseWorkflowUsecase.uploadReturnAttachments(
          returnId, multipart);
    }
    pendingAttachments.clear();
  }

  Future<void> loadReturnDetails(String returnId) async {
    returnDetails.clear();
    detailsLoading.value = true;
    update();
    try {
      returnDetails.assignAll(
          asMap(await purchaseWorkflowUsecase.purchaseReturnDetails(returnId)));
    } finally {
      detailsLoading.value = false;
      update();
    }
  }

  Future<void> addDetailsAttachments(
      BuildContext context, String returnId) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.any, withData: false);
    if (result == null || result.files.isEmpty) return;
    isLoading.value = true;
    update();
    try {
      await _uploadFiles(returnId,
          result.files.where((file) => file.path != null).take(10).toList());
      await loadReturnDetails(returnId);
      if (context.mounted) {
        Helpers.showCustomDialogSuccess(
            context: context, title: 'success'.tr, message: 'تم رفع المرفقات');
      }
    } catch (error) {
      if (context.mounted) {
        Helpers.showCustomDialogError(
            context: context, title: 'تعذر الرفع', message: error.toString());
      }
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> uploadDetailsFiles(
      BuildContext context, String returnId, List<File> files) async {
    if (files.isEmpty) return;
    isLoading.value = true;
    update();
    try {
      final selected = files
          .take(10)
          .map((file) => PlatformFile(
                name: file.path.split(Platform.pathSeparator).last,
                path: file.path,
                size: file.lengthSync(),
              ))
          .toList();
      await _uploadFiles(returnId, selected);
      await loadReturnDetails(returnId);
      if (context.mounted) {
        Helpers.showCustomDialogSuccess(
            context: context, title: 'success'.tr, message: 'تم رفع المرفقات');
      }
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> downloadPdf(String returnId, String number) async {
    final bytes = await purchaseWorkflowUsecase.downloadReturnPdf(returnId);
    final base = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download/Doctor Bike/PDF')
        : Directory(
            '${(await getApplicationDocumentsDirectory()).path}/Doctor Bike/PDF');
    if (!await base.exists()) await base.create(recursive: true);
    final file = File('${base.path}/مرتجع_$number.pdf');
    await file.writeAsBytes(bytes);
    Get.snackbar('success'.tr, 'تم تنزيل ملف المرتجع');
    await OpenFilex.open(file.path);
  }

  void _showSaveSuccess(bool confirm) {
    final currentContext = Get.context;
    if (currentContext == null) return;
    Helpers.showCustomDialogSuccess(
        context: currentContext,
        title: 'success'.tr,
        message: confirm
            ? 'تم اعتماد المرتجع وإخراجه من المخزون'
            : 'تم حفظ المسودة');
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

  void showSettlementDialog(BuildContext context, ReturnProduct row) {
    final billsController = Get.find<BillsController>();
    billsController.loadPurchaseBoxes();
    final amount = TextEditingController(
        text: ((double.tryParse(row.total) ?? 0) -
                (double.tryParse(row.settledAmount) ?? 0))
            .toStringAsFixed(2));
    final billId = TextEditingController();
    var type = 'cash_refund';
    dynamic box;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text('تسوية ${row.number}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'طريقة التسوية', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'cash_refund', child: Text('استرداد نقدي')),
                  DropdownMenuItem(
                      value: 'bill_allocation', child: Text('خصم من فاتورة')),
                ],
                onChanged: (value) => setState(() => type = value!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'المبلغ (${row.currency})',
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              if (type == 'cash_refund')
                Obx(() => DropdownButtonFormField<dynamic>(
                      initialValue: box,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'الصندوق', border: OutlineInputBorder()),
                      items: billsController.purchaseBoxes
                          .map((item) => DropdownMenuItem(
                              value: item,
                              child:
                                  Text('${item.boxName} (${item.currency})')))
                          .toList(),
                      onChanged: (value) => setState(() => box = value),
                    )),
              if (type == 'bill_allocation')
                TextField(
                  controller: billId,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'رقم فاتورة الشراء المفتوحة',
                      border: OutlineInputBorder()),
                ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final data = <String, dynamic>{
                  'type': type,
                  'amount': amount.text.trim(),
                };
                if (type == 'cash_refund') {
                  data['box_id'] = box?.id;
                } else {
                  data['bill_id'] = billId.text.trim();
                }
                Navigator.pop(dialogContext);
                runAction(context, row, 'settle', data: data);
              },
              child: const Text('تسجيل التسوية'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      amount.dispose();
      billId.dispose();
    });
  }

  void searchBar(String value) {
    search.value = value.trim().toLowerCase();
    _rebuildGroups();
    update();
  }

  void toggleSearch() {
    isSearchVisible.toggle();
    if (!isSearchVisible.value) closeSearch();
    update();
  }

  void closeSearch() {
    searchController.clear();
    searchBar('');
    isSearchVisible.value = false;
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
    searchController.dispose();
    for (final line in availableItems) {
      line.dispose();
    }
    pendingAttachments.clear();
    super.onClose();
  }
}

class PurchaseReturnDraftLine {
  PurchaseReturnDraftLine(
      {required this.billItemId,
      required this.productName,
      required this.variant,
      required this.available,
      required this.unitPrice,
      required this.productImage});
  final int billItemId;
  final String productName;
  final String variant;
  final double available;
  final double unitPrice;
  final String productImage;
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
        productImage:
            ShowNetImage.getPhoto(asNullableString(json['product_image'])),
      );
  Map<String, dynamic> toRequest() =>
      {'bill_item_id': billItemId, 'quantity': quantity};
  void dispose() => quantityController.dispose();
}
