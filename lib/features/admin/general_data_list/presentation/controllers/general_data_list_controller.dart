import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../data/models/person_data_model.dart';
import '../../domain/entity/add_person_entity.dart';
import '../../domain/usecases/add_person_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/get_person_data_usecase.dart';
import 'general_data_serves.dart';

class GeneralDataListController extends GetxController {
  final GeneralDataServes generalDataServes;
  final GetCustomersUseCase getCustomersUseCase;
  final AddPersonUseCase addPersonUseCase;
  final GetPersonDataUseCase getPersonDataUseCase;

  GeneralDataListController({
    required this.generalDataServes,
    required this.getCustomersUseCase,
    required this.addPersonUseCase,
    required this.getPersonDataUseCase,
  });

  final isEdit = false.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController toDateController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController employeeNameController = TextEditingController();

  final currentTab = 0.obs;

  TextEditingController customerNameController = TextEditingController();
  TextEditingController selectedCustomerType = TextEditingController();

  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController subPhoneNumberController = TextEditingController();
  TextEditingController facebookNameController = TextEditingController();
  TextEditingController facebookLinkController = TextEditingController();
  TextEditingController instagramNameController = TextEditingController();
  TextEditingController instagramLinkController = TextEditingController();
  TextEditingController closePeople = TextEditingController();

  List<File> personalIdImage = [];
  List<File> licenseImage = [];

  TextEditingController residenceLocationController = TextEditingController();
  TextEditingController workController = TextEditingController();
  TextEditingController workLocationController = TextEditingController();
  TextEditingController closestPersonNumberController = TextEditingController();
  TextEditingController closestPersonWorkController = TextEditingController();

  final List<Map<String, dynamic>> generalDatalist = [];

  final tabs = ['merchants', 'customers', 'completeData'];

  void changeTab(int index) {
    currentTab.value = index;
  }

  final isLoading = false.obs;

  final isEditLoading = false.obs;

  List<String> customerTypeList = ['wholesale', 'retail'];

  List<String> closePeopleList = ['محمد علي', 'محمود علي', 'محمد رفعت'];

  // add person
  void addPerson({
    required BuildContext context,
    String? customerId,
    String? sellerId,
  }) async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      final result = await addPersonUseCase.call(
        data: AddPersonEntity(
          isEdit: isEdit.value,
          name: customerNameController.text,
          personType:
              selectedCustomerType.text == 'wholesale' ? 'seller' : 'customer',
          phone: phoneNumberController.text,
          subPhone: subPhoneNumberController.text,
          facebookUsername: facebookNameController.text,
          facebookLink: facebookLinkController.text,
          instagramUsername: instagramNameController.text,
          instagramLink: instagramLinkController.text,
          relatedPeople: closePeople.text,
          iDImage: personalIdImage,
          licenseImage: licenseImage,
          address: residenceLocationController.text,
          jobTitle: workController.text,
          workAddress: workLocationController.text,
          relativePhone: closestPersonNumberController.text,
          relativeJobTitle: closestPersonWorkController.text,
        ),
        customerId: customerId ?? '',
        sellerId: sellerId ?? '',
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
          clearForm();
          Future.delayed(
            Duration(milliseconds: 500),
            () {
              getGeneralDataList(loding: true);
            },
          );
          Future.delayed(
            Duration(milliseconds: 1500),
            () {
              Get.back();
              Get.back();
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
  }

  //Get General Data List
  void getGeneralDataList({bool loding = false}) async {
    generalDataServes.employeeDataList.isEmpty ||
            generalDataServes.sellersDataList.isEmpty ||
            generalDataServes.inCompleteDataList.isEmpty
        ? isLoading(true)
        : isLoading(false);
    loding ? isLoading(true) : null;

    generalDataServes.employeeDataList
        .assignAll(await getCustomersUseCase.call(tab: 0));
    generalDataServes.sellersDataList
        .assignAll(await getCustomersUseCase.call(tab: 1));
    generalDataServes.inCompleteDataList
        .assignAll(await getCustomersUseCase.call(tab: 2));
    isLoading(false);
  }

  //Get Person Data
  final Rxn<PersonDataModel> personData = Rxn();
  void getPersonData({String? customerId, String? sellerId}) async {
    isEditLoading(true);
    personData.value = await getPersonDataUseCase.call(
      customerId: customerId ?? '',
      sellerId: sellerId ?? '',
    );
    customerNameController.text = personData.value!.name;
    phoneNumberController.text = personData.value!.phone;
    subPhoneNumberController.text = personData.value!.subPhone;
    facebookNameController.text = personData.value!.facebookUsername;
    facebookLinkController.text = personData.value!.facebookLink;
    instagramNameController.text = personData.value!.instagramUsername;
    instagramLinkController.text = personData.value!.instagramLink;
    closePeople.text = personData.value!.relatedPeople;
    residenceLocationController.text = personData.value!.address;
    workController.text = personData.value!.jobTitle;
    workLocationController.text = personData.value!.workAddress;
    closestPersonNumberController.text = personData.value!.relativePhone;
    closestPersonWorkController.text = personData.value!.relativeJobTitle;
    personalIdImage = personData.value!.iDImage;
    licenseImage = personData.value!.licenseImage;
    selectedCustomerType.text = personData.value!.personType.isNotEmpty
        ? personData.value!.personType == 'seller'
            ? 'wholesale'
            : 'retail'
        : '';
    isEditLoading(false);
    update();
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
    employeeNameController.dispose();
    customerNameController.dispose();
    phoneNumberController.dispose();
    subPhoneNumberController.dispose();
    selectedCustomerType.dispose();
    facebookNameController.dispose();
    facebookLinkController.dispose();
    instagramNameController.dispose();
    instagramLinkController.dispose();
    closePeople.dispose();
    residenceLocationController.dispose();
    workController.dispose();
    workLocationController.dispose();
    closestPersonNumberController.dispose();
    closestPersonWorkController.dispose();
  }

  void clearForm() {
    customerNameController.clear();
    selectedCustomerType.clear();
    phoneNumberController.clear();
    subPhoneNumberController.clear();
    facebookNameController.clear();
    facebookLinkController.clear();
    instagramNameController.clear();
    instagramLinkController.clear();
    closePeople.clear();
    residenceLocationController.clear();
    workController.clear();
    workLocationController.clear();
    closestPersonNumberController.clear();
    closestPersonWorkController.clear();
    personalIdImage.clear();
    licenseImage.clear();
    update();
  }
}
