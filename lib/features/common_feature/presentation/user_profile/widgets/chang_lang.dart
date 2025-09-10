import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../controllers/profile_controller.dart';
import 'build_sidebar_item.dart';
import 'chang_lang_bottom_sheet.dart';

Widget changLang(ProfileController controller) {
  return GestureDetector(
    onTap: () {
      changLangBottomSheet(controller);
    },
    child: Row(
      children: [
        buildSidebarItem(
          'language'.tr,
          Icons.language,
          () {
            changLangBottomSheet(controller);
          },
        ),
        const Spacer(),
        Row(
          children: [
            Text(
              controller.languageController.getLang() == 'ar'
                  ? 'العربية'
                  : 'English',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              controller.languageController.getLang() == 'ar'
                  ? Icons.keyboard_arrow_left_sharp
                  : Icons.keyboard_arrow_right_sharp,
              size: 30.sp,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ],
    ),
  );
}
