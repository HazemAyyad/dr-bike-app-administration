import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../routes/app_routes.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../checks/domain/usecases/all_customers_sellers_usecase.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/domain/usecases/get_all_products_usecase.dart';
import '../../data/models/followup_modle.dart';
import '../../domain/usecases/add_followup_usecase.dart';
import '../../domain/usecases/add_new_follow_customer_usecase.dart';
import '../../domain/usecases/followup_details_cancel_usecase.dart';
import '../../domain/usecases/get_followup_usecase.dart';
import 'gfollow_up_services.dart';

class FollowUpController extends GetxController {
  final AddFollowupUsecase addFollowupUsecase;
  final GetFollowupUsecase getFollowupUsecase;
  final AllCustomersSellersUsecase allCustomersSellersUsecase;
  final GetAllProductsUsecase getAllProductsUsecase;
  final FollowupDetailsCancelUsecase followupDetailsCancelUsecase;
  final AddNewFollowCustomerUsecase addNewFollowCustomerUsecase;

  FollowUpController({
    required this.addFollowupUsecase,
    required this.getFollowupUsecase,
    required this.allCustomersSellersUsecase,
    required this.getAllProductsUsecase,
    required this.followupDetailsCancelUsecase,
    required this.addNewFollowCustomerUsecase,
  });

  final formKey = GlobalKey<FormState>();
  final addNewCustomerFormKey = GlobalKey<FormState>();

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final employeeNameController = TextEditingController();

  final customerAndSellerIdController = TextEditingController();
  final itemIdController = TextEditingController();

  final customerNameController = TextEditingController();
  final customerTypeController = TextEditingController();
  final customerphoneController = TextEditingController();
  final customerNotesController = TextEditingController();

  RxInt currentTab = 0.obs;
  RxList<Map<String, dynamic>> tasks = <Map<String, dynamic>>[].obs;
  final tabs = [
    'initialFollowUp',
    'notify_customer',
    'completion_and_agreement',
    'archive',
  ].obs;

  void changeTab(int index) {
    currentTab.value = index;
    update();
  }

  final List<Map<int, String>> timeLineSteps = [
    {1: 'initialFollowUp'},
    {2: 'notify_customer'},
    {3: 'completion_and_agreement'},
  ];
  final RxInt selectedStep = 1.obs;

  void changeSelected(int index) => selectedStep.value = index;

  void nextStep() {
    if (selectedStep.value < timeLineSteps.length) {
      addFollowUp(step: selectedStep.value);
      selectedStep.value += 1;
      update();
    } else if (selectedStep.value == timeLineSteps.length) {
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.back();
      });
      addFollowUp(step: selectedStep.value);
      update();
    }
  }

  void prevStep() {
    selectedStep.value -= 1;
    addFollowUp(step: selectedStep.value - 1);
    update();
  }

  List<String> customerTypeList = ['جملة', 'قطاعي'];

  final RxBool isLoading = false.obs;

  // get all Follow ups
  void getAllFollowUps() async {
    FollowUpServices().initialFollowups.isEmpty ? isLoading(true) : null;
    update();
    FollowUpServices()
        .initialFollowups
        .assignAll(await getFollowupUsecase.call(page: 0));
    initialFollowupsFilterList.assignAll(FollowUpServices().initialFollowups);

    isLoading(false);
    update();
    FollowUpServices()
        .informFollowups
        .assignAll(await getFollowupUsecase.call(page: 1));
    informFollowupsFilterList.assignAll(FollowUpServices().informFollowups);

    FollowUpServices()
        .finishAndAgreementFollowups
        .assignAll(await getFollowupUsecase.call(page: 2));
    finishAndAgreementFollowupsFilterList
        .assignAll(FollowUpServices().finishAndAgreementFollowups);

    FollowUpServices()
        .archivedFollowups
        .assignAll(await getFollowupUsecase.call(page: 3));
    archivedFollowupsFilterList.assignAll(FollowUpServices().archivedFollowups);

    isLoading(false);
    update();
  }

  // get all customers and sellers
  final RxList<SellerModel> allCustomersList = <SellerModel>[].obs;
  final RxList<SellerModel> allSellersList = <SellerModel>[].obs;

  final RxBool isCustomer = true.obs;

  void getAllCustomersAndSellers() async {
    final resultCustomers = await allCustomersSellersUsecase.call(
        endPoint: EndPoints.all_customers);
    final resultSellers =
        await allCustomersSellersUsecase.call(endPoint: EndPoints.all_sellers);
    allSellersList.assignAll(resultSellers);
    allCustomersList.assignAll(resultCustomers);
  }

  // get all products
  final List<ProductModel> products = [];
  void getAllProducts() async {
    final result = await getAllProductsUsecase.call();
    products.assignAll(result);
  }

  final RxBool isEdite = false.obs;

  // get follow up details
  String followupId = '';
  void getFollowUpDetails({
    required String followupId,
    bool isCancel = false,
  }) async {
    isLoading(true);
    if (isCancel) {
      final result = await followupDetailsCancelUsecase.call(
        followupId: followupId,
        isCancel: isCancel,
      );
      getAllFollowUps();
      Get.back();
      Get.snackbar(
        'success'.tr,
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
      );
      isLoading(false);
      update();
      return;
    }
    isEdite(true);
    Get.toNamed(AppRoutes.ADDFOLLOWUPSCREEN);
    final result = await followupDetailsCancelUsecase.call(
      followupId: followupId,
      isCancel: isCancel,
    );
    final followupDetails = result['followup'];
    if (followupDetails['customer'] != null) {
      isCustomer.value = false;
      customerAndSellerIdController.text =
          followupDetails['customer']['id'].toString();
    }
    if (followupDetails['seller'] != null) {
      isCustomer.value = true;
      customerAndSellerIdController.text =
          followupDetails['seller']['id'].toString();
    }
    itemIdController.text = followupDetails['product_id'].toString();
    selectedStep.value = followupDetails['status'] == 'initial'
        ? 1
        : followupDetails['status'] == 'inform'
            ? 2
            : followupDetails['status'] == 'agreement'
                ? 3
                : 4;

    this.followupId = followupDetails['id'].toString();
    isLoading(false);
    update();
  }

  void resetData() {
    isEdite(false);
    Get.toNamed(AppRoutes.ADDFOLLOWUPSCREEN);
    customerAndSellerIdController.clear();
    itemIdController.clear();
    followupId == '';
    selectedStep.value = 1;
    update();
  }

  // add follow up
  void addFollowUp({int step = 0}) async {
    isLoading(true);
    String status = '';
    if (step == 1) {
      status = 'inform';
    } else if (step == 2) {
      status = 'agreement';
    } else if (step == 3) {
      status = 'delivered';
    } else if (step == 4) {
      status = 'rejected';
    }
    final result = await addFollowupUsecase.call(
      followupId: followupId,
      customerId: !isCustomer.value ? customerAndSellerIdController.text : '',
      sellerId: isCustomer.value ? customerAndSellerIdController.text : '',
      productId: itemIdController.text,
      status: status,
    );
    // values [inform,agreement,delivered,rejected]

    result.fold(
      (failure) {
        final errors = failure.data != null ? failure.data['errors'] : null;
        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((list) => list)
              .cast<String>()
              .join('')
              .replaceAll('.', '- \n');
          Helpers.showCustomDialogError(
            context: Get.context!,
            title: failure.errMessage,
            message: messages,
          );
        } else {
          Helpers.showCustomDialogError(
            context: Get.context!,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        }
        isLoading(false);
      },
      (success) {
        getAllFollowUps();
        if (selectedStep.value == 1) {
          customerAndSellerIdController.clear();
          itemIdController.clear();
          Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              Get.back();
              Get.back();
            },
          );
          Helpers.showCustomDialogSuccess(
            context: Get.context!,
            title: 'success'.tr,
            message: success,
          );
          selectedStep.value = 1;
          return;
        }
        Get.snackbar(
          'success'.tr,
          success,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1500),
        );
      },
    );
    isLoading(false);
  }

  // add new follow customer
  void addNewFollowCustomer() async {
    if (!addNewCustomerFormKey.currentState!.validate()) {
      return;
    }
    isLoading(true);
    final result = await addNewFollowCustomerUsecase.call(
      name: customerNameController.text,
      type: customerTypeController.text,
      phone: customerphoneController.text,
      notes: customerNotesController.text,
    );

    result.fold(
      (failure) {
        final errors = failure.data != null ? failure.data['errors'] : null;
        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .expand((list) => list)
              .cast<String>()
              .join('')
              .replaceAll('.', '- \n');
          Helpers.showCustomDialogError(
            context: Get.context!,
            title: failure.errMessage,
            message: messages,
          );
        } else {
          Helpers.showCustomDialogError(
            context: Get.context!,
            title: failure.errMessage,
            message: failure.data['message'],
          );
        }
        isLoading(false);
      },
      (success) {
        getAllCustomersAndSellers();
        Future.delayed(
          const Duration(milliseconds: 1500),
          () {
            Get.back();
            Get.back();
          },
        );
        Helpers.showCustomDialogSuccess(
          context: Get.context!,
          title: 'success',
          message: success,
        );
      },
    );
    isLoading(false);
  }

  final List<FollowupModel> initialFollowupsFilterList = <FollowupModel>[].obs;
  final List<FollowupModel> informFollowupsFilterList = <FollowupModel>[].obs;
  final List<FollowupModel> finishAndAgreementFollowupsFilterList =
      <FollowupModel>[].obs;
  final List<FollowupModel> archivedFollowupsFilterList = <FollowupModel>[].obs;

  void filterGoals() {
    final nameQuery = employeeNameController.text.trim();
    final fromDate = fromDateController.text.trim();
    final toDate = toDateController.text.trim();

    List<FollowupModel> applyFilter(List<FollowupModel> sourceList) {
      return sourceList.where((item) {
        final name =
            (item.customerName.isNotEmpty ? item.customerName : item.sellerName)
                .toLowerCase();

        // ✅ فلترة بالاسم
        final matchesName =
            (nameQuery.isEmpty) ? true : name.contains(nameQuery.toLowerCase());

        // ✅ فلترة بالتاريخ
        final itemDate = item.createdAt;
        final from = (fromDate.isNotEmpty) ? DateTime.tryParse(fromDate) : null;
        final to = (toDate.isNotEmpty) ? DateTime.tryParse(toDate) : null;
        bool matchesDate = true;
        if (from != null && itemDate.isBefore(from)) matchesDate = false;
        if (to != null && itemDate.isAfter(to)) matchesDate = false;
        return matchesName && matchesDate;
      }).toList();
    }

    initialFollowupsFilterList
      ..clear()
      ..addAll(applyFilter(FollowUpServices().initialFollowups));
    informFollowupsFilterList
      ..clear()
      ..addAll(applyFilter(FollowUpServices().informFollowups));
    finishAndAgreementFollowupsFilterList
      ..clear()
      ..addAll(applyFilter(FollowUpServices().finishAndAgreementFollowups));
    archivedFollowupsFilterList
      ..clear()
      ..addAll(applyFilter(FollowUpServices().archivedFollowups));

    Get.back();
    update();
  }

  void searchBar(String value) {
    final search = value.toLowerCase();

    if (value.isNotEmpty) {
      initialFollowupsFilterList.assignAll(
        FollowUpServices().initialFollowups.where((f) =>
            f.customerName.toLowerCase().contains(search) ||
            f.customerPhone.toLowerCase().contains(search) ||
            f.productName.toLowerCase().contains(search) ||
            f.sellerName.toLowerCase().contains(search) ||
            f.sellerPhone.toLowerCase().contains(search) ||
            f.createdAt.toString().toLowerCase().contains(search)),
      );

      informFollowupsFilterList.assignAll(
        FollowUpServices().informFollowups.where((f) =>
            f.customerName.toLowerCase().contains(search) ||
            f.customerPhone.toLowerCase().contains(search) ||
            f.productName.toLowerCase().contains(search) ||
            f.sellerName.toLowerCase().contains(search) ||
            f.sellerPhone.toLowerCase().contains(search) ||
            f.createdAt.toString().toLowerCase().contains(search)),
      );

      finishAndAgreementFollowupsFilterList.assignAll(
        FollowUpServices().finishAndAgreementFollowups.where((f) =>
            f.customerName.toLowerCase().contains(search) ||
            f.customerPhone.toLowerCase().contains(search) ||
            f.productName.toLowerCase().contains(search) ||
            f.sellerName.toLowerCase().contains(search) ||
            f.sellerPhone.toLowerCase().contains(search) ||
            f.createdAt.toString().toLowerCase().contains(search)),
      );

      archivedFollowupsFilterList.assignAll(
        FollowUpServices().archivedFollowups.where((f) =>
            f.customerName.toLowerCase().contains(search) ||
            f.customerPhone.toLowerCase().contains(search) ||
            f.productName.toLowerCase().contains(search) ||
            f.sellerName.toLowerCase().contains(search) ||
            f.sellerPhone.toLowerCase().contains(search) ||
            f.createdAt.toString().toLowerCase().contains(search)),
      );
    } else {
      initialFollowupsFilterList.assignAll(FollowUpServices().initialFollowups);
      informFollowupsFilterList.assignAll(FollowUpServices().informFollowups);
      finishAndAgreementFollowupsFilterList
          .assignAll(FollowUpServices().finishAndAgreementFollowups);
      archivedFollowupsFilterList
          .assignAll(FollowUpServices().archivedFollowups);
    }
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getAllFollowUps();
    getAllProducts();
    getAllCustomersAndSellers();
    initialFollowupsFilterList.assignAll(FollowUpServices().initialFollowups);
    informFollowupsFilterList.assignAll(FollowUpServices().informFollowups);
    finishAndAgreementFollowupsFilterList
        .assignAll(FollowUpServices().finishAndAgreementFollowups);
    archivedFollowupsFilterList.assignAll(FollowUpServices().archivedFollowups);
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    customerAndSellerIdController.dispose();
    customerNameController.dispose();
    customerphoneController.dispose();
    itemIdController.dispose();
    customerTypeController.dispose();
    customerNotesController.dispose();
    super.onClose();
  }
}
