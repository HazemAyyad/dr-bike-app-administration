import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/project_details_model.dart';
import '../controllers/project_controller.dart';
import '../controllers/project_service.dart';
import '../widgets/product_details_widgets/add_product_to_project.dart';
import '../widgets/product_details_widgets/end_project_dialog.dart';
import '../widgets/product_details_widgets/project_expenses_dialog.dart';
import '../widgets/project_images.dart';
import '../widgets/product_details_widgets/project_sales_dialog.dart';
import '../widgets/product_details_widgets/sup_text_and_dis.dart';

class ProjectDetailsScreeen extends GetView<ProjectController> {
  const ProjectDetailsScreeen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'projectDetails',
        action: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, size: 30.sp),
            onPressed: () {
              controller.editProject();
            },
          ),
        ],
      ),
      body: GetBuilder<ProjectController>(
        builder: (controller) {
          if (controller.isLoadingProjectDetails.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                SupTextAndDis(
                  title: 'projectName',
                  discription: ProjectService().projectDetails.value!.name,
                ),
                SupTextAndDis(
                  title: 'projectCost',
                  discription: "${NumberFormat('#,###').format(
                    double.tryParse(ProjectService()
                            .projectDetails
                            .value!
                            .projectCost) ??
                        0,
                  )} ${'currency'.tr}",
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(
                            ProjectService()
                                .projectDetails
                                .value!
                                .products
                                .length,
                            (index) {
                              ProjectProductModel product = ProjectService()
                                  .projectDetails
                                  .value!
                                  .products[index];
                              return SupTextAndDis(
                                showLine: false,
                                title: '${'productName'.tr} ${index + 1}',
                                discription: product.productName,
                              );
                            },
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 10.h, horizontal: 50.w),
                            height: 1.h,
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor6
                                : AppColors.customGreyColor3,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.dialog(const AddProductToProject());
                      },
                      icon: Icon(
                        Icons.add_circle_sharp,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                        size: 35.sp,
                      ),
                    )
                  ],
                ),
                ProjectImages(
                  list: ProjectService().projectDetails.value!.images,
                ),
                if (ProjectService().projectDetails.value!.partnership != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    .customerName ??
                                '',
                      ),
                    ],
                  ),
                if (ProjectService().projectDetails.value!.partnership != null)
                  Row(
                    children: [
                      SupTextAndDis(
                        showLine: false,
                        title: 'partnerSharePercentage',
                        discription: ProjectService()
                            .projectDetails
                            .value!
                            .partnership!
                            .share,
                      ),
                    ],
                  ),
                if (ProjectService().projectDetails.value!.partnership != null)
                  SupTextAndDis(
                    title: 'partnerPercentage',
                    discription:
                        '${ProjectService().projectDetails.value!.partnership!.partnershipPercentage}%',
                  ),
                if (ProjectService().projectDetails.value!.notes.isNotEmpty)
                  SupTextAndDis(
                    title: 'notes',
                    discription: ProjectService().projectDetails.value!.notes,
                  ),
                ProjectImages(
                    list: ProjectService()
                        .projectDetails
                        .value!
                        .partnershipPapers),
                if (ProjectService()
                    .projectDetails
                    .value!
                    .partnershipPapers
                    .isNotEmpty)
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
                // SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        isSafeArea: false,
                        color: Colors.green,
                        text: 'projectExpenses',
                        onPressed: () {
                          controller.getProjectExpenses();
                          Get.dialog(const ProjectExpensesDialog());
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: AppButton(
                        isSafeArea: false,
                        color: Colors.green,
                        text: 'projectSales',
                        onPressed: () {
                          controller.getProjectExpenses(isSales: true);
                          Get.dialog(const ProjectSalesDialog());
                        },
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
                  onPressed: () {
                    Get.dialog(
                      const EndProjectDialog(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
