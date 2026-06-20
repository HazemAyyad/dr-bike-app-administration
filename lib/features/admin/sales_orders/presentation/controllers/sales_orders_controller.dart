import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:doctorbike/core/errors/failure.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/helpers/media_permissions.dart';
import '../../../../../routes/app_routes.dart';

import '../../data/models/sales_order_model.dart';
import '../../data/repositories/sales_orders_implement.dart';
import '../../../payment_method/presentation/controllers/payment_controller.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/utils/sales_amount_format.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../widgets/sales_order_media_source_sheet.dart';
import '../widgets/sales_order_media_category_sheet.dart';
import '../widgets/sales_order_share_sheet.dart';
import '../widgets/sales_order_notice.dart';

class SalesOrderCartItem {
  SalesOrderCartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.sizeId,
    this.sizeColorId,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final int? sizeId;
  final int? sizeColorId;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        if (sizeId != null) 'size_id': sizeId,
        if (sizeColorId != null) 'size_color_id': sizeColorId,
      };
}

class ShiplyPartnerSelection {
  const ShiplyPartnerSelection({
    required this.partner,
    required this.isCustomer,
  });

  final SellerModel partner;
  final bool isCustomer;
}

class SalesOrdersController extends GetxController {
  SalesOrdersController({required this.repository});

  final SalesOrdersRepository repository;

  static const surfaceGray = Color(0xFFF5F6F8);
  static const cardGray = Color(0xFFF9FAFB);
  static const borderGray = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  final isLoading = false.obs;
  final isDetailLoading = false.obs;
  final isSubmitting = false.obs;
  final isPreparingEdit = false.obs;
  final orders = <SalesOrderListItemModel>[].obs;
  final statusFilter = 'unconfirmed'.obs;
  final detail = Rxn<SalesOrderDetailModel>();
  final cities = <CityModel>[].obs;
  final shiplyCities = <ShiplyCityModel>[].obs;
  final shiplyIsSandboxMode = false.obs;
  final deliveryCompanies = <DeliveryCompanyModel>[].obs;
  final shiplyCustomers = <SellerModel>[].obs;
  final shiplySellers = <SellerModel>[].obs;
  final shiplyPartnerIsCustomer = true.obs;
  final cartItems = <SalesOrderCartItem>[].obs;

  ShiplyPartnerSelection? pendingShiplyPartner;

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final customerAddressController = TextEditingController();
  final deliveryFeeController = TextEditingController(text: '0');
  final trackingController = TextEditingController();
  final carrierContactNameController = TextEditingController();
  final carrierContactPhoneController = TextEditingController();
  final carrierOfficeNameController = TextEditingController();
  final carrierVehicleNumberController = TextEditingController();
  final settleAmountController = TextEditingController();
  final settleBoxIdController = TextEditingController();
  final notesController = TextEditingController();

  final bulkMode = false.obs;
  final selectedOrderIds = <int>{}.obs;

  final selectedCityId = RxnInt();
  final selectedShiplyCityId = RxnInt();
  final selectedShiplyVillageId = RxnInt();
  final manualDeliveryFee = 0.0.obs;
  final shiplyQuotedDeliveryFee = RxnDouble();
  final selectedPaymentType = 'cash'.obs;
  final selectedDeliveryCompanyId = RxnInt();
  final hasSuspendedDraft = false.obs;
  final activeEditSalesOrderId = RxnInt();

  bool get isEditingOrder => activeEditSalesOrderId.value != null;

  double get selectedCityDeliveryFee => manualDeliveryFee.value;

  List<ShiplyVillageModel> get selectedShiplyVillages {
    final cityId = selectedShiplyCityId.value;
    if (cityId == null) return const [];
    for (final city in shiplyCities) {
      if (city.id == cityId) return city.villages;
    }
    return const [];
  }

  bool get isSelectedCompanyShiply => _selectedCompanyCode == 'shiply';

  bool get isSelectedCompanyTaxi => _selectedCompanyCode == 'taxi';

  bool get isSelectedCompanyOffice => _selectedCompanyCode == 'office';

  bool get isSelectedCompanyDoctorBike => _selectedCompanyCode == 'doctor_bike';

  bool get isSelectedCompanyManualCarrier =>
      isSelectedCompanyTaxi || isSelectedCompanyOffice;

  bool get isSelectedCompanySelfDelivery => isSelectedCompanyDoctorBike;

  String? get _selectedCompanyCode {
    final id = selectedDeliveryCompanyId.value;
    for (final company in deliveryCompanies) {
      if (company.id == id) {
        return company.code?.toLowerCase();
      }
    }
    return null;
  }

  DeliveryCompanyModel? get selectedDeliveryCompany {
    final id = selectedDeliveryCompanyId.value;
    for (final company in deliveryCompanies) {
      if (company.id == id) return company;
    }
    return null;
  }

  void onDeliveryCompanyChanged(int? companyId) {
    selectedDeliveryCompanyId.value = companyId;
  }

  void pickDefaultDeliveryCompany(SalesOrderDetailModel? order) {
    if (order != null) {
      pickDefaultHandoverCompany(order);
      return;
    }
    if (deliveryCompanies.isEmpty) return;
    if (shiplyDeliveryCompany != null) {
      selectedDeliveryCompanyId.value = shiplyDeliveryCompany!.id;
      return;
    }
    selectedDeliveryCompanyId.value = deliveryCompanies.first.id;
  }

  DeliveryCompanyModel? get shiplyDeliveryCompany {
    for (final company in deliveryCompanies) {
      if (company.code?.toLowerCase() == 'shiply') return company;
    }
    return null;
  }

  void pickDefaultHandoverCompany(SalesOrderDetailModel? order) {
    if (deliveryCompanies.isEmpty) return;

    if (order?.deliveryCompanyId != null) {
      final savedId = order!.deliveryCompanyId!;
      if (deliveryCompanies.any((c) => c.id == savedId)) {
        selectedDeliveryCompanyId.value = savedId;
        return;
      }
    }

    if (order != null &&
        order.isShiplyDelivery &&
        shiplyDeliveryCompany != null) {
      selectedDeliveryCompanyId.value = shiplyDeliveryCompany!.id;
      return;
    }

    final nonShiply = deliveryCompanies
        .where((c) => c.code?.toLowerCase() != 'shiply')
        .toList();
    if (nonShiply.isNotEmpty) {
      selectedDeliveryCompanyId.value = nonShiply.first.id;
      return;
    }

    selectedDeliveryCompanyId.value = deliveryCompanies.first.id;
  }

  final statusTabs = const [
    'unconfirmed',
    'confirmed',
    'ready',
    'with_delivery',
    'review',
    'delivered',
    'partial_return',
    'returned',
    'postponed',
    'stuck',
    'canceled',
    'archived',
  ];

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    loadLookups();
  }

  @override
  void onClose() {
    customerNameController.dispose();
    customerPhoneController.dispose();
    customerAddressController.dispose();
    deliveryFeeController.dispose();
    trackingController.dispose();
    carrierContactNameController.dispose();
    carrierContactPhoneController.dispose();
    carrierOfficeNameController.dispose();
    carrierVehicleNumberController.dispose();
    settleAmountController.dispose();
    settleBoxIdController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> loadLookups() async {
    final shiplyResult = await repository.getShiplyAddressOptions();
    shiplyResult.fold((_) {}, (data) {
      shiplyCities.assignAll(data.cities);
      shiplyIsSandboxMode.value = data.isTestMode;
    });
    final companiesResult = await repository.getDeliveryCompanies();
    companiesResult.fold((_) {}, (data) => deliveryCompanies.assignAll(data));
  }

  String deliveryCompanyLabel(DeliveryCompanyModel company) {
    if (company.code?.toLowerCase() == 'shiply' && shiplyIsSandboxMode.value) {
      return '${company.name} (${'shiplySandboxShort'.tr})';
    }
    return company.name;
  }

  Future<void> loadOrders() async {
    isLoading.value = true;
    final result = await repository.getOrders(status: statusFilter.value);
    result.fold(
      (_) => orders.clear(),
      (data) => orders.assignAll(data),
    );
    isLoading.value = false;
  }

  Future<void> loadDetail(int orderId) async {
    isDetailLoading.value = true;
    final result = await repository.getOrder(orderId);
    result.fold(
      (f) {
        SalesOrderNotice.error(f.errMessage);
        detail.value = null;
      },
      (data) => detail.value = data,
    );
    isDetailLoading.value = false;
  }

  void changeStatusFilter(String status) {
    statusFilter.value = status;
    if (!canBulkSelectCurrentTab) {
      toggleBulkMode(false);
    } else {
      selectedOrderIds.clear();
      selectedOrderIds.refresh();
    }
    loadOrders();
  }

  /// After a status-changing action, show the order under its new tab.
  void focusOrderStatusTab(String status) {
    if (statusTabs.contains(status)) {
      if (statusFilter.value != status) {
        changeStatusFilter(status);
      } else {
        loadOrders();
      }
      return;
    }
    loadOrders();
  }

  void addCartItem(SalesOrderCartItem item) {
    cartItems.add(item);
  }

  void removeCartItem(int index) {
    if (index >= 0 && index < cartItems.length) {
      cartItems.removeAt(index);
    }
  }

  void resetCreateForm() {
    cartItems.clear();
    customerNameController.clear();
    customerPhoneController.clear();
    customerAddressController.clear();
    deliveryFeeController.text = '0';
    notesController.clear();
    selectedCityId.value = null;
    selectedShiplyCityId.value = null;
    selectedShiplyVillageId.value = null;
    manualDeliveryFee.value = 0;
    shiplyQuotedDeliveryFee.value = null;
    selectedPaymentType.value = 'cash';
    hasSuspendedDraft.value = false;
    activeEditSalesOrderId.value = null;
  }

  void clearActiveEditSalesOrder() {
    activeEditSalesOrderId.value = null;
  }

  static bool canRevertStatus(String status) {
    return const {
      'confirmed',
      'ready',
      'with_delivery',
      'postponed',
    }.contains(status);
  }

  Future<void> revertOrderStatus(int orderId) async {
    await runAction(() => repository.revertOrder(orderId));
  }

  Future<void> openOrderInvoice(int? instantSaleId) async {
    if (instantSaleId == null) return;
    if (!Get.isRegistered<SalesController>()) return;
    await Get.find<SalesController>()
        .openInstantSaleBillDetails(instantSaleId.toString());
  }

  static bool canEditOrderStatus(String status) {
    return const {
      'unconfirmed',
      'confirmed',
      'ready',
      'postponed',
    }.contains(status);
  }

  Future<void> openEditSalesOrderFlow(SalesOrderDetailModel order) async {
    if (!canEditOrderStatus(order.status)) {
      SalesOrderNotice.error('salesOrderNotEditable'.tr);
      return;
    }

    final sales = Get.find<SalesController>();
    hasSuspendedDraft.value = false;
    activeEditSalesOrderId.value = order.id;

    customerNameController.text = order.customerName ?? '';
    customerPhoneController.text = order.customerPhone ?? '';
    customerAddressController.text = order.customerAddress ?? '';
    notesController.text = order.notes ?? '';
    selectedShiplyCityId.value = order.shiplyCityId;
    selectedShiplyVillageId.value = order.shiplyVillageId;
    deliveryFeeController.text = order.customerDeliveryFee.toStringAsFixed(0);
    manualDeliveryFee.value = order.customerDeliveryFee;
    shiplyQuotedDeliveryFee.value = order.shiplyQuotedDeliveryFee;
    selectedPaymentType.value = order.paymentType;

    isPreparingEdit.value = true;
    try {
      await sales.hydrateFromSalesOrder(order);
    } finally {
      isPreparingEdit.value = false;
    }

    await Get.toNamed(
      AppRoutes.NEWSALESORDERSCREEN,
      arguments: {'editSalesOrder': true},
    );
  }

  void suspendOrderDraft() {
    hasSuspendedDraft.value = true;
    Get.back();
    SalesOrderNotice.success('salesOrderDraftSuspended'.tr);
  }

  void suspendOrderDraftFromPicker() {
    if (!Get.isRegistered<SalesController>()) return;
    final sales = Get.find<SalesController>();
    if (sales.cartDistinctCount <= 0) return;
    hasSuspendedDraft.value = true;
    Get.back();
    SalesOrderNotice.success('salesOrderDraftSuspended'.tr);
  }

  List<Map<String, dynamic>> _itemsFromSalesCart(SalesController sales) {
    return sales.cartLines
        .where((l) => !l.isDisposed && !l.isProjectSale.value)
        .map((l) => <String, dynamic>{
              'product_id': int.tryParse(l.productId) ?? 0,
              'quantity': SalesAmountFormat.parse(l.quantityText).round(),
              'unit_price': SalesAmountFormat.parse(l.priceText),
              if (l.sizeId != null && l.sizeId!.isNotEmpty)
                'size_id': int.tryParse(l.sizeId!),
              if (l.sizeColorId != null && l.sizeColorId!.isNotEmpty)
                'size_color_id': int.tryParse(l.sizeColorId!),
              if (l.sizeLabel != null && l.sizeLabel!.isNotEmpty)
                'size_label': l.sizeLabel,
              if (l.colorLabel != null && l.colorLabel!.isNotEmpty)
                'color_label': l.colorLabel,
            })
        .where((m) => (m['product_id'] as int) > 0)
        .toList();
  }

  void onDeliveryCityChanged(int? cityId) {
    selectedCityId.value = cityId;
  }

  void onShiplyCityChanged(int? cityId) {
    selectedShiplyCityId.value = cityId;
    selectedShiplyVillageId.value = null;
    shiplyQuotedDeliveryFee.value = null;
  }

  Future<void> onShiplyVillageChanged(
    int? villageId, {
    double parcelPrice = 0,
  }) async {
    selectedShiplyVillageId.value = villageId;
    if (villageId == null) return;
    await _applyShiplyDeliveryFeeQuote(villageId, parcelPrice: parcelPrice);
  }

  Future<void> _applyShiplyDeliveryFeeQuote(
    int villageId, {
    double parcelPrice = 0,
  }) async {
    final result = await repository.calculateShiplyDeliveryFee(
      villageId: villageId,
      price: parcelPrice,
    );
    result.fold((_) {}, (fee) {
      if (fee == null) return;
      shiplyQuotedDeliveryFee.value = fee;
      deliveryFeeController.text = fee.toStringAsFixed(0);
      manualDeliveryFee.value = fee;
    });
  }

  void preloadShiplyAddressFromOrder(SalesOrderDetailModel order) {
    customerAddressController.text = order.customerAddress ?? '';
    selectedShiplyCityId.value = order.shiplyCityId;
    selectedShiplyVillageId.value = order.shiplyVillageId;
    deliveryFeeController.text = order.customerDeliveryFee.toStringAsFixed(0);
    manualDeliveryFee.value = order.customerDeliveryFee;
    shiplyQuotedDeliveryFee.value = order.shiplyQuotedDeliveryFee;
  }

  bool needsDeliveryCustomer(SalesOrderDetailModel order) =>
      needsShiplyCustomerSelection(order);

  bool needsDeliveryPhone(SalesOrderDetailModel order) =>
      needsShiplyPhone(order);

  bool needsDeliveryAddress(SalesOrderDetailModel order, {bool? forShiply}) =>
      needsShiplyAddress(order);

  bool isDeliveryHandoverReady(
    SalesOrderDetailModel order, {
    bool? forShiply,
  }) {
    return _hasShiplyRecipient(order) && !needsShiplyAddress(order);
  }

  String? validateManualHandoverFields() {
    if (isSelectedCompanyTaxi) {
      if (trackingController.text.trim().isEmpty) {
        return 'salesOrderTaxiNumberRequired'.tr;
      }
      if (carrierContactNameController.text.trim().isEmpty) {
        return 'salesOrderTaxiDriverRequired'.tr;
      }
      if (carrierContactPhoneController.text.trim().isEmpty) {
        return 'salesOrderTaxiPhoneRequired'.tr;
      }
      return null;
    }

    if (isSelectedCompanyOffice) {
      if (carrierOfficeNameController.text.trim().isEmpty) {
        return 'salesOrderOfficeNameRequired'.tr;
      }
      if (carrierContactNameController.text.trim().isEmpty) {
        return 'salesOrderOfficeDriverRequired'.tr;
      }
      if (carrierContactPhoneController.text.trim().isEmpty) {
        return 'salesOrderOfficePhoneRequired'.tr;
      }
      if (carrierVehicleNumberController.text.trim().isEmpty) {
        return 'salesOrderOfficeVehicleRequired'.tr;
      }
      return null;
    }

    return null;
  }

  Future<bool> saveDeliveryAddressForOrder(int orderId) async {
    if (customerAddressController.text.trim().isEmpty) {
      SalesOrderNotice.error('salesOrderAddressRequired'.tr);
      return false;
    }
    isSubmitting.value = true;
    final result = await repository.updateOrder(orderId, {
      'customer_address': customerAddressController.text.trim(),
    });
    isSubmitting.value = false;
    return result.fold(
      (f) {
        SalesOrderNotice.error(_humanizeFailure(f));
        return false;
      },
      (order) {
        detail.value = order;
        return true;
      },
    );
  }

  bool needsShiplyCustomerSelection(SalesOrderDetailModel order) {
    if (_hasShiplyRecipient(order)) return false;
    return order.customerId == null &&
        (order.customerName ?? '').trim().isEmpty;
  }

  bool needsShiplyPhone(SalesOrderDetailModel order) {
    if ((order.customerPhone ?? '').trim().isNotEmpty) return false;
    return (order.customerName ?? '').trim().isNotEmpty;
  }

  bool _hasShiplyRecipient(SalesOrderDetailModel order) {
    return (order.customerName ?? '').trim().isNotEmpty &&
        (order.customerPhone ?? '').trim().isNotEmpty;
  }

  bool needsShiplyAddress(SalesOrderDetailModel order) {
    return order.shiplyVillageId == null ||
        (order.customerAddress ?? '').trim().isEmpty;
  }

  bool isShiplyHandoverReady(SalesOrderDetailModel order) {
    return _hasShiplyRecipient(order) && !needsShiplyAddress(order);
  }

  Future<void> loadShiplyPartners() async {
    if (shiplyCustomers.isNotEmpty && shiplySellers.isNotEmpty) return;
    final customersResult = await repository.getCustomersList();
    customersResult.fold((_) {}, (data) => shiplyCustomers.assignAll(data));
    final sellersResult = await repository.getSellersList();
    sellersResult.fold((_) {}, (data) => shiplySellers.assignAll(data));
  }

  Map<String, dynamic> buildCustomerPayloadFromPartner(
    SellerModel partner, {
    required bool isCustomer,
  }) {
    final phone = partner.phone.trim();
    if (isCustomer) {
      return {
        'customer_id': partner.id,
        'customer_name': partner.name,
        'customer_phone': phone,
      };
    }
    return {
      'customer_name': partner.name,
      'customer_phone': phone,
    };
  }

  Future<bool> saveOrderCustomerPayload(
    int orderId,
    Map<String, dynamic> payload,
  ) async {
    isSubmitting.value = true;
    final result = await repository.updateOrder(orderId, payload);
    isSubmitting.value = false;
    return result.fold(
      (f) {
        SalesOrderNotice.error(_humanizeFailure(f));
        return false;
      },
      (order) {
        detail.value = order;
        customerNameController.text = order.customerName ?? '';
        customerPhoneController.text = order.customerPhone ?? '';
        return true;
      },
    );
  }

  Future<SellerModel?> createShiplyPartner({
    required bool isCustomer,
    required String name,
    required String phone,
  }) async {
    final personType = isCustomer ? 'customer' : 'seller';
    final result = await repository.createPersonQuick(
      personType: personType,
      name: name,
      phone: phone,
    );
    return result.fold(
      (f) {
        SalesOrderNotice.error(_humanizeFailure(f));
        return null;
      },
      (partner) {
        if (isCustomer) {
          shiplyCustomers.add(partner);
        } else {
          shiplySellers.add(partner);
        }
        return partner;
      },
    );
  }

  Future<bool> updatePartnerPhoneAndOrder({
    required int orderId,
    required ShiplyPartnerSelection selection,
    required String phone,
  }) async {
    final formatted = PhoneFormatHelper.forApi(phone);
    if (!PhoneFormatHelper.isValidApiPhone(formatted)) {
      SalesOrderNotice.error('salesOrderShiplyPhoneInvalid'.tr);
      return false;
    }

    if (selection.partner.id > 0) {
      isSubmitting.value = true;
      final updateResult = await repository.updatePersonPhone(
        isCustomer: selection.isCustomer,
        personId: selection.partner.id,
        name: selection.partner.name,
        phone: formatted,
      );
      isSubmitting.value = false;

      final personOk = updateResult.fold(
        (f) {
          SalesOrderNotice.error(_humanizeFailure(f));
          return false;
        },
        (_) => true,
      );
      if (!personOk) return false;
    }

    final partner = SellerModel(
      id: selection.partner.id,
      name: selection.partner.name,
      phone: formatted,
    );
    return saveOrderCustomerPayload(
      orderId,
      buildCustomerPayloadFromPartner(
        partner,
        isCustomer: selection.isCustomer && selection.partner.id > 0,
      ),
    );
  }

  Future<bool> applyShiplyPartnerToOrder({
    required int orderId,
    required ShiplyPartnerSelection selection,
  }) async {
    pendingShiplyPartner = selection;
    final phone = selection.partner.phone.trim();
    if (phone.isEmpty) {
      return false;
    }
    return saveOrderCustomerPayload(
      orderId,
      buildCustomerPayloadFromPartner(
        selection.partner,
        isCustomer: selection.isCustomer,
      ),
    );
  }

  ShiplyPartnerSelection? shiplyPartnerForPhonePrompt(
    SalesOrderDetailModel order,
  ) {
    if (pendingShiplyPartner != null) return pendingShiplyPartner;
    if (order.customerId != null) {
      final match = shiplyCustomers.firstWhereOrNull(
        (c) => c.id == order.customerId,
      );
      if (match != null) {
        return ShiplyPartnerSelection(partner: match, isCustomer: true);
      }
      return ShiplyPartnerSelection(
        partner: SellerModel(
          id: order.customerId!,
          name: order.customerName ?? '',
          phone: order.customerPhone ?? '',
        ),
        isCustomer: true,
      );
    }
    if ((order.customerName ?? '').trim().isNotEmpty) {
      return ShiplyPartnerSelection(
        partner: SellerModel(
          id: 0,
          name: order.customerName ?? '',
          phone: order.customerPhone ?? '',
        ),
        isCustomer: true,
      );
    }
    return null;
  }

  String? validateShiplyAddressForm() {
    if (selectedShiplyCityId.value == null) {
      return 'salesOrderShiplyCityRequired'.tr;
    }
    if (selectedShiplyVillageId.value == null) {
      return 'salesOrderShiplyVillageRequired'.tr;
    }
    if (customerAddressController.text.trim().isEmpty) {
      return 'salesOrderStreetRequired'.tr;
    }
    return null;
  }

  Map<String, dynamic> buildShiplyAddressPayload() {
    onDeliveryFeeChanged();
    return {
      'customer_address': customerAddressController.text.trim(),
      'shiply_city_id': selectedShiplyCityId.value,
      'shiply_village_id': selectedShiplyVillageId.value,
      'customer_delivery_fee': manualDeliveryFee.value,
      if (shiplyQuotedDeliveryFee.value != null)
        'shiply_quoted_delivery_fee': shiplyQuotedDeliveryFee.value,
    };
  }

  Future<bool> saveShiplyAddressForOrder(int orderId) async {
    final err = validateShiplyAddressForm();
    if (err != null) {
      SalesOrderNotice.error(err);
      return false;
    }
    isSubmitting.value = true;
    final result =
        await repository.updateOrder(orderId, buildShiplyAddressPayload());
    isSubmitting.value = false;
    return result.fold(
      (f) {
        SalesOrderNotice.error(_humanizeFailure(f));
        return false;
      },
      (order) {
        detail.value = order;
        return true;
      },
    );
  }

  void onDeliveryFeeChanged() {
    manualDeliveryFee.value =
        double.tryParse(deliveryFeeController.text.trim()) ?? 0;
  }

  // Intentionally: do not auto-change cash when delivery city changes.

  void openOrderDetailAfterSave(SalesOrderDetailModel order) {
    statusFilter.value = order.status;
    loadOrders();
    detail.value = order;

    Get.until((route) => route.settings.name == AppRoutes.SALESSCREEN);

    if (Get.isRegistered<SalesController>()) {
      Get.find<SalesController>().changeTab(2);
    }

    Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: order.id);
  }

  Future<bool> submitCreateOrderFromCheckout(SalesController sales) async {
    final body = await _buildCheckoutBody(sales);
    if (body == null) return false;

    isSubmitting.value = true;
    final editId = activeEditSalesOrderId.value;
    final result = editId != null
        ? await repository.updateOrder(editId, body)
        : await repository.createOrder(body);
    isSubmitting.value = false;
    return result.fold(
      (f) {
        SalesOrderNotice.error(_humanizeFailure(f));
        return false;
      },
      (order) {
        SalesOrderNotice.success(
          editId != null ? 'salesOrderUpdated'.tr : 'salesOrderCreated'.tr,
        );
        hasSuspendedDraft.value = false;
        activeEditSalesOrderId.value = null;
        resetCreateForm();
        sales.resetInstantSaleForm();
        if (editId != null) {
          loadOrders();
          detail.value = order;
          Get.back();
          Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: order.id);
        } else {
          openOrderDetailAfterSave(order);
        }
        return true;
      },
    );
  }

  Future<Map<String, dynamic>?> _buildCheckoutBody(SalesController sales) async {
    sales.calculateGrandTotal();
    final lines = sales.cartLines.where((l) => !l.isDisposed).toList();
    if (lines.isEmpty) {
      SalesOrderNotice.error('salesOrderAddItem'.tr);
      return null;
    }

    final items = _itemsFromSalesCart(sales);
    if (items.isEmpty) {
      SalesOrderNotice.error('salesOrderAddItem'.tr);
      return null;
    }

    var customerName = customerNameController.text.trim();
    var customerPhone = customerPhoneController.text.trim();
    int? customerId;
    double paidAmount = 0;
    int? paymentBoxId;

    final partner = sales.pickerSelectedPartner.value;
    if (partner != null) {
      customerName = partner.name;
      customerPhone = partner.phone;
      if (sales.pickerPartnerIsCustomer.value && partner.id > 0) {
        customerId = partner.id;
      }
    }

    if (Get.isRegistered<PaymentController>(tag: kSalesOrderPaymentTag)) {
      final payment = Get.find<PaymentController>(tag: kSalesOrderPaymentTag);
      final buyer = payment.buildInstantSaleBuyerPayload();
      final buyerName = buyer['buyer_name']?.toString().trim() ?? '';
      if (buyerName.isNotEmpty) {
        customerName = buyerName;
      }
      if (buyer['buyer_type'] == 'customer' && buyer['buyer_id'] != null) {
        customerId = int.tryParse(buyer['buyer_id'].toString());
      }

      // For sales orders we consider cash entered even if the UI hides box selection;
      // the box is still applied from the daily session, but we don't want to drop paid amount.
      paidAmount = SalesAmountFormat.parse(payment.cashValueController.text);
      paymentBoxId = int.tryParse(payment.boxIdController.text.trim());
    }

    final discount = SalesAmountFormat.parse(sales.discountController.text);
    final total = sales.totalCost.value;
    var paymentType = selectedPaymentType.value;
    if (paymentType != 'visa') {
      paymentType = 'credit';
      if (paidAmount <= 0) {
        paymentType = 'credit';
      } else if (paidAmount >= total) {
        paymentType = 'cash';
      } else {
        paymentType = 'mixed';
      }
    }

    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (customerId != null) 'customer_id': customerId,
      'payment_type': paymentType,
      'payment_amount': paidAmount,
      if (paymentBoxId != null) 'payment_box_id': paymentBoxId,
      'discount': discount,
      'notes': notesController.text.trim(),
      'items': items,
    };
  }

  @Deprecated('Use submitCreateOrderFromCheckout')
  Future<bool> submitCreateOrderFromCheckoutLegacy(SalesController sales) async {
    return submitCreateOrderFromCheckout(sales);
  }

  Future<void> runAction(
    Future<Either<Failure, SalesOrderDetailModel>> Function() action, {
    bool deferNotice = false,
  }) async {
    isSubmitting.value = true;
    try {
      final result = await action();
      result.fold(
        (f) => deferNotice
            ? SalesOrderNotice.errorDeferred(_humanizeFailure(f))
            : SalesOrderNotice.error(_humanizeFailure(f)),
        (order) {
          detail.value = order;
          focusOrderStatusTab(order.status);
          final msg = 'salesOrderMovedToTab'.trParams({
            'status': statusLabel(order.status),
          });
          if (deferNotice) {
            SalesOrderNotice.successDeferred(msg);
          } else {
            SalesOrderNotice.success(msg);
          }
        },
      );
    } catch (e) {
      if (deferNotice) {
        SalesOrderNotice.errorDeferred(e.toString());
      } else {
        SalesOrderNotice.error(e.toString());
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> withBlockingProgress(
    Future<void> Function() action, {
    required String message,
  }) async {
    final hostContext = Get.overlayContext ?? Get.context;
    if (hostContext == null) {
      await action();
      return;
    }

    void Function()? closeLoader;

    showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        closeLoader = () {
          final nav = Navigator.of(dialogContext, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          }
        };
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: cardGray,
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;

    try {
      await action();
    } catch (e) {
      SalesOrderNotice.errorDeferred(e.toString());
    } finally {
      closeLoader?.call();
    }
  }

  Future<void> confirmOrder(int orderId) async {
    await withBlockingProgress(
      () => runAction(
        () => repository.confirmOrder(orderId),
        deferNotice: true,
      ),
      message: 'salesOrderActionInProgress'.tr,
    );
  }

  Future<void> markReady(int orderId) async {
    await withBlockingProgress(
      () => runAction(
        () => repository.markReady(orderId),
        deferNotice: true,
      ),
      message: 'salesOrderActionInProgress'.tr,
    );
  }

  Future<void> handover(int orderId) async {
    final body = <String, dynamic>{
      if (selectedDeliveryCompanyId.value != null)
        'delivery_company_id': selectedDeliveryCompanyId.value,
    };
    if (isSelectedCompanyTaxi) {
      body['tracking_number'] = trackingController.text.trim();
      body['carrier_contact_name'] = carrierContactNameController.text.trim();
      body['carrier_contact_phone'] = carrierContactPhoneController.text.trim();
    } else if (isSelectedCompanyOffice) {
      body['carrier_office_name'] = carrierOfficeNameController.text.trim();
      body['carrier_contact_name'] = carrierContactNameController.text.trim();
      body['carrier_contact_phone'] = carrierContactPhoneController.text.trim();
      body['carrier_vehicle_number'] = carrierVehicleNumberController.text.trim();
    } else if (!isSelectedCompanyShiply &&
        !isSelectedCompanyDoctorBike &&
        trackingController.text.trim().isNotEmpty) {
      body['tracking_number'] = trackingController.text.trim();
    }

    final showShiplyWait = isSelectedCompanyShiply;
    if (showShiplyWait) {
      await withBlockingProgress(
        () => runAction(
          () => repository.handover(orderId, body),
          deferNotice: true,
        ),
        message: 'shiplyHandoverInProgress'.tr,
      );
      return;
    }

    await runAction(() => repository.handover(orderId, body));
  }

  Future<void> deliver(int orderId) async {
    await runAction(() => repository.deliver(orderId, {}));
  }

  Future<void> settle(int orderId) async {
    final amount = double.tryParse(settleAmountController.text.trim()) ?? 0;
    final boxId = int.tryParse(settleBoxIdController.text.trim());
    await runAction(() => repository.settle(orderId, {
          'delivery_settled_amount': amount,
          if (amount > 0 && boxId != null) 'payment_box_id': boxId,
        }));
  }

  Future<void> postponeOrder(
    int orderId,
    DateTime until, {
    String? reason,
  }) async {
    final formatted =
        until.toIso8601String().substring(0, 19).replaceFirst('T', ' ');
    await runAction(() => repository.postpone(
          orderId,
          formatted,
          reason: reason,
        ));
  }

  Future<void> markStuckOrder(int orderId, {String? reason}) async {
    await runAction(() => repository.markStuck(orderId, reason: reason));
  }

  void toggleBulkMode([bool? value]) {
    bulkMode.value = value ?? !bulkMode.value;
    if (!bulkMode.value) {
      selectedOrderIds.clear();
    }
  }

  void toggleOrderSelection(int orderId, bool selected) {
    if (selected) {
      selectedOrderIds.add(orderId);
    } else {
      selectedOrderIds.remove(orderId);
    }
    selectedOrderIds.refresh();
  }

  Future<void> runBulkAction(String action) async {
    if (selectedOrderIds.isEmpty) return;
    isSubmitting.value = true;
    final result = await repository.bulkStatus(
      orderIds: selectedOrderIds.toList(),
      action: action,
    );
    isSubmitting.value = false;
    result.fold(
      (f) => SalesOrderNotice.error(_humanizeFailure(f)),
      (data) {
        final updated = data['updated'] as int? ?? 0;
        final failed = (data['failed'] as List<dynamic>? ?? []).length;
        toggleBulkMode(false);
        loadOrders();
        SalesOrderNotice.success(
          failed > 0
              ? 'salesOrderBulkPartial'.trParams({
                  'ok': '$updated',
                  'fail': '$failed',
                })
              : 'salesOrderBulkDone'.trParams({'count': '$updated'}),
        );
      },
    );
  }

  Future<void> archive(int orderId) async {
    await runAction(() => repository.archive(orderId));
  }

  Future<void> cancelOrder(int orderId) async {
    await runAction(() => repository.cancel(orderId));
  }

  Future<void> partialDeliver(int orderId, List<Map<String, dynamic>> items) async {
    await runAction(() => repository.partialDeliver(orderId, items));
  }

  Future<void> followUp(int orderId) async {
    isSubmitting.value = true;
    final result = await repository.followUp(orderId);
    isSubmitting.value = false;
    result.fold(
      (f) => SalesOrderNotice.error(f.errMessage),
      (order) {
        detail.value = order;
        loadOrders();
        SalesOrderNotice.success('salesOrderFollowUpCreated'.tr);
      },
    );
  }

  Future<void> partialReturn(int orderId, List<Map<String, dynamic>> items) async {
    await runAction(() => repository.partialReturn(orderId, items));
  }

  Future<void> alternativeReturn(
    int orderId,
    List<Map<String, dynamic>> items,
  ) async {
    await runAction(() => repository.alternativeReturn(orderId, items));
  }

  bool get canBulkSelectCurrentTab {
    return const {'unconfirmed', 'confirmed'}.contains(statusFilter.value);
  }

  List<String> get bulkActionsForCurrentTab {
    switch (statusFilter.value) {
      case 'unconfirmed':
        return const ['confirm', 'cancel'];
      case 'confirmed':
        return const ['mark_ready', 'cancel'];
      default:
        return const [];
    }
  }

  String bulkActionLabel(String action) {
    switch (action) {
      case 'confirm':
        return 'confirm'.tr;
      case 'mark_ready':
        return 'salesOrderMarkReady'.tr;
      case 'cancel':
        return 'cancel'.tr;
      default:
        return action;
    }
  }

  void selectAllVisibleOrders() {
    selectedOrderIds
      ..clear()
      ..addAll(orders.map((o) => o.id));
    selectedOrderIds.refresh();
  }

  void clearOrderSelection() {
    selectedOrderIds.clear();
    selectedOrderIds.refresh();
  }

  Future<void> shareOrderVia(int orderId, String channel) async {
    isSubmitting.value = true;
    final result = await repository.fetchStatement(orderId);
    isSubmitting.value = false;

    await result.fold(
      (f) async => SalesOrderNotice.error(f.errMessage),
      (report) async {
        final pdfUrl = report['pdf_url']?.toString() ?? '';
        final serial = report['serial_number']?.toString() ?? '#$orderId';
        final total = report['total']?.toString() ?? '';
        final message = '${'salesOrderShareIntro'.tr} $serial\n'
            '${'total'.tr}: $total ₪\n$pdfUrl';

        final phone = detail.value?.customerPhone?.replaceAll(RegExp(r'\D'), '') ?? '';

        if (channel == 'sms') {
          if (phone.isNotEmpty) {
            final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
              return;
            }
          }
          await SharePlus.instance.share(ShareParams(text: message));
          return;
        }

        if (phone.isNotEmpty) {
          final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
        await SharePlus.instance.share(ShareParams(text: message));
      },
    );
  }

  void showShareSheet(int orderId) {
    Get.bottomSheet(
      SalesOrderShareSheet(orderId: orderId),
      isScrollControlled: true,
    );
  }

  Future<void> pickAndUploadMedia(
    int orderId, {
    String? presetCategory,
  }) async {
    final category = presetCategory ?? await showSalesOrderMediaCategorySheet();
    if (category == null) return;

    final source = await showSalesOrderMediaSourceSheet();
    if (source == null) return;

    String? choice;
    if (source == 'camera') {
      choice = await showSalesOrderCameraTypeSheet();
    } else if (source == 'gallery') {
      choice = 'gallery_mixed';
    }
    if (choice == null) return;

    final picker = ImagePicker();
    final picked = <XFile>[];

    switch (choice) {
      case 'camera_image':
        if (!await ensureCameraPermission()) {
          SalesOrderNotice.error('cameraPermissionDenied'.tr);
          return;
        }
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) picked.add(image);
        break;
      case 'camera_video':
        if (!await ensureCameraPermission()) {
          SalesOrderNotice.error('cameraPermissionDenied'.tr);
          return;
        }
        final video = await picker.pickVideo(source: ImageSource.camera);
        if (video != null) picked.add(video);
        break;
      case 'gallery_mixed':
        if (!await ensurePhotosPermission()) {
          SalesOrderNotice.error('cameraPermissionDenied'.tr);
          return;
        }
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: const [
            'jpg',
            'jpeg',
            'png',
            'webp',
            'gif',
            'heic',
            'mp4',
            'mov',
            'avi',
            'mkv',
            'webm',
          ],
        );
        if (result != null) {
          for (final f in result.files) {
            final path = f.path;
            if (path != null && path.isNotEmpty) {
              picked.add(XFile(path));
            }
          }
        }
        break;
    }

    if (picked.isEmpty) return;

    await withBlockingProgress(() async {
      final multipart = <dio.MultipartFile>[];
      for (final file in picked) {
        multipart.add(
          await dio.MultipartFile.fromFile(file.path, filename: file.name),
        );
      }

      final uploadResult = await repository.uploadMedia(
        orderId,
        multipart,
        category: category,
      );
      uploadResult.fold(
        (f) => SalesOrderNotice.errorDeferred(_humanizeFailure(f)),
        (order) {
          detail.value = order;
          SalesOrderNotice.successDeferred('salesOrderMediaUploaded'.tr);
        },
      );
    }, message: 'salesOrderMediaUploadInProgress'.tr);
  }

  String _humanizeFailure(Failure f) {
    final data = f.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'] ?? (_looksLikeErrorsMap(data) ? data : null);
      if (errors is Map) {
        final parts = <String>[];
        errors.forEach((_, v) {
          if (v is List) {
            for (final msg in v) {
              final s = msg?.toString().trim();
              if (s != null && s.isNotEmpty) parts.add(s);
            }
          } else {
            final s = v?.toString().trim();
            if (s != null && s.isNotEmpty) parts.add(s);
          }
        });
        if (parts.isNotEmpty) {
          return parts.take(3).join('\n');
        }
      }
    }
    final msg = f.errMessage.trim();
    if (msg == 'validation_failed'.tr ||
        msg.toLowerCase() == 'validation failed' ||
        msg.contains('فشل التحقق')) {
      return 'makeSureTheDataIsCorrect'.tr;
    }
    if (msg.toLowerCase().contains('unauthorized')) {
      return 'shiplyUnauthorizedHint'.tr;
    }
    if (msg.contains('حدث خطأ') ||
        msg.toLowerCase().contains('something_wrong') ||
        msg.toLowerCase() == 'unknown error') {
      return 'salesOrderActionFailedGeneric'.tr;
    }
    return f.errMessage;
  }

  bool _looksLikeErrorsMap(Map<String, dynamic> data) {
    if (data.containsKey('status') || data.containsKey('message')) {
      return false;
    }
    return data.values.any((v) => v is List);
  }

  String statusLabel(String status) {
    if (status == 'unconfirmed') return 'salesOrderStatusUnconfirmed'.tr;
    if (status == 'confirmed') return 'salesOrderStatusConfirmed'.tr;
    if (status == 'ready') return 'salesOrderStatusReady'.tr;
    if (status == 'postponed') return 'salesOrderStatusPostponed'.tr;
    if (status == 'with_delivery') return 'salesOrderStatusWithDelivery'.tr;
    if (status == 'delivered') return 'salesOrderStatusDelivered'.tr;
    if (status == 'archived') return 'salesOrderStatusArchived'.tr;
    if (status == 'returned') return 'salesOrderStatusReturned'.tr;
    if (status == 'review') return 'salesOrderStatusReview'.tr;
    if (status == 'partial_delivered') return 'salesOrderStatusPartialDelivered'.tr;
    if (status == 'partial_return') return 'salesOrderStatusPartialReturn'.tr;
    if (status == 'alternative_return') return 'salesOrderStatusAlternativeReturn'.tr;
    if (status == 'stuck') return 'salesOrderStatusStuck'.tr;
    if (status == 'canceled') return 'salesOrderStatusCanceled'.tr;
    return status;
  }
}
