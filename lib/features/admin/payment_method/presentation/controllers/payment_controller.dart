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
  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    allCustomersList.assignAll(resultCustomers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
  }

  // get shown boxes
  final RxList<shownBoxesModel> shownBoxes = <shownBoxesModel>[].obs;

  void showBoxes() async {
    // shownBoxes.isEmpty ? isLoading(true) : isLoading(true);
    final boxes = await getShownBoxUsecase.call(screen: 0);
    shownBoxes.value = boxes;
    // isLoading(false);
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
  void addPayment({required BuildContext context, required String type}) async {
    isLoading(true);

    final result = await addPaymentUsecase.call(
      customerId:
          !selectedCustomersSellers.value ? partnerIdController.text : '',
      sellerId: selectedCustomersSellers.value ? partnerIdController.text : '',
      type: type,
      boxId: boxIdController.text,
      boxValue: cashValueController.text,
      checks: payments,
    );
    result.fold(
      (failure) {
        String errorMessages = '';
        bool data = false;
        final errors = failure.data?['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          errors.forEach((key, value) {
            if (key.startsWith('permissions')) {
              if (!data) {
                errorMessages += "Permissions: ${value.first}\n";
                data = true;
              }
            } else {
              for (var msg in value) {
                errorMessages += "- $key: $msg\n";
              }
            }
          });
        } else {
          errorMessages = failure.data?['message'] ?? failure.errMessage;
        }
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: errorMessages,
        );
      },
      (success) {
        // totalBillController.clear();
        partnerIdController.clear();
        boxIdController.clear();
        // paymentMethodController.clear();
        cashValueController.clear();
        checkNumberController.clear();
        currencyController.clear();
        bankNameController.clear();
        payments.map((e) {
          e.paymentMethod.clear();
          e.checkValue.clear();
          e.dueDate.clear();
          e.currency.clear();
          e.checkNumber.clear();
          e.bankName.clear();
          e.selectedFile.value = null;
          e.debtValue.clear();
        });
        payments.clear();
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            Get.back();
            // ignore: use_build_context_synchronously
            Navigator.pop(context, true);
          },
        );
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: success,
        );
      },
    );
    isLoading(false);
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
