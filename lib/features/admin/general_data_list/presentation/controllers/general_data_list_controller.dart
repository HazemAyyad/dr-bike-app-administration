import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/usecases/get_customers_usecase.dart';
import 'general_data_serves.dart';

class GeneralDataListController extends GetxController {
  final GeneralDataServes generalDataServes;
  final GetCustomersUseCase getCustomersUseCase;

  GeneralDataListController({
    required this.generalDataServes,
    required this.getCustomersUseCase,
  });

  final GlobalKey formKey = GlobalKey();

  TextEditingController toDateController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController employeeNameController = TextEditingController();

  final currentTab = 0.obs;

  TextEditingController customerNameController = TextEditingController();
  TextEditingController selectedCustomerType = TextEditingController();

  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController secondPhoneNumberController = TextEditingController();
  TextEditingController facebookNameController = TextEditingController();
  TextEditingController facebookLinkController = TextEditingController();
  TextEditingController instagramNameController = TextEditingController();
  TextEditingController instagramLinkController = TextEditingController();
  TextEditingController closePeople = TextEditingController();

  Rx<XFile?> personalIdImage = Rx<XFile?>(null);
  Rx<XFile?> carLicenseImage = Rx<XFile?>(null);
  TextEditingController residenceLocationController = TextEditingController();
  TextEditingController workController = TextEditingController();
  TextEditingController workLocationController = TextEditingController();
  TextEditingController closestPersonNumberController = TextEditingController();
  TextEditingController closestPersonWorkController = TextEditingController();

  final List<Map<String, dynamic>> generalDatalist = [];

  final tabs = ['merchants', 'customers'];

  void changeTab(int index) {
    currentTab.value = index;
  }

  final isLoading = false.obs;

  List<String> customerTypeList = ['جملة', 'قطاعي'];

  List<String> closePeopleList = ['محمد علي', 'محمود علي', 'محمد رفعت'];

  void addNewCustomer() {
    if ((formKey.currentState as FormState?)?.validate() ?? false) {
      Get.snackbar(
        'success'.tr,
        'customerAddedSuccessfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  //Get General Data List

  void getGeneralDataList({bool isSellers = false, bool loding = false}) async {
    generalDataServes.employeeDataList.isEmpty ||
            generalDataServes.sellersDataList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    loding ? isLoading(true) : null;

    final employeeResult = await getCustomersUseCase.call(isSellers: isSellers);
    generalDataServes.employeeDataList.assignAll(employeeResult);

    final sellersResult = await getCustomersUseCase.call(isSellers: true);
    generalDataServes.sellersDataList.assignAll(sellersResult);
    isLoading(false);
  }

  @override
  void onInit() {
    super.onInit();
    getGeneralDataList();
  }

  @override
  void dispose() {
    super.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    customerNameController.dispose();
    phoneNumberController.dispose();
    selectedCustomerType.dispose();
    phoneNumberController.dispose();
    facebookNameController.dispose();
    facebookLinkController.dispose();
    instagramNameController.dispose();
    instagramLinkController.dispose();
    closePeople.dispose();
    carLicenseImage = Rx<XFile?>(null);
    personalIdImage = Rx<XFile?>(null);
    residenceLocationController.dispose();
    workController.dispose();
    workLocationController.dispose();
    closestPersonNumberController.dispose();
    closestPersonWorkController.dispose();
  }
}
