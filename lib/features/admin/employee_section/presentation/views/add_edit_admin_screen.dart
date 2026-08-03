import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/validator/validator.dart';
import '../controllers/add_admin_controller.dart';

class AddEditAdminScreen extends GetView<AddAdminController> {
  const AddEditAdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = controller.isEdit ? 'editAdmin'.tr : 'addNewAdmin'.tr;

    return Scaffold(
      appBar: CustomAppBar(title: title, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Form(
          key: controller.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              CustomTextField(
                isRequired: true,
                controller: controller.nameController,
                label: 'name',
                hintText: 'name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'requiredField'.tr : null,
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                isRequired: true,
                controller: controller.emailController,
                label: 'email',
                hintText: 'test@mail.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validators.validateEmail(
                  v,
                  Get.locale?.languageCode ?? 'ar',
                ),
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: controller.phoneController,
                label: 'phone',
                hintText: 'phone',
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 12.h),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.developmentRole.value,
                  decoration: const InputDecoration(
                    labelText: 'الدور في تطوير التطبيق',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('بدون')),
                    DropdownMenuItem(
                      value: 'owner',
                      child: Text('صاحب التطبيق'),
                    ),
                    DropdownMenuItem(
                      value: 'developer',
                      child: Text('مبرمج'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.developmentRole.value = value;
                    }
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Obx(
                () => CustomTextField(
                  isRequired: !controller.isEdit,
                  controller: controller.passwordController,
                  label: 'password',
                  hintText: controller.isEdit ? 'password' : 'password',
                  obscureText: controller.passwordObscured.value,
                  onChanged: (_) => controller.formKey.currentState?.validate(),
                  suffixIcon: IconButton(
                    tooltip: controller.passwordObscured.value
                        ? 'إظهار كلمة المرور'
                        : 'إخفاء كلمة المرور',
                    icon: Icon(
                      controller.passwordObscured.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => controller.passwordObscured.toggle(),
                  ),
                  validator: (v) {
                    if (controller.isEdit && (v == null || v.isEmpty)) {
                      return null;
                    }
                    return Validators.validatePassword(
                      v,
                      Get.locale?.languageCode ?? 'ar',
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Obx(
                () => CustomTextField(
                  isRequired: !controller.isEdit,
                  controller: controller.passwordConfirmationController,
                  label: 'passwordConfirmation',
                  hintText: 'passwordConfirmation',
                  obscureText: controller.passwordConfirmationObscured.value,
                  onChanged: (_) => controller.formKey.currentState?.validate(),
                  suffixIcon: IconButton(
                    tooltip: controller.passwordConfirmationObscured.value
                        ? 'إظهار تأكيد كلمة المرور'
                        : 'إخفاء تأكيد كلمة المرور',
                    icon: Icon(
                      controller.passwordConfirmationObscured.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        controller.passwordConfirmationObscured.toggle(),
                  ),
                  validator: (v) {
                    if (controller.isEdit &&
                        controller.passwordController.text.isEmpty &&
                        (v == null || v.isEmpty)) {
                      return null;
                    }
                    if (v != controller.passwordController.text) {
                      return 'passwordMismatch'.tr;
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 24.h),
              AppButton(
                isLoading: controller.isLoading,
                text: controller.isEdit ? 'save'.tr : 'add'.tr,
                onPressed: () => controller.submit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
