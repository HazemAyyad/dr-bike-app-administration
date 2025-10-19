import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/official_papers_controller.dart';
import '../../widgets/official_papers_widgets/add_picture.dart';
import '../../widgets/official_papers_widgets/official_papers_card.dart';
import '../../widgets/official_papers_widgets/picture_card.dart';

class OfficialPapersScreen extends GetView<OfficialPapersController> {
  const OfficialPapersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'officialPapers',
        action: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.inventory,
              size: 25.sp,
            ),
            color: ThemeService.isDark.value
                ? AppColors.primaryColor
                : AppColors.secondaryColor,
            onPressed: () {
              controller.getTreasury();
              Get.toNamed(AppRoutes.SAFESSCREEN);
            },
          ),
          SizedBox(width: 15.w),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              child: SearchBar(
                backgroundColor: WidgetStateProperty.all(
                  ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.whiteColor2,
                ),
                hintText: 'search'.tr,
                onChanged: (value) => controller.searchBar(value),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<OfficialPapersController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.currentTab.value == 0
                  ? controller.papersSearch.isEmpty
                  : controller.picturesSearch.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ShowNoData(),
                );
              }

              if (controller.currentTab.value == 0) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = controller.papersSearch[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.h,
                          horizontal: 24.w,
                        ),
                        child: OfficialPapersCard(data: data),
                      );
                    },
                    childCount: controller.papersSearch.length,
                  ),
                );
              } else {
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = controller.picturesSearch[index];
                        return PictureCard(data: data);
                      },
                      childCount: controller.picturesSearch.length,
                    ),
                  ),
                );
              }
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: () {
          controller.toggleAddMenu();
        },
        opacityAnimation: controller.sizeAnimation,
        sizeAnimation: controller.opacityAnimation,
        customWidget: Column(
          children: [
            BuildAddMenuItem(
              title: 'add_important_images',
              iconAsset: AssetsManager.invoiceIcon,
              route: '',
              onTap: () {
                controller.isEdit = false;
                controller.fileController.clear();
                controller.paperFiles.clear();
                controller.notesController.clear();
                controller.toggleAddMenu();
                controller.getPictureData();
                Get.dialog(const AddPicture());
              },
            ),
          ],
        ),
      ),
    );
  }
}
