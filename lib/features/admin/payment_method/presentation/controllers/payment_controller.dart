import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
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

  String get partnerDropdownTitle =>
      selectedCustomersSellers.value ? 'customerName' : 'sellerName';

  String get partnerDropdownHint => selectedCustomersSellers.value
      ? 'customerNameExample'
      : 'sellerName1';

  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    allCustomersList.assignAll(resultCustomers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
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

    return {
      'success': true,
      'buyer_type': isCustomer ? 'customer' : 'seller',
      'buyer_id': isCustomer ? id : null,
      if (!isCustomer && id.isNotEmpty) 'seller_id': id,
      'buyer_name': name ?? '',
      if (boxId.isNotEmpty) 'payment_box_id': boxId,
      if (boxName != null && boxName.isNotEmpty) 'payment_box_name': boxName,
      if (cashRaw.isNotEmpty) 'payment_box_value': cashRaw,
    };
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
    if (partnerIdController.text.trim().isEmpty) {
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

    if (boxIdController.text.trim().isNotEmpty &&
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
      final sanitizedCash = cashValueController.text
          .replaceAll(',', '')
          .replaceAll('،', '')
          .trim();

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

  void clearPaymentForm() => _clearPaymentForm();

  void _clearPaymentForm() {
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
