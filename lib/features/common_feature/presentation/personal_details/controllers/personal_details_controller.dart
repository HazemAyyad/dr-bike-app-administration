import 'package:doctorbike/core/services/user_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/helpers/api_error_message.dart';
import '../../../../../core/helpers/helpers.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/validator/validator.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../domain/usecases/get_user_data_usecase.dart';
import '../../../domain/usecases/user_profile_usecase.dart';

class PersonalDetailsController extends GetxController {
  final UserProfileUseCase userProfileUseCase;
  final GetUserDataUsecase getUserDataUsecase;

  PersonalDetailsController({
    required this.userProfileUseCase,
    required this.getUserDataUsecase,
  });

  final formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController subPhoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final city = 'القدس'.obs;
  final isPhoneValid = true.obs;
  RxBool isLoading = false.obs;
  RxBool isProfileLoaded = false.obs;

  UserModel? userData;

  bool get isAdmin =>
      userData?.user.type == 'admin' || userType == 'admin';

  String? _compactPhone(String raw, {required bool required}) {
    final compact = PhoneFormatHelper.forApi(raw).replaceAll(' ', '');
    if (RegExp(r'^\+?[0-9]{12}$').hasMatch(compact)) {
      return compact;
    }
    return required ? null : '';
  }

  void _applyUserToForm(UserModel userdata) {
    nameController.text = userdata.user.name;
    emailController.text = userdata.user.email;
    phoneController.text = PhoneFormatHelper.forApi(userdata.user.phone);
    subPhoneController.text = userdata.user.subPhone != null &&
            userdata.user.subPhone!.trim().isNotEmpty
        ? PhoneFormatHelper.forApi(userdata.user.subPhone!)
        : '';
    city.value = userdata.user.city?.trim().isNotEmpty == true
        ? userdata.user.city!.trim()
        : (isAdmin ? '' : 'القدس');
    addressController.text = userdata.user.address ?? '';
  }

  Future<void> _loadCachedProfile() async {
    final userdata = await UserData.getSavedUser();
    if (userdata == null) return;
    userData = userdata;
    _applyUserToForm(userdata);
    isProfileLoaded(true);
    update();
  }

  Future<void> getUserData() async {
    try {
      final result = await getUserDataUsecase.call();
      await UserData.saveUser(result);
      userData = result;
      _applyUserToForm(result);
      userName = result.user.name;
      isProfileLoaded(true);
      update();
    } catch (_) {
      if (!isProfileLoaded.value) {
        await _loadCachedProfile();
      }
    }
  }

  Future<void> _loadProfile() async {
    isLoading(true);
    await _loadCachedProfile();
    final token = await UserData.getUserToken();
    if (token.isNotEmpty) {
      await getUserData();
    }
    isLoading(false);
    update();
  }

  void updateUserProfile(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'pleaseFillAllFields'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!isAdmin &&
        (phoneController.text.isEmpty || city.value.isEmpty)) {
      Get.snackbar(
        'error'.tr,
        'pleaseFillAllFields'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final emailError =
        Validators.validateEmail(emailController.text, Get.locale!.languageCode);
    if (emailError != null) {
      Get.snackbar('error'.tr, emailError, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    String? phoneForApi;
    if (phoneController.text.trim().isNotEmpty) {
      phoneForApi = _compactPhone(phoneController.text, required: true);
      if (phoneForApi == null) {
        Get.snackbar(
          'error'.tr,
          'invalidPhoneNumber'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } else if (!isAdmin) {
      Get.snackbar(
        'error'.tr,
        'invalidPhoneNumber'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final subPhoneForApi = subPhoneController.text.trim().isEmpty
        ? ''
        : (_compactPhone(subPhoneController.text, required: false) ?? '');

    if (subPhoneController.text.trim().isNotEmpty && subPhoneForApi.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'invalidPhoneNumber'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading(true);

    final result = await userProfileUseCase.call(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneForApi ?? '',
      subPhone: subPhoneForApi,
      city: city.value.trim(),
      address: addressController.text.trim(),
    );
    result.fold(
      (failure) {
        final message = _profileFailureMessage(failure);
        if (kDebugMode) {
          debugPrint('[ProfileUpdate] FAILED');
          debugPrint('[ProfileUpdate] failure type: ${failure.runtimeType}');
          debugPrint('[ProfileUpdate] errMessage: ${failure.errMessage}');
          debugPrint('[ProfileUpdate] data: ${failure.data}');
        }
        Helpers.showCustomDialogError(
          context: context,
          title: 'error'.tr,
          message: message,
        );
      },
      (success) {
        _loadProfile();
        Get.back();
        Helpers.showCustomDialogSuccess(
          context: context,
          title: 'success'.tr,
          message: 'dataUpdatedSuccessfully'.tr,
        );
        Future.delayed(
          const Duration(seconds: 1),
          () {
            Get.back();
          },
        );
      },
    );
    isLoading(false);
  }

  String _profileFailureMessage(Failure failure) {
    final data = failure.data;
    final parts = <String>[];

    if (data is Map) {
      final errors = apiErrorMessageFromPayload(
        data['errors'],
        fallback: '',
      );
      if (errors.isNotEmpty) parts.add(errors);

      for (final key in ['details', 'detail', 'debug_message', 'error']) {
        final value = data[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          parts.add(value);
        }
      }

      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        parts.add(message);
      }

      if (kDebugMode) {
        parts.add('RAW: $data');
      }
    } else if (data != null) {
      parts.add(data.toString());
    }

    if (parts.isEmpty) {
      parts.add(
        apiErrorMessageFromPayload(
          failure.errMessage,
          fallback: 'error'.tr,
        ),
      );
    }

    return parts.join('\n\n');
  }

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }
}
