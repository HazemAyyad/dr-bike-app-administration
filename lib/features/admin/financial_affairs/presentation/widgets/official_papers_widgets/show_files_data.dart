import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/official_papers_models/safes_model.dart';
import '../../controllers/finacial_service.dart';
import '../../controllers/official_papers_controller.dart';
import 'add_paper.dart';

class ShowFilesData extends GetView<OfficialPapersController> {
  const ShowFilesData({Key? key, required this.data}) : super(key: key);

  final FilesModel data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data.name,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.secondaryColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.back();
                      controller.isEdit = false;
                      controller.pictureNameController.clear();
                      controller.pictureDescriptionController.clear();
                      controller.selectedFile.value = null;
                      controller.getPaperData();
                      Get.dialog(AddPaper(fileId: data.id.toString()));
                    },
                    icon: const Icon(
                      Icons.playlist_add,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (FinacialService().filesPapers.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: ShowNoData()),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = FinacialService().filesPapers[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 5.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9.r),
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: GestureDetector(
                              onTap: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  barrierColor: Colors.black.withAlpha(128),
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder: (context, anim1, anim2) {
                                    return FullScreenZoomImage(
                                      imageUrl: data.paperImage,
                                    );
                                  },
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: data.paperImage,
                                cacheManager: CacheManager(
                                  Config(
                                    'imagesCache',
                                    stalePeriod: const Duration(days: 7),
                                    maxNrOfCacheObjects: 100,
                                  ),
                                ),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  height: 40.h,
                                  width: 55.w,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primaryColor),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              data.paperName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    color: AppColors.graywhiteColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                // padding: EdgeInsets.all(5.r),
                                decoration: BoxDecoration(
                                  borderRadius: Get.locale!.languageCode == 'ar'
                                      ? BorderRadius.only(
                                          bottomRight: Radius.circular(4.r),
                                          topRight: Radius.circular(4.r),
                                        )
                                      : BorderRadius.only(
                                          bottomLeft: Radius.circular(4.r),
                                          topLeft: Radius.circular(4.r),
                                        ),
                                  color: AppColors.graywhiteColor,
                                ),
                                height: 45.h,
                                width: 45.w,
                                child: Center(
                                  child: Text(
                                    data.fileName,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: AppColors.secondaryColor,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Container(
                                // padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  borderRadius: Get.locale!.languageCode == 'ar'
                                      ? BorderRadius.only(
                                          bottomLeft: Radius.circular(4.r),
                                          topLeft: Radius.circular(4.r),
                                        )
                                      : BorderRadius.only(
                                          bottomRight: Radius.circular(4.r),
                                          topRight: Radius.circular(4.r),
                                        ),
                                  color: AppColors.graywhiteColor,
                                ),
                                height: 45.h,
                                width: 45.w,
                                child: Center(
                                  child: Text(
                                    data.treasuryName,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: AppColors.secondaryColor,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: FinacialService().filesPapers.length,
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
