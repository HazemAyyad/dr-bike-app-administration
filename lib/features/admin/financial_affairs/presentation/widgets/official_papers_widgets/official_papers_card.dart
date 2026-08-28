import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../data/models/official_papers_models/papers_model.dart';
import '../../controllers/official_papers_controller.dart';
import '../../views/official_papers_screens/paper_details_screen.dart';
import '../financial_operational_ui.dart';
import '../financial_image_cache.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';

class OfficialPapersCard extends GetView<OfficialPapersController> {
  const OfficialPapersCard({Key? key, required this.data}) : super(key: key);

  final PaperModel data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => PaperDetailsScreen(paper: data));
      },
      onLongPress: () {
        Get.dialog(
          Dialog(
            backgroundColor: ThemeService.isDark.value
                ? AppColors.darkColor
                : AppColors.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'delete_document'.tr,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.blackColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AppButton(
                          isSafeArea: false,
                          onPressed: () {
                            Get.back();
                          },
                          text: 'cancel'.tr,
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: AppButton(
                          isLoading: controller.isLoading,
                          isSafeArea: false,
                          onPressed: () {
                            controller.cancelPaper(
                              paperId: data.paperId.toString(),
                            );
                          },
                          text: 'yes'.tr,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: FinancialOperationalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: CachedNetworkImage(
                  cacheManager: FinancialImageCache.instance,
                  imageUrl: data.img.isNotEmpty
                      ? data.img.first
                      : AssetsManager.noImageNet,
                  width: 42.w,
                  height: 38.h,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 42.w,
                    height: 38.h,
                    color: AppColors.operationalSurface,
                    child: Icon(Icons.description_outlined,
                        color: AppColors.operationalPurple, size: 19.sp),
                  ),
                  placeholder: (_, __) =>
                      SkeletonBlock(width: 42.w, height: 38.h, radius: 9),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.paperName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.operationalNavy,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 2.h),
                    Text(showData(data.createdAt),
                        maxLines: 1,
                        style: TextStyle(
                            color: AppColors.customGreyColor5,
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              FinancialMiniChip(
                label: '${data.img.length}',
                color: AppColors.operationalPurple,
                icon: Icons.attach_file_rounded,
              ),
            ]),
            SizedBox(height: 6.h),
            _PaperLocationPath(data: data),
          ],
        ),
      ),
    );
  }
}

class _PaperLocationPath extends StatelessWidget {
  const _PaperLocationPath({required this.data});
  final PaperModel data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.operationalSurface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(children: [
        Expanded(
            child: _LocationPart(
                label: 'الخزنة',
                value: data.treasuryName,
                icon: Icons.account_balance_outlined)),
        _arrow(),
        Expanded(
            child: _LocationPart(
                label: 'الصندوق',
                value: data.fileBoxName,
                icon: Icons.inventory_2_outlined)),
        _arrow(),
        Expanded(
            child: _LocationPart(
                label: 'الملف',
                value: data.fileName,
                icon: Icons.folder_outlined)),
      ]),
    );
  }

  Widget _arrow() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Icon(Icons.chevron_right_rounded,
            size: 14.sp, color: AppColors.customGreyColor5),
      );
}

class _LocationPart extends StatelessWidget {
  const _LocationPart(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 13.sp, color: AppColors.operationalPurple),
        SizedBox(width: 3.w),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 7.5.sp,
                    color: AppColors.customGreyColor5,
                    height: 1)),
            SizedBox(height: 2.h),
            Text(value.isEmpty ? 'غير محدد' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.operationalNavy,
                    height: 1)),
          ]),
        ),
      ]);
}
