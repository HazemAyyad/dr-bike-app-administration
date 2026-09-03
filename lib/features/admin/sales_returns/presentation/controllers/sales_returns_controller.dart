import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/sales_return_models.dart';
import '../../data/sales_returns_api_service.dart';

class SalesReturnsController extends GetxController {
  SalesReturnsController(this.api);
  final SalesReturnsApiService api;
  final people = <SalesReturnPerson>[].obs;
  final items = <SalesReturnAvailableItem>[].obs;
  final selected = <String, SalesReturnAvailableItem>{}.obs;
  final returns = <SalesReturnRecord>[].obs;
  final person = Rxn<SalesReturnPerson>();
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isReturnsLoading = false.obs;
  final returnsSearch = ''.obs;
  final personType = 'customer'.obs;
  final search = ''.obs;
  final editingReturnId = RxnInt();
  final editCashRefund = 0.0.obs;
  final editNote = ''.obs;
  Timer? _debounce;

  List<SalesReturnPerson> get visiblePeople {
    final query = search.value.trim().toLowerCase();
    return people
        .where((row) => row.type == personType.value)
        .where((row) =>
            query.isEmpty ||
            row.name.toLowerCase().contains(query) ||
            row.phone.contains(query))
        .toList();
  }

  List<SalesReturnAvailableItem> filteredItems(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return items;
    return items
        .where((row) =>
            row.productName.toLowerCase().contains(value) ||
            row.productCode.toLowerCase().contains(value) ||
            row.invoiceSerial.toLowerCase().contains(value))
        .toList();
  }

  List<SalesReturnInvoiceGroup> filteredInvoices(String query) {
    final value = query.trim().toLowerCase();
    final grouped = <String, List<SalesReturnAvailableItem>>{};
    for (final item in items) {
      final key = '${item.sourceType}:${item.invoiceId}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final invoices = grouped.values.map((lines) {
      final first = lines.first;
      return SalesReturnInvoiceGroup(
        sourceType: first.sourceType,
        invoiceId: first.invoiceId,
        invoiceSerial: first.invoiceSerial,
        invoiceDate: first.invoiceDate,
        items: lines,
      );
    }).where((invoice) {
      if (value.isEmpty) return true;
      return invoice.invoiceSerial.toLowerCase().contains(value) ||
          invoice.sourceLabel.toLowerCase().contains(value) ||
          invoice.items.any((item) =>
              item.productName.toLowerCase().contains(value) ||
              item.productCode.toLowerCase().contains(value));
    }).toList();
    invoices.sort((first, second) {
      final firstDate = DateTime.tryParse(first.invoiceDate);
      final secondDate = DateTime.tryParse(second.invoiceDate);
      if (firstDate != null && secondDate != null) {
        return secondDate.compareTo(firstDate);
      }
      return second.invoiceId.compareTo(first.invoiceId);
    });
    return invoices;
  }

  List<SalesReturnRecord> get visibleReturns {
    final query = returnsSearch.value.trim().toLowerCase();
    if (query.isEmpty) return returns;
    return returns
        .where((row) =>
            row.serialNumber.toLowerCase().contains(query) ||
            row.partnerName.toLowerCase().contains(query) ||
            row.partnerPhone.contains(query))
        .toList();
  }

  double get total =>
      selected.values.fold(0, (sum, row) => sum + row.lineTotal);

  @override
  void onInit() {
    super.onInit();
    loadPeople();
    loadReturns();
  }

  Future<void> loadReturns() async {
    isReturnsLoading.value = true;
    try {
      returns.assignAll(await api.list());
    } catch (error) {
      _error(error);
    } finally {
      isReturnsLoading.value = false;
    }
  }

  Future<SalesReturnRecord?> loadReturnDetails(int id) async {
    try {
      return await api.show(id);
    } catch (error) {
      _error(error);
      return null;
    }
  }

  Future<void> loadPeople() async {
    isLoading.value = true;
    try {
      people.assignAll(await api.people());
    } catch (error) {
      _error(error);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length >= 2) {
        try {
          people.assignAll(await api.people(search: value));
        } catch (_) {}
      }
    });
  }

  Future<void> choosePerson(SalesReturnPerson value) async {
    clearEdit();
    final loaded = await changePerson(value);
    if (loaded) {
      Get.toNamed(AppRoutes.SALESRETURNPRODUCTPICKER);
    }
  }

  Future<bool> changePerson(SalesReturnPerson value) async {
    isLoading.value = true;
    try {
      final loadedItems = await api.availableItems(value);
      person.value = value;
      selected.clear();
      items.assignAll(loadedItems);
      return true;
    } catch (error) {
      _error(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void toggle(SalesReturnAvailableItem item) {
    if (selected.containsKey(item.key)) {
      selected.remove(item.key);
    } else {
      item.quantity = 1;
      item.unitPrice = item.originalUnitPrice;
      selected[item.key] = item;
    }
    selected.refresh();
  }

  void changeQuantity(SalesReturnAvailableItem item, int value) {
    item.quantity = value.clamp(1, item.availableQuantity);
    selected[item.key] = item;
    selected.refresh();
  }

  void goToCheckout() {
    if (selected.isEmpty) {
      Get.snackbar('تنبيه', 'اختر منتجًا واحدًا على الأقل.');
      return;
    }
    Get.toNamed(AppRoutes.SALESRETURNCHECKOUT);
  }

  Future<void> submit(
      {required double cashRefund,
      required String note,
      String editReason = ''}) async {
    final currentPerson = person.value;
    if (currentPerson == null || isSubmitting.value) return;
    if (cashRefund < 0 || cashRefund > total + 0.001) {
      Get.snackbar('تنبيه', 'المبلغ النقدي يجب ألا يتجاوز إجمالي المرتجع.');
      return;
    }
    if (selected.values.any((row) =>
        row.priceWasChanged && row.priceOverrideReason.trim().isEmpty)) {
      Get.snackbar('تنبيه', 'اكتب سبب تعديل السعر لكل صنف تم تغيير سعره.');
      return;
    }
    isSubmitting.value = true;
    try {
      final payload = <String, dynamic>{
        'person_type': currentPerson.type,
        'person_id': currentPerson.id,
        'cash_refund_amount': cashRefund,
        'note': note.trim(),
        'items': selected.values.map((row) => row.toRequest()).toList(),
      };
      final currentEditId = editingReturnId.value;
      if (currentEditId != null) {
        if (editReason.trim().length < 3) {
          Get.snackbar('تنبيه', 'اكتب سبب تعديل المرتجع.');
          return;
        }
        payload['sales_return_id'] = currentEditId;
        payload['edit_reason'] = editReason.trim();
      }
      final result = currentEditId == null
          ? await api.create(payload)
          : await api.update(payload);
      final returnData = result['sales_return'] as Map?;
      final serial = returnData?['serial_number'] ?? '';
      clearEdit();
      Get.offAllNamed(
        AppRoutes.SALESSCREEN,
        arguments: {'salesTab': 3},
      );
      Get.snackbar(
          currentEditId == null ? 'تم إنشاء المرتجع' : 'تم تعديل المرتجع',
          serial.toString().isEmpty
              ? 'تمت إعادة المخزون وتسجيل التسوية بنجاح.'
              : 'تم إنشاء الفاتورة $serial وإتمام التسوية.',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white);
    } catch (error) {
      _error(error);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> startEdit(SalesReturnRecord record) async {
    if (record.isCancelled || isLoading.value) return;
    isLoading.value = true;
    try {
      final selectedPerson = SalesReturnPerson(
        id: record.partnerId,
        type: record.partnerType,
        name: record.partnerName,
        phone: record.partnerPhone,
      );
      final available = await api.availableItems(selectedPerson);
      final byKey = {for (final item in available) item.key: item};
      selected.clear();
      for (final oldItem in record.items) {
        final key = '${oldItem.sourceType}:${oldItem.sourceItemId}';
        var item = byKey[key];
        if (item == null) {
          final invoice = oldItem.saleInvoice;
          item = SalesReturnAvailableItem(
            sourceType: oldItem.sourceType,
            sourceItemId: oldItem.sourceItemId,
            invoiceId: invoice?.id ?? 0,
            invoiceSerial: invoice?.serial ?? '-',
            invoiceDate: invoice?.date ?? '',
            productId: oldItem.productId,
            productCode: oldItem.productCode,
            productName: oldItem.productName,
            image: oldItem.productImage,
            sizeLabel: oldItem.sizeLabel,
            colorLabel: oldItem.colorLabel,
            soldQuantity: invoice?.soldQuantity ?? oldItem.quantity,
            returnedQuantity:
                ((invoice?.soldQuantity ?? oldItem.quantity) - oldItem.quantity)
                    .clamp(0, 1 << 30),
            availableQuantity: oldItem.quantity,
            originalUnitPrice: oldItem.originalUnitPrice,
          );
          available.add(item);
          byKey[key] = item;
        } else {
          item.availableQuantity += oldItem.quantity;
          item.returnedQuantity =
              (item.returnedQuantity - oldItem.quantity).clamp(0, 1 << 30);
        }
        item.quantity = oldItem.quantity;
        item.unitPrice = oldItem.unitPrice;
        item.priceOverrideReason = oldItem.priceOverrideReason;
        selected[key] = item;
      }
      person.value = selectedPerson;
      personType.value = selectedPerson.type;
      items.assignAll(available);
      selected.refresh();
      editingReturnId.value = record.id;
      editCashRefund.value = record.cashRefundAmount;
      editNote.value = record.note;
      Get.back();
      await Get.toNamed(AppRoutes.SALESRETURNPRODUCTPICKER);
    } catch (error) {
      _error(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelReturn(int id, String reason) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      await api.cancel(id: id, reason: reason);
      await loadReturns();
      Get.snackbar(
        'تم إلغاء المرتجع',
        'تم عكس المخزون والنقد ورصيد الطرف بنجاح.',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      return true;
    } catch (error) {
      _error(error);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearEdit() {
    editingReturnId.value = null;
    editCashRefund.value = 0;
    editNote.value = '';
  }

  void _error(Object error) => Get.snackbar(
      'تعذر تنفيذ العملية', error.toString().replaceFirst('Exception: ', ''));
  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
