import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../domain/usecases/get_user_data_usecase.dart';
import '../../../domain/usecases/user_profile_usecase.dart';

class PersonalDetailsController extends GetxController {
  final UserProfileUseCase userProfileUseCase;
  final GetUserDataUsecase getUserDataUsecase;
  PersonalDetailsController(
      {required this.userProfileUseCase, required this.getUserDataUsecase});
  final formKey = GlobalKey<FormState>();
  // متغيرات للبيانات الشخصية

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final alternativePhoneController =
      TextEditingController(text: '+970123456789');
  final cityController = TextEditingController();
  final addressController = TextEditingController();

  final city = 'نابلس'.obs;

  // متغيرات للتحقق من صحة النموذج
  final isPhoneValid = true.obs;

  RxBool isLoading = false.obs;

  void updateUserProfile(BuildContext context) async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        city.value.isEmpty ||
        addressController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'pleaseFillAllFields'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isLoading(true);

    final result = await userProfileUseCase.call(
      name: nameController.text,
      phone: phoneController.text.split(' ').join(''),
      subPhone: alternativePhoneController.text.split(' ').join(''),
      city: city.value,
      address: addressController.text,
    );
    result.fold(
      (failure) {
        Helpers.showCustomDialogError(
          context: context,
          title: failure.errMessage,
          message: failure.data['errors']
              .toString()
              .split('[')
              .last
              .split(']')
              .first,
        );
      },
      (success) {
        // getUserData();
        Get.back();
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: 'dataUpdatedSuccessfully'.tr,
        );
        Future.delayed(
          const Duration(seconds: 2),
          () {
            Get.back();
          },
        );
      },
    );
    isLoading(false);
  }

  // void getUserData() async {
  //   final result = await getUserDataUsecase.call();
  //   // await UserData.saveToken(result);
  //   // print(result.user.name);
  //   // userName = result.user.name;
  // }

  @override
  void onInit() async {
    final userdata = await UserData.getSavedUser();
    if (userdata != null) {
      nameController.text = userdata.user.name;
      emailController.text = userdata.user.email;
      phoneController.text = userdata.user.phone;
      alternativePhoneController.text = userdata.user.subPhone ?? '';
      city.value = userdata.user.city ?? 'نابلس';
      addressController.text = userdata.user.address ?? '';
    }
    super.onInit();
  }
}
