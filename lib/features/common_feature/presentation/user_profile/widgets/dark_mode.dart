import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/profile_controller.dart';
import 'build_sidebar_item.dart';

class DarkMode extends GetView<ProfileController> {
  const DarkMode({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BuildSidebarItem(
          title: 'darkMode'.tr,
          icon: Icons.dark_mode_outlined,
          route: null,
        ),
        const Spacer(),
        Obx(
          () => Switch(
            value: ThemeService.isDark.value,
            activeColor: AppColors.primaryColor,
            inactiveThumbColor: AppColors.secondaryColor,
            onChanged: (value) {
              ThemeService.isDark.value = value;
              final mode = value ? ThemeMode.dark : ThemeMode.light;
              Get.changeThemeMode(mode);
              ThemeService.instance.themeMode = mode;
              controller.update();
            },
          ),
        )
      ],
    );
  }
}
