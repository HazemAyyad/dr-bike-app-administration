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
  final person = Rxn<SalesReturnPerson>();
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final personType = 'customer'.obs;
  final search = ''.obs;
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

  double get total =>
      selected.values.fold(0, (sum, row) => sum + row.lineTotal);

  @override
  void onInit() {
    super.onInit();
    loadPeople();
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
    person.value = value;
    selected.clear();
    isLoading.value = true;
    try {
      items.assignAll(await api.availableItems(value));
      Get.toNamed(AppRoutes.SALESRETURNPRODUCTPICKER);
    } catch (error) {
      _error(error);
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
      {required double cashRefund, required String note}) async {
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
      final result = await api.create({
        'person_type': currentPerson.type,
        'person_id': currentPerson.id,
        'cash_refund_amount': cashRefund,
        'note': note.trim(),
        'items': selected.values.map((row) => row.toRequest()).toList(),
      });
      final returnData = result['sales_return'] as Map?;
      final serial = returnData?['serial_number'] ?? '';
      Get.offAllNamed(AppRoutes.SALESSCREEN);
      Get.snackbar(
          'تم إنشاء المرتجع',
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

  void _error(Object error) => Get.snackbar(
      'تعذر تنفيذ العملية', error.toString().replaceFirst('Exception: ', ''));
  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
