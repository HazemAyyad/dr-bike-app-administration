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
import '../widgets/sales_order_media_source_sheet.dart';
import '../widgets/sales_order_share_sheet.dart';

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
  final deliveryCompanies = <DeliveryCompanyModel>[].obs;
  final cartItems = <SalesOrderCartItem>[].obs;

  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final customerAddressController = TextEditingController();
  final deliveryFeeController = TextEditingController(text: '0');
  final trackingController = TextEditingController();
  final settleAmountController = TextEditingController();
  final notesController = TextEditingController();

  final selectedCityId = RxnInt();
  final selectedShiplyCityId = RxnInt();
  final selectedShiplyVillageId = RxnInt();
  final manualDeliveryFee = 0.0.obs;
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

  bool get isSelectedCompanyShiply {
    final id = selectedDeliveryCompanyId.value;
    for (final company in deliveryCompanies) {
      if (company.id == id) {
        return company.code?.toLowerCase() == 'shiply';
      }
    }
    return false;
  }

  DeliveryCompanyModel? get shiplyDeliveryCompany {
    for (final company in deliveryCompanies) {
      if (company.code?.toLowerCase() == 'shiply') return company;
    }
    return null;
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
    settleAmountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> loadLookups() async {
    final shiplyResult = await repository.getShiplyAddressOptions();
    shiplyResult.fold((_) {}, (data) => shiplyCities.assignAll(data));
    final companiesResult = await repository.getDeliveryCompanies();
    companiesResult.fold((_) {}, (data) => deliveryCompanies.assignAll(data));
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
        Get.snackbar('error'.tr, f.errMessage);
        detail.value = null;
      },
      (data) => detail.value = data,
    );
    isDetailLoading.value = false;
  }

  void changeStatusFilter(String status) {
    statusFilter.value = status;
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
      Get.snackbar('error'.tr, 'salesOrderNotEditable'.tr);
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
    Get.snackbar('success'.tr, 'salesOrderDraftSuspended'.tr);
  }

  void suspendOrderDraftFromPicker() {
    if (!Get.isRegistered<SalesController>()) return;
    final sales = Get.find<SalesController>();
    if (sales.cartDistinctCount <= 0) return;
    hasSuspendedDraft.value = true;
    Get.back();
    Get.snackbar('success'.tr, 'salesOrderDraftSuspended'.tr);
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
  }

  bool needsShiplyAddress(SalesOrderDetailModel order) {
    return order.shiplyVillageId == null ||
        (order.customerAddress ?? '').trim().isEmpty;
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
    };
  }

  Future<bool> saveShiplyAddressForOrder(int orderId) async {
    final err = validateShiplyAddressForm();
    if (err != null) {
      Get.snackbar('error'.tr, err);
      return false;
    }
    isSubmitting.value = true;
    final result =
        await repository.updateOrder(orderId, buildShiplyAddressPayload());
    isSubmitting.value = false;
    return result.fold(
      (f) {
        Get.snackbar('error'.tr, _humanizeFailure(f));
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
        Get.snackbar('error'.tr, _humanizeFailure(f));
        return false;
      },
      (order) {
        Get.snackbar(
          'success'.tr,
          editId != null ? 'salesOrderUpdated'.tr : 'salesOrderCreated'.tr,
        );
        hasSuspendedDraft.value = false;
        activeEditSalesOrderId.value = null;
        resetCreateForm();
        sales.resetInstantSaleForm();
        loadOrders();
        detail.value = order;
        Get.offNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: order.id);
        return true;
      },
    );
  }

  Future<Map<String, dynamic>?> _buildCheckoutBody(SalesController sales) async {
    sales.calculateGrandTotal();
    final lines = sales.cartLines.where((l) => !l.isDisposed).toList();
    if (lines.isEmpty) {
      Get.snackbar('error'.tr, 'salesOrderAddItem'.tr);
      return null;
    }

    final items = _itemsFromSalesCart(sales);
    if (items.isEmpty) {
      Get.snackbar('error'.tr, 'salesOrderAddItem'.tr);
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
    onDeliveryFeeChanged();
    final deliveryFee = manualDeliveryFee.value;
    final total = sales.totalCost.value + deliveryFee;
    var paymentType = 'credit';
    if (paidAmount <= 0) {
      paymentType = 'credit';
    } else if (paidAmount >= total) {
      paymentType = 'cash';
    } else {
      paymentType = 'mixed';
    }

    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (customerId != null) 'customer_id': customerId,
      'customer_address': customerAddressController.text.trim(),
      if (selectedShiplyCityId.value != null)
        'shiply_city_id': selectedShiplyCityId.value,
      if (selectedShiplyVillageId.value != null)
        'shiply_village_id': selectedShiplyVillageId.value,
      'customer_delivery_fee': deliveryFee,
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
    Future<Either<Failure, SalesOrderDetailModel>> Function() action,
  ) async {
    isSubmitting.value = true;
    final result = await action();
    isSubmitting.value = false;
    result.fold(
      (f) => Get.snackbar('error'.tr, _humanizeFailure(f)),
      (order) {
        detail.value = order;
        focusOrderStatusTab(order.status);
        Get.snackbar(
          'success'.tr,
          'salesOrderMovedToTab'.trParams({'status': statusLabel(order.status)}),
        );
      },
    );
  }

  Future<void> confirmOrder(int orderId) async {
    await runAction(() => repository.confirmOrder(orderId));
  }

  Future<void> markReady(int orderId) async {
    await runAction(() => repository.markReady(orderId));
  }

  Future<void> handover(int orderId) async {
    final body = <String, dynamic>{
      if (selectedDeliveryCompanyId.value != null)
        'delivery_company_id': selectedDeliveryCompanyId.value,
    };
    if (!isSelectedCompanyShiply && trackingController.text.trim().isNotEmpty) {
      body['tracking_number'] = trackingController.text.trim();
    }
    await runAction(() => repository.handover(orderId, body));
  }

  Future<void> deliver(int orderId) async {
    await runAction(() => repository.deliver(orderId, {}));
  }

  Future<void> settle(int orderId) async {
    final amount = double.tryParse(settleAmountController.text.trim()) ?? 0;
    await runAction(() => repository.settle(orderId, {
          'delivery_settled_amount': amount,
        }));
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
      (f) => Get.snackbar('error'.tr, f.errMessage),
      (order) {
        detail.value = order;
        loadOrders();
        Get.snackbar('success'.tr, 'salesOrderFollowUpCreated'.tr);
      },
    );
  }

  Future<void> partialReturn(int orderId, List<Map<String, dynamic>> items) async {
    await runAction(() => repository.partialReturn(orderId, items));
  }

  Future<void> shareOrderVia(int orderId, String channel) async {
    isSubmitting.value = true;
    final result = await repository.fetchStatement(orderId);
    isSubmitting.value = false;

    await result.fold(
      (f) async => Get.snackbar('error'.tr, f.errMessage),
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

  Future<void> pickAndUploadMedia(int orderId) async {
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
          showMediaPermissionDeniedSnackbar();
          return;
        }
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) picked.add(image);
        break;
      case 'camera_video':
        if (!await ensureCameraPermission()) {
          showMediaPermissionDeniedSnackbar();
          return;
        }
        final video = await picker.pickVideo(source: ImageSource.camera);
        if (video != null) picked.add(video);
        break;
      case 'gallery_mixed':
        if (!await ensurePhotosPermission()) {
          showMediaPermissionDeniedSnackbar();
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

    final multipart = <dio.MultipartFile>[];
    for (final file in picked) {
      multipart.add(
        await dio.MultipartFile.fromFile(file.path, filename: file.name),
      );
    }

    isSubmitting.value = true;
    final uploadResult = await repository.uploadMedia(orderId, multipart);
    isSubmitting.value = false;
    uploadResult.fold(
      (f) => Get.snackbar('error'.tr, _humanizeFailure(f)),
      (order) {
        detail.value = order;
        Get.snackbar('success'.tr, 'salesOrderMediaUploaded'.tr);
      },
    );
  }

  String _humanizeFailure(Failure f) {
    final data = f.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
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
    return f.errMessage;
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
    if (status == 'canceled') return 'salesOrderStatusCanceled'.tr;
    return status;
  }
}
