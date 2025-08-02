import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/helpers/url_launcher.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../widgets/contact_button.dart';
import '../widgets/social_icon.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'contactUsTitle'.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? Colors.white
                    : AppColors.secondaryColor,
              ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                'contactUsDesc'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w400,
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.customGreyColor,
                    ),
              ),
            ),
            SizedBox(height: 50.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildContactButton(
                  context,
                  icon: Icons.phone,
                  label: 'contactUsTitle'.tr,
                  onTap: () async {
                    final Uri telUri =
                        Uri(scheme: 'tel', path: Constants.phoneNamber);
                    urlLauncher(telUri.toString());
                  },
                ),
                SizedBox(width: 50.w),
                buildContactButton(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: 'message'.tr,
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: Constants.email,
                      query:
                          'subject=Contact&body=Hello, I would like to contact you.',
                    );
                    urlLauncher(emailUri.toString());
                  },
                ),
              ],
            ),
            SizedBox(height: 50.h),
            Text(
              'or'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.customGreyColor,
                  ),
            ),
            SizedBox(height: 50.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildSocialIcon(
                  context,
                  iconAsset: AssetsManger.x,
                  onTap: () async {
                    urlLauncher(Constants.xUrl);
                  },
                ),
                SizedBox(width: 20.w),
                buildSocialIcon(
                  context,
                  iconAsset: AssetsManger.instagram,
                  onTap: () async {
                    urlLauncher(Constants.instagramUrl);
                  },
                ),
                SizedBox(width: 20.w),
                buildSocialIcon(
                  context,
                  iconAsset: AssetsManger.whatsapp,
                  onTap: () async {
                    urlLauncher(Constants.whatsAppUrl);
                  },
                ),
              ],
            ),
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}
