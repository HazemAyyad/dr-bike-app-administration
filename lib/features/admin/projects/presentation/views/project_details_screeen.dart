import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/project_controller.dart';
import '../controllers/project_service.dart';
import '../widgets/project_details/project_status.dart';
import '../widgets/project_details/sup_text_and_dis.dart';

class ProjectDetailsScreeen extends StatelessWidget {
  const ProjectDetailsScreeen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'projectDetails', action: false),
      body: GetBuilder<ProjectController>(
        builder: (controller) {
          if (controller.isLoadingProjectDetails.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 10.h),
              SupTextAndDis(
                title: 'projectName',
                discription: ProjectService().projectDetails.value!.name,
              ),
              SupTextAndDis(
                title: 'projectCost',
                discription: "${NumberFormat('#,###').format(
                  double.tryParse(
                          ProjectService().projectDetails.value!.projectCost) ??
                      0,
                )} ${'currency'.tr}",
              ),
              ...ProjectService().projectDetails.value!.products.map((e) {
                return SupTextAndDis(
                  title: 'productName',
                  discription: e.productName!,
                );
              }),
              if (ProjectService().projectDetails.value!.images.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SupTextAndDis(
                        showLine: false,
                        title: 'projectOrProductsImages',
                        discription: '',
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          ...ProjectService().projectDetails.value!.images.map(
                            (e) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5.r),
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
                                      height: 150.h,
                                      fit: BoxFit.fill,
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
                                      fadeOutDuration:
                                          const Duration(milliseconds: 200),
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              if (ProjectService().projectDetails.value!.partnership != null)
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          height: 1.h,
                          width: 300.w,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor3,
                        ),
                      ],
                    ),
                    SupTextAndDis(
                      showLine: false,
                      title: 'partnerName',
                      discription: ProjectService()
                              .projectDetails
                              .value!
                              .partnership!
                              .sellerName!
                              .isNotEmpty
                          ? ProjectService()
                              .projectDetails
                              .value!
                              .partnership!
                              .sellerName!
                          : ProjectService()
                              .projectDetails
                              .value!
                              .partnership!
                              .customerName,
                    ),
                  ],
                ),
              if (ProjectService().projectDetails.value!.partnership != null)
                SupTextAndDis(
                  showLine: false,
                  title: 'partnerSharePercentage',
                  discription:
                      ProjectService().projectDetails.value!.partnership!.share,
                ),
              if (ProjectService().projectDetails.value!.partnership != null)
                SupTextAndDis(
                  title: 'partnerPercentage',
                  discription: ProjectService()
                      .projectDetails
                      .value!
                      .partnership!
                      .partnershipPercentage,
                ),
              if (ProjectService().projectDetails.value!.notes.isNotEmpty)
                SupTextAndDis(
                  title: 'notes',
                  discription: ProjectService().projectDetails.value!.notes,
                ),
              if (ProjectService()
                  .projectDetails
                  .value!
                  .partnershipPapers
                  .isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SupTextAndDis(
                        showLine: false,
                        title: 'projectOrProductsImages',
                        discription: '',
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          ...ProjectService()
                              .projectDetails
                              .value!
                              .partnershipPapers
                              .map(
                            (e) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5.r),
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
                                      height: 150.h,
                                      fit: BoxFit.fill,
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
                                      fadeOutDuration:
                                          const Duration(milliseconds: 200),
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 10.h),
                            height: 1.h,
                            width: 300.w,
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor6
                                : AppColors.customGreyColor3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      color: Colors.green,
                      text: 'projectExpenses',
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AppButton(
                      isSafeArea: false,
                      color: Colors.green,
                      text: 'projectSales',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10.h),
                    height: 1.h,
                    width: 300.w,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor3,
                  ),
                ],
              ),
              if (ProjectService()
                  .projectDetails
                  .value!
                  .paymentMethod
                  .isNotEmpty)
                SupTextAndDis(
                  title: 'paymentMethod',
                  discription:
                      ProjectService().projectDetails.value!.paymentMethod,
                ),
              if (ProjectService()
                  .projectDetails
                  .value!
                  .paymentNotes
                  .isNotEmpty)
                SupTextAndDis(
                  title: '${'notes'.tr} ${'paymentMethod'.tr}',
                  discription:
                      ProjectService().projectDetails.value!.paymentNotes,
                ),
              SizedBox(height: 20.h),
              AppButton(
                color: Colors.red,
                text: 'endProject',
                onPressed: () {},
              ),
              // SizedBox(height: 50.h),
              // 'projectPartners'.isEmpty
              //     ? const SizedBox.shrink()
              //     : Padding(
              //         padding: EdgeInsets.only(
              //           right: Get.locale!.languageCode == 'ar' ? 50.w : 0.w,
              //           left: Get.locale!.languageCode == 'ar' ? 0.w : 50.w,
              //         ),
              //         child: Column(
              //           children: [
              //             SupTextAndDis(
              //               title: 'partnerShare',
              //               discription: "${'partnerShare'} ${'currency'.tr}",
              //             ),
              //             const SupTextAndDis(
              //                 title: 'partnerPercentage',
              //                 discription: 'partnerPercentage'),
              //           ],
              //         ),
              //       ),
              // const SupTextAndDis('notes', 'notes'),
              // const SupTextAndDis('projectDocuments', 'projectDocuments'),
              // const SupTextAndDis('totalSales', 'totalSales'),
              // const SupTextAndDis('projectStatus', 'projectStatus'),
              // SizedBox(height: 10.h),
              // // project Status
              // projectStatus(),
              // SizedBox(height: 10.h),
              // Text(
              //   'projectImagesOrProducts'.tr,
              //   style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              //         fontSize: 14.sp,
              //         fontWeight: FontWeight.w700,
              //         color: ThemeService.isDark.value
              //             ? AppColors.customGreyColor6
              //             : AppColors.customGreyColor4,
              //       ),
              // ),
              // SizedBox(height: 5.h),
              // project Images
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Image.asset(
              //       'projectOrProductsImages',
              //     ),
              //     Image.asset(
              //       'projectOrProductsImages',
              //     ),
              //   ],
              // )
            ],
          );
        },
      ),
    );
  }
}
