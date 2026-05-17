import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/services/banks_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/banks_settings_controller.dart';

class BanksSettingsScreen extends GetView<BanksSettingsController> {
  const BanksSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final svc = Get.find<BanksService>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: 'banksManagement',
        action: false,
        backgroundColor: Color(0xFFF5F5F5),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'banksAutoShortcutHint'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8.h),
                CustomTextField(
                  label: 'bankName',
                  hintText: 'bankNameExample',
                  controller: controller.nameController,
                ),
                SizedBox(height: 12.h),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controller.save,
                          child: Text(
                            controller.editingId.value != null
                                ? 'save'.tr
                                : 'add'.tr,
                          ),
                        ),
                      ),
                      if (controller.editingId.value != null) ...[
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: controller.clearForm,
                          child: Text('cancel'.tr),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (svc.isLoading.value && svc.banks.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: svc.loadBanks,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: svc.banks.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final bank = svc.banks[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          bank.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.primaryColor,
                              onPressed: () => controller.startEdit(bank),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => controller.remove(bank.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
