import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../employee_tasks/presentation/views/task_details_screen.dart';
import '../../../data/models/official_papers_models/papers_model.dart';
import '../../controllers/official_papers_controller.dart';
import 'add_paper.dart';

class PaperDetails extends GetView<OfficialPapersController> {
  const PaperDetails({Key? key, required this.paper}) : super(key: key);

  final PaperModel paper;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  const SizedBox.shrink(),
                  Text(
                    'details'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.secondaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_document,
                      color: AppColors.primaryColor,
                      size: 30,
                    ),
                    onPressed: () {
                      controller.isEdit = true;
                      controller.getPaperData(paper: paper);
                      Get.dialog(const AddPaper());
                    },
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'paperName',
                      discription: paper.paperName,
                    ),
                  ),
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'safe_name',
                      discription: paper.treasuryName,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'file_box_name',
                      discription: paper.fileBoxName,
                    ),
                  ),
                  Flexible(
                    child: SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: 'file_name',
                      discription: paper.fileName,
                    ),
                  ),
                ],
              ),
              if (paper.img.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SupTextAndDiscr(
                      titleColor: AppColors.primaryColor,
                      title: '${'images'.tr} ${'or'.tr} ${'video'.tr}',
                      discription: '',
                    ),
                    SizedBox(height: 5.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...paper.img.map(
                            (e) => e.contains('.mp4')
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: GestureDetector(
                                      onTap: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          barrierLabel: 'Dismiss',
                                          barrierColor:
                                              Colors.black.withAlpha(128),
                                          transitionDuration:
                                              const Duration(milliseconds: 300),
                                          pageBuilder: (context, anim1, anim2) {
                                            return FullScreenZoomImage(
                                                imageUrl: e);
                                          },
                                        );
                                      },
                                      child: Icon(
                                        Icons.video_library_rounded,
                                        size: 80.sp,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: GestureDetector(
                                      onTap: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          barrierLabel: 'Dismiss',
                                          barrierColor:
                                              Colors.black.withAlpha(128),
                                          transitionDuration:
                                              const Duration(milliseconds: 300),
                                          pageBuilder: (context, anim1, anim2) {
                                            return FullScreenZoomImage(
                                              imageUrl: e,
                                            );
                                          },
                                        );
                                      },
                                      child: CachedNetworkImage(
                                        imageUrl: e,
                                        cacheManager: CacheManager(
                                          Config(
                                            'imagesCache',
                                            stalePeriod:
                                                const Duration(days: 7),
                                            maxNrOfCacheObjects: 100,
                                          ),
                                        ),
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          height: 150.h,
                                          width: 150.w,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                              filterQuality: FilterQuality.low,
                                            ),
                                          ),
                                        ),
                                        placeholder: (context, url) =>
                                            const Center(
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
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              if (paper.note.isNotEmpty)
                SupTextAndDiscr(
                  titleColor: AppColors.primaryColor,
                  title: 'notes',
                  discription: paper.note,
                ),
              SupTextAndDiscr(
                titleColor: AppColors.primaryColor,
                title: 'date',
                discription: showData(paper.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
