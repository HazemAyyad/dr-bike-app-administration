import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../controllers/stock_controller.dart';
import '../widgets/archive_dialog.dart';
import '../widgets/stock_search_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../widgets/grid_view_items.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class StockScreen extends GetView<StockController> {
  const StockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'stock',
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              controller.getArchived();
              Get.dialog(const ArchiveDialog());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AppPullToRefresh(
            onRefresh: controller.pullToRefresh,
            child: CustomScrollView(
              controller: controller.scrollController,
              physics: kRefreshableScrollPhysics,
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                  child: AppTabs(
                    tabs: controller.tabs,
                    currentTab: controller.currentTab,
                    changeTab: controller.changeTab,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Obx(() {
                  if (controller.currentTab.value == 3) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: const StockSearchBar(),
                  );
                }),
              ),
              const GridViewItems(),
            ],
            ),
          ),
          Positioned(
            bottom: 50.h,
            right: 20.w,
            child: Obx(
              () => AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: controller.showScrollToTopButton.value ? 1.0 : 0.0,
                child: controller.showScrollToTopButton.value
                    ? GestureDetector(
                        onTap: controller.scrollToTop,
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(80),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        isAddMenuOpen: controller.isAddMenuOpen,
        onTap: controller.toggleAddMenu,
        sizeAnimation: controller.sizeAnimation,
        opacityAnimation: controller.opacityAnimation,
        addList: controller.addList,
        customWidget: BuildAddMenuItem(
          title: 'addProduct',
          iconAsset: AssetsManager.invoiceIcon,
          route: '',
          onTap: () {
            controller.toggleAddMenu();
            controller.prepareCreateProduct();
            Get.toNamed(AppRoutes.EDITPRODUCTSCREEN);
          },
        ),
      ),
    );
  }
}
