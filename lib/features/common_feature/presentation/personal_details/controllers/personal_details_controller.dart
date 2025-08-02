import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../domain/usecases/user_profile_usecase.dart';

class PersonalDetailsController extends GetxController {
  UserProfileUseCase userProfileUseCase;
  PersonalDetailsController({required this.userProfileUseCase});
  final formKey = GlobalKey<FormState>();
  // متغيرات للبيانات الشخصية

  final nameController = TextEditingController();
  final emailController = TextEditingController(text: 'Bt1bA@example.com');
  final phoneController = TextEditingController(text: '+970123456789');
  final alternativePhoneController =
      TextEditingController(text: '+970123456789');
  final cityController = TextEditingController();
  final addressController = TextEditingController();

  final city = 'نابلس'.obs;

  // متغيرات للتحقق من صحة النموذج
  final isPhoneValid = true.obs;

  RxBool isLoading = false.obs;

  void updateUserProfile(BuildContext context) async {
    isLoading(true);
    String token = await UserData.getUserToken();

    final result = await userProfileUseCase.call(
      token: token,
      name: nameController.text,
      phone: phoneController.text,
      subPhone: alternativePhoneController.text,
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
}
