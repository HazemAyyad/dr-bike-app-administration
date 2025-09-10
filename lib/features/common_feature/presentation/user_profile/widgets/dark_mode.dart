import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/profile_controller.dart';
import 'build_sidebar_item.dart';

Row darkMode(ProfileController controller) {
  return Row(
    children: [
      buildSidebarItem('darkMode'.tr, Icons.dark_mode_outlined, null),
      const Spacer(),
      Obx(
        () => Switch(
          value: ThemeService.isDark.value,
          activeColor: AppColors.primaryColor,
          inactiveThumbColor: AppColors.secondaryColor,
          onChanged: (value) {
            ThemeService.isDark.value = value;
            final mode = value ? ThemeMode.dark : ThemeMode.light;
            ThemeService.instance.themeMode = mode;
            Get.changeThemeMode(mode);
            controller.update();
          },
        ),
      ),
    ],
  );
}
