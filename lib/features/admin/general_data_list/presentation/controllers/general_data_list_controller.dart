import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class GeneralDataListController extends GetxController {
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
  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  void changeTab(int index) {
    currentTab.value = index;
    fetchOrders();
  }

  void fetchOrders() {
    // Simulate fetching orders based on the current tab
    generalDatalist.clear();
    if (currentTab.value == 0) {
      generalDatalist.addAll(
        [
          {
            'customerName': 'ماجد احمد',
            'customerPhoneNumber': '+9772548632',
            'job': 'مهندس',
            'image': AssetsManger.noImageNet,
          },
          {
            'customerName': 'ماجد احمد',
            'customerPhoneNumber': '+9772548632',
            'job': 'مهندس',
            'image': AssetsManger.noImageNet,
          },
          {
            'customerName': 'ماجد احمد',
            'customerPhoneNumber': '+9772548632',
            'job': 'مهندس',
            'image': AssetsManger.noImageNet,
          },
          {
            'customerName': 'ماجد احمد',
            'customerPhoneNumber': '+9772548632',
            'job': 'مهندس',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    } else if (currentTab.value == 1) {
      generalDatalist.addAll(
        [
          {
            'customerName': 'ماجد احمد',
            'customerPhoneNumber': '+9772548632',
            'job': 'مهندس',
            'image': AssetsManger.noImageNet,
          },
          {
            'customerName': 'ماجد احمد',
            'customerPhoneNumber': '+9772548632',
            'job': 'مهندس',
            'image': AssetsManger.noImageNet,
          },
        ],
      );
    }
  }

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
