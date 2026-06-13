import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../boxes/data/models/get_shown_boxes_model.dart';
import '../../../boxes/domain/usecases/get_shown_box_usecase.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../domain/usecases/add_payment_usecase.dart';

class PaymentController extends GetxController {
  static bool isSuccessResult(dynamic value) {
    return value == true ||
        (value is Map && value['success'] == true);
  }

  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final GetShownBoxUsecase getShownBoxUsecase;
  final AddPaymentUsecase addPaymentUsecase;
  PaymentController({
    required this.allCustomersSellersUsecase,
    required this.getShownBoxUsecase,
    required this.addPaymentUsecase,
  });
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController partnerIdController = TextEditingController();
  final TextEditingController boxIdController = TextEditingController();
  // final TextEditingController totalBillController = TextEditingController();
  // final TextEditingController paymentMethodController = TextEditingController();
  final TextEditingController cashValueController = TextEditingController();
  final TextEditingController checkNumberController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  final DateTime dueDate = DateTime.now();

  final RxBool selectedCustomersSellers = false.obs;

  /// When true (instant sale flow), pop immediately with buyer payload and skip payment success dialog.
  bool forInstantSale = false;
  String? instantSaleBoxLogNote;

  /// Daily sales drawer — box is fixed (not chosen from main boxes list).
  final RxBool useDailySalesBox = false.obs;
  final RxString dailySalesBoxLabel = ''.obs;
  final RxString dailySalesCurrency = 'شيكل'.obs;

  void applyDailySalesBox({
    required int boxId,
    required String boxName,
    String currency = 'شيكل',
  }) {
    useDailySalesBox.value = true;
    dailySalesBoxLabel.value = boxName;
    dailySalesCurrency.value = currency;
    boxIdController.text = boxId.toString();
    selectedBox.value = ShownBoxesModel(
      boxId: boxId,
      boxName: boxName,
      totalBalance: 0,
      isShown: false,
      currency: currency,
    );
  }

  void clearDailySalesBox() {
    useDailySalesBox.value = false;
    dailySalesBoxLabel.value = '';
  }

  final List<String> paymentMethods = [
    'check',
    'deb',
  ];
  final List<String> paymentMethods1 = [
    'cash',
    'visa',
  ];

  final List<String> currencies = [
    'currency',
    'currency1',
    'currency2',
  ];

  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;
  final Rxn<SellerModel> selectedPartner = Rxn<SellerModel>();

  /// false = تاجر (sellers), true = زبون (customers).
  void setPartnerTab({required bool isCustomer}) {
    if (selectedCustomersSellers.value == isCustomer) return;
    selectedCustomersSellers.value = isCustomer;
    selectedPartner.value = null;
    partnerIdController.clear();
  }

  void onPartnerSelected(SellerModel? partner) {
    selectedPartner.value = partner;
    if (partner != null) {
      partnerIdController.text = partner.id.toString();
    } else {
      partnerIdController.clear();
    }
  }

  /// After restoring partner id from suspended sale payload.
  void restorePartnerSelectionFromId() {
    final id = partnerIdController.text.trim();
    if (id.isEmpty) return;
    final list =
        selectedCustomersSellers.value ? allCustomersList : allSellersList;
    selectedPartner.value =
        list.firstWhereOrNull((e) => e.id.toString() == id);
  }

  String get partnerDropdownTitle =>
      selectedCustomersSellers.value ? 'customerName' : 'sellerName';

  String get partnerDropdownHint => selectedCustomersSellers.value
      ? 'customerNameExample'
      : 'sellerName1';

  Future<void> getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
      endPoint: EndPoints.all_customers,
    );
    allCustomersList.assignAll(resultCustomers);
    final resultSellers = await allCustomersSellersUsecase.call(
      endPoint: EndPoints.all_sellers,
    );
    allSellersList.assignAll(resultSellers);
  }

  Set<int> _partnerIds(bool isCustomer) {
    final list = isCustomer ? allCustomersList : allSellersList;
    return list.map((e) => e.id).toSet();
  }

  Future<void> _refreshPartnerList({required bool isCustomer}) async {
    if (isCustomer) {
      final customers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers,
      );
      allCustomersList.assignAll(customers);
      return;
    }
    final sellers = await allCustomersSellersUsecase.call(
      endPoint: EndPoints.all_sellers,
    );
    allSellersList.assignAll(sellers);
  }

  void _selectNewlyAddedPartner({
    required bool isCustomer,
    required Set<int> previousIds,
  }) {
    final list = isCustomer ? allCustomersList : allSellersList;
    final newcomers =
        list.where((e) => !previousIds.contains(e.id)).toList();
    if (newcomers.isEmpty) return;
    final pick = newcomers.length == 1
        ? newcomers.first
        : newcomers.reduce((a, b) => a.id > b.id ? a : b);
    onPartnerSelected(pick);
  }

  /// فتح شاشة إضافة زبون/تاجر ثم تحديث القائمة عند العودة (بيع فوري وغيره).
  Future<void> openAddPartnerScreen() async {
    final isCustomer = selectedCustomersSellers.value;
    final previousIds = _partnerIds(isCustomer);

    final result = await Get.toNamed(
      AppRoutes.ADDNEWCUSTOMERSCREEN,
      arguments: {
        'sellerId': '',
        'employeeId': '',
        'employeeType': isCustomer ? 'customer' : 'seller',
        'popOnceOnSuccess': true,
      },
    );

    await _refreshPartnerList(isCustomer: isCustomer);

    if (result is Map && result['added'] == true) {
      _selectNewlyAddedPartner(
        isCustomer: isCustomer,
        previousIds: previousIds,
      );
    }
  }

  // get shown boxes
  final RxList<ShownBoxesModel> shownBoxes = <ShownBoxesModel>[].obs;
  final Rxn<ShownBoxesModel> selectedBox = Rxn<ShownBoxesModel>();

  void showBoxes() async {
    final boxes = await getShownBoxUsecase.call(screen: 0);
    shownBoxes.assignAll(boxes);
  }

  void onBoxSelected(ShownBoxesModel? box) {
    selectedBox.value = box;
    if (box != null) {
      boxIdController.text = box.boxId.toString();
    } else {
      boxIdController.clear();
    }
  }

  final List<PaymentModel> payments = <PaymentModel>[].obs;

  void addPaymentMethod() {
    payments.add(PaymentModel());
    update();
  }

  void removePaymentMethod(int index) {
    payments.removeAt(index);
    update();
  }

  final RxBool isLoading = false.obs;
  final RxBool isPayment = true.obs;

  /// Maps payment-step partner selection to instant-sale buyer fields.
  Map<String, dynamic> buildInstantSaleBuyerPayload() {
    final id = partnerIdController.text.trim();
    final isCustomer = selectedCustomersSellers.value;

    String? name;
    if (id.isNotEmpty) {
      if (isCustomer) {
        name = allCustomersList
            .firstWhereOrNull((e) => e.id.toString() == id)
            ?.name;
      } else {
        name = allSellersList
            .firstWhereOrNull((e) => e.id.toString() == id)
            ?.name;
      }
    }

    final boxId = boxIdController.text.trim();
    String? boxName;
    if (boxId.isNotEmpty) {
      boxName = shownBoxes
          .firstWhereOrNull((e) => e.boxId.toString() == boxId)
          ?.boxName;
    }

    final cashRaw = cashValueController.text
        .replaceAll(',', '')
        .replaceAll('،', '')
        .trim();

    final hasPartner = id.isNotEmpty;

    return {
      'success': true,
      'buyer_type': hasPartner
          ? (isCustomer ? 'customer' : 'seller')
          : 'unknown',
      if (hasPartner && isCustomer) 'buyer_id': id,
      if (hasPartner && !isCustomer) 'seller_id': id,
      if (name != null && name.isNotEmpty) 'buyer_name': name,
      if (boxId.isNotEmpty) 'payment_box_id': boxId,
      if (boxName != null && boxName.isNotEmpty) 'payment_box_name': boxName,
      if (boxId.isNotEmpty) 'payment_box_value': cashRaw.isEmpty ? '0' : cashRaw,
    };
  }

  Map<String, dynamic> buildOptionalProfitSalePayload() {
    final id = partnerIdController.text.trim();
    final hasPartner = id.isNotEmpty;
    final isCustomer = selectedCustomersSellers.value;

    String? name;
    if (hasPartner) {
      if (isCustomer) {
        name = allCustomersList
            .firstWhereOrNull((e) => e.id.toString() == id)
            ?.name;
      } else {
        name = allSellersList
            .firstWhereOrNull((e) => e.id.toString() == id)
            ?.name;
      }
    }

    final boxId = boxIdController.text.trim();
    String? boxName;
    if (boxId.isNotEmpty) {
      boxName = shownBoxes
          .firstWhereOrNull((e) => e.boxId.toString() == boxId)
          ?.boxName;
    }

    final cashRaw = cashValueController.text
        .replaceAll(',', '')
        .replaceAll('،', '')
        .trim();
    final normalizedCash = _normalizeAmountDigits(cashRaw);

    return {
      'success': true,
      'buyer_type': hasPartner ? (isCustomer ? 'customer' : 'seller') : 'unknown',
      if (hasPartner && isCustomer) 'buyer_id': id,
      if (hasPartner && !isCustomer) 'seller_id': id,
      if (name != null && name.isNotEmpty) 'buyer_name': name,
      if (boxId.isNotEmpty) 'payment_box_id': boxId,
      if (boxName != null && boxName.isNotEmpty) 'payment_box_name': boxName,
      if (normalizedCash.isNotEmpty) 'payment_box_value': normalizedCash,
    };
  }

  String _normalizeAmountDigits(String value) {
    const eastern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };
    var text = value.trim();
    eastern.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
    return text;
  }

  /// Receive (قبض) for instant sale without leaving the sale screen.
  Future<Map<String, dynamic>?> submitReceiveForInstantSale(
    BuildContext context,
  ) async {
    return _submitPayment(
      context: context,
      type: 'receive',
      popOnSuccess: false,
    );
  }

  void addPayment({required BuildContext context, required String type}) async {
    if (type == 'receive' && forInstantSale) {
      final payload = await _submitPayment(
        context: context,
        type: type,
        popOnSuccess: true,
      );
      if (payload != null) {
        Get.back(result: payload);
      }
      return;
    }

    isLoading(true);
    try {
      await _submitPayment(context: context, type: type, popOnSuccess: false);
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>?> _submitPayment({
    required BuildContext context,
    required String type,
    required bool popOnSuccess,
  }) async {
    if (!forInstantSale && partnerIdController.text.trim().isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'must_select_customer_or_seller'.tr,
      );
      return null;
    }

    if (forInstantSale && boxIdController.text.trim().isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'must_select_box'.tr,
      );
      return null;
    }

    if (!forInstantSale &&
        boxIdController.text.trim().isNotEmpty &&
        cashValueController.text.trim().isEmpty) {
      Helpers.showCustomDialogError(
        context: context,
        title: 'error'.tr,
        message: 'must_enter_box_value'.tr,
      );
      return null;
    }

    isLoading(true);
    try {
      var sanitizedCash = cashValueController.text
          .replaceAll(',', '')
          .replaceAll('،', '')
          .trim();
      if (forInstantSale &&
          boxIdController.text.trim().isNotEmpty &&
          sanitizedCash.isEmpty) {
        sanitizedCash = '0';
      }

      final result = await addPaymentUsecase.call(
        customerId:
            selectedCustomersSellers.value ? partnerIdController.text : '',
        sellerId:
            !selectedCustomersSellers.value ? partnerIdController.text : '',
        type: type,
        boxId: boxIdController.text,
        boxValue: sanitizedCash,
        checks: payments,
        boxLogNote: forInstantSale && type == 'receive'
            ? instantSaleBoxLogNote
            : null,
      );

      Map<String, dynamic>? payload;
      var failed = false;
      String? successMessage;

      await result.fold(
        (failure) async {
          failed = true;
          String errorMessages = '';
          var permissionsAdded = false;
          final errors = failure.data?['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            errors.forEach((key, value) {
              if (key.startsWith('permissions')) {
                if (!permissionsAdded) {
                  errorMessages += "Permissions: ${value.first}\n";
                  permissionsAdded = true;
                }
              } else {
                for (var msg in value) {
                  errorMessages += "- $key: $msg\n";
                }
              }
            });
          } else {
            errorMessages = failure.data?['message']?.toString() ??
                failure.errMessage;
          }
          if (errorMessages.trim().isEmpty) {
            errorMessages = 'something_wrong'.tr;
          }
          Helpers.showCustomDialogError(
            context: context,
            title: failure.errMessage,
            message: errorMessages,
          );
        },
        (success) async {
          successMessage = success;
          if (type == 'receive' && forInstantSale) {
            payload = buildInstantSaleBuyerPayload();
          }
          if (popOnSuccess) {
            _clearPaymentForm();
          } else if (!forInstantSale) {
            _clearPaymentForm();
            Get.back(result: buildInstantSaleBuyerPayload());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final ctx = Get.context;
              if (ctx == null) return;
              Helpers.showCustomDialogSuccess(
                context: ctx,
                title: 'success'.tr,
                message: successMessage ?? '',
              );
            });
          }
        },
      );

      if (failed) {
        return null;
      }
      return payload;
    } finally {
      isLoading(false);
    }
  }

  List<ShownBoxesModel> get selectableBoxes {
    if (useDailySalesBox.value && selectedBox.value != null) {
      return [selectedBox.value!];
    }
    return shownBoxes;
  }

  void clearPaymentForm() => _clearPaymentForm();

  void _clearPaymentForm() {
    clearDailySalesBox();
    partnerIdController.clear();
    selectedPartner.value = null;
    boxIdController.clear();
    selectedBox.value = null;
    cashValueController.clear();
    checkNumberController.clear();
    currencyController.clear();
    bankNameController.clear();
    for (final e in payments) {
      e.paymentMethod.clear();
      e.checkValue.clear();
      e.dueDate.clear();
      e.currency.clear();
      e.checkNumber.clear();
      e.bankName.clear();
      e.selectedFile.value = null;
      e.debtValue.clear();
    }
    payments.clear();
  }

  @override
  void onInit() {
    super.onInit();
    getAllCustomersAndSellers();
    showBoxes();
  }

  @override
  void onClose() {
    super.onClose();
    // totalBillController.dispose();
    partnerIdController.dispose();
    boxIdController.dispose();
    // paymentMethodController.dispose();
    cashValueController.dispose();
    checkNumberController.dispose();
    currencyController.dispose();
    bankNameController.dispose();
  }
}

class PaymentModel {
  final TextEditingController paymentMethod = TextEditingController();
  final TextEditingController checkValue = TextEditingController();
  final TextEditingController dueDate = TextEditingController();
  final TextEditingController currency = TextEditingController();
  final TextEditingController checkNumber = TextEditingController();
  final TextEditingController bankName = TextEditingController();
  final Rx<XFile?> selectedFile = Rx<XFile?>(null);
  final TextEditingController debtValue = TextEditingController();
}
