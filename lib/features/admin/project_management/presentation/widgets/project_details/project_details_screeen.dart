import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import 'project_status.dart';
import 'sup_text_and_dis.dart';

class ProjectDetailsScreeen extends StatelessWidget {
  const ProjectDetailsScreeen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    dynamic ordar = Get.arguments;
    return Scaffold(
      appBar: const CustomAppBar(title: 'projectDetails', action: false),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        children: [
          SizedBox(height: 10.h),
          supTextAndDis(context, 'projectName', ordar['projectName']),
          supTextAndDis(
            context,
            'projectCost',
            "${ordar['projectCost']} ${'currency'.tr}",
          ),
          supTextAndDis(context, 'paymentMethod', ordar['paymentMethod']),
          supTextAndDis(context, 'projectPartners', ordar['projectPartners']),
          ordar['projectPartners'].isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(
                    right: Get.locale!.languageCode == 'ar' ? 50.w : 0.w,
                    left: Get.locale!.languageCode == 'ar' ? 0.w : 50.w,
                  ),
                  child: Column(
                    children: [
                      supTextAndDis(
                        context,
                        'partnerShare',
                        "${ordar['partnerShare']} ${'currency'.tr}",
                      ),
                      supTextAndDis(context, 'partnerPercentage',
                          ordar['partnerPercentage']),
                    ],
                  ),
                ),
          supTextAndDis(context, 'notes', ordar['notes']),
          supTextAndDis(context, 'projectDocuments', ordar['projectDocuments']),
          supTextAndDis(context, 'totalSales', ordar['totalSales']),
          supTextAndDis(context, 'projectStatus', ordar['projectStatus']),
          SizedBox(height: 10.h),
          // project Status
          projectStatus(),
          SizedBox(height: 10.h),
          Text(
            'projectImagesOrProducts'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor4,
                ),
          ),
          SizedBox(height: 5.h),
          // project Images
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                ordar['projectOrProductsImages'].isEmpty
                    ? ''
                    : ordar['projectOrProductsImages'],
              ),
              Image.asset(
                ordar['projectOrProductsImages'].isEmpty
                    ? ''
                    : ordar['projectOrProductsImages'],
              ),
            ],
          )
        ],
      ),
    );
  }
}
