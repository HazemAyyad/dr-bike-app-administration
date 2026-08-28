import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../../../data/models/official_papers_models/pictures_model.dart';
import '../../controllers/official_papers_controller.dart';
import '../financial_image_cache.dart';
import '../financial_operational_ui.dart';
import 'picture_details.dart';

class PictureCard extends GetView<OfficialPapersController> {
  const PictureCard({Key? key, required this.data}) : super(key: key);
  final PictureModel data;

  @override
  Widget build(BuildContext context) => FinancialOperationalCard(
        onTap: () => Get.dialog(PictureDetails(picture: data)),
        onLongPress: () => _confirmArchive(context),
        child: Padding(
          padding: EdgeInsets.all(7.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(
                      cacheManager: FinancialImageCache.instance,
                      imageUrl: data.file.contains('.mp4')
                          ? AssetsManager.noImageNet
                          : data.file,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SkeletonBlock(
                          width: double.infinity,
                          height: double.infinity,
                          radius: 10),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.operationalSurface,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: AppColors.operationalPurple),
                      ),
                    ),
                    if (data.file.contains('.mp4'))
                      Center(
                        child: Icon(Icons.play_circle_fill_rounded,
                            size: 38.sp, color: Colors.white),
                      ),
                    PositionedDirectional(
                      top: 5.h,
                      end: 5.w,
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: Icon(Icons.open_in_full_rounded,
                            size: 12.sp, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
              SizedBox(height: 7.h),
              Text(data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.operationalNavy)),
              SizedBox(height: 3.h),
              Row(children: [
                Icon(Icons.schedule_rounded,
                    size: 11.sp, color: AppColors.customGreyColor5),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(showData(data.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 8.5.sp, color: AppColors.customGreyColor5)),
                ),
              ]),
              if (data.description.trim().isNotEmpty) ...[
                SizedBox(height: 3.h),
                Text(data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        height: 1.25,
                        fontSize: 8.5.sp,
                        color: AppColors.customGreyColor5)),
              ],
            ],
          ),
        ),
      );

  void _confirmArchive(BuildContext context) {
    Get.dialog(AlertDialog(
      title: Text('delete_picture'.tr),
      content: const Text('سيتم نقل الصورة إلى الأرشيف دون حذف الملف.'),
      actions: [
        AppButton(isSafeArea: false, onPressed: Get.back, text: 'cancel'.tr),
        AppButton(
          isSafeArea: false,
          isLoading: controller.isLoading,
          onPressed: () => controller.cancelPaper(
              isPicture: true, paperId: data.id.toString()),
          text: 'yes'.tr,
          color: Colors.red,
        ),
      ],
    ));
  }
}
