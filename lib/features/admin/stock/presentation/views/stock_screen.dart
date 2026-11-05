import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/widgets/open_desktop_window_button.dart';
import '../widgets/stock_products_fab.dart';
import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/custom_tab_bar.dart';
import '../../../../../core/helpers/desktop_scroll_behavior.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../core/utils/desktop_layout.dart';
import '../controllers/offer_packages_controller.dart';
import '../controllers/stock_controller.dart';
import '../widgets/archive_dialog.dart';
import '../widgets/stock_search_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../widgets/grid_view_items.dart';
import '../widgets/sale_blocked_products_tab.dart';
import '../widgets/stock_product_grid_layout.dart';
import '../widgets/stock_product_selection_bar.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _saleBlockedKey = GlobalKey<SaleBlockedProductsTabState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockController>();
    final desktop = DesktopLayout.isDesktopPlatform;
    final narrowDesktop = desktop && MediaQuery.sizeOf(context).width < 560;
    final isPhoneLandscape = StockProductGridLayout.isPhoneLandscape(context);
    final compactTabs = desktop || isPhoneLandscape;
    final horizontalPadding = compactTabs ? 12.0 : 16.w;
    final verticalPadding = compactTabs ? 6.0 : 8.h;
    final tabs = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: AppTabs(
        tabs: controller.tabs,
        currentTab: controller.currentTab,
        changeTab: (index) {
          if (desktop &&
              controller.currentTab.value != index &&
              controller.scrollController.hasClients) {
            controller.scrollController.jumpTo(0);
          }
          controller.changeTab(index);
        },
        height: desktop ? 44 : (isPhoneLandscape ? 38 : null),
        horizontalPadding: compactTabs ? 4 : null,
        tabHorizontalPadding: compactTabs ? 14 : null,
        tabVerticalPadding: compactTabs ? 7 : null,
        tabHorizontalMargin: compactTabs ? 3 : null,
        fontSize: compactTabs ? 14 : null,
        desktopScrollbar: true,
      ),
    );
    final stockList = AppPullToRefresh(
      indicatorKey: _refreshKey,
      onRefresh: () {
        final blockedTab = _saleBlockedKey.currentState;
        if (controller.isSaleBlockedTab && blockedTab != null) {
          return blockedTab.refresh();
        }
        return controller.pullToRefresh();
      },
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: kRefreshableScrollPhysics,
        scrollBehavior: desktop ? const DesktopScrollBehavior() : null,
        slivers: [
          if (!desktop) SliverToBoxAdapter(child: tabs),
          SliverToBoxAdapter(
            child: Obx(() {
              final tab = controller.currentTab.value;
              if (tab == 3 ||
                  tab == 4 ||
                  tab == 5 ||
                  controller.isNegativeStockTab ||
                  controller.isSaleBlockedTab ||
                  controller.isQuickEditTab) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: compactTabs ? 6 : 12.h,
                ),
                child: StockSearchBar(compact: compactTabs),
              );
            }),
          ),
          GridViewItems(saleBlockedKey: _saleBlockedKey),
        ],
      ),
    );
    void openImageExports() => Get.toNamed(AppRoutes.STOCKIMAGESEXPORTSSCREEN);
    Future<void> openSettings() async {
      await Get.toNamed(AppRoutes.STOCKINVENTORYSETTINGSSCREEN);
      await controller.refreshAfterStoreSectionsChanged();
    }

    void openArchive() {
      controller.getArchived();
      Get.dialog(const ArchiveDialog());
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'stock',
        titleFontSize: isPhoneLandscape ? 24 : null,
        iconSize: isPhoneLandscape ? 22 : null,
        toolbarHeight: isPhoneLandscape ? 48 : null,
        actions: [
          if (desktop)
            IconButton(
              tooltip: 'refresh'.tr,
              onPressed: () => _refreshKey.currentState?.show(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          const OpenDesktopWindowButton(
            route: AppRoutes.STOCKSCREEN,
            title: 'stock',
          ),
          Obx(() {
            if (!controller.canPickProductLocation) {
              return const SizedBox.shrink();
            }
            final active = controller.locationSelectionActive.value;
            return IconButton(
              icon: Icon(
                active ? Icons.location_on : Icons.drive_file_move_outline,
                color: active ? AppColors.operationalPurple : null,
              ),
              tooltip: 'moveProductLocation'.tr,
              onPressed: active
                  ? controller.exitLocationSelection
                  : controller.startLocationSelectionMode,
            );
          }),
          Obx(() {
            if (!controller.canDeleteProducts) {
              return const SizedBox.shrink();
            }
            final active = controller.deleteSelectionActive.value;
            return IconButton(
              icon: Icon(
                active ? Icons.delete : Icons.delete_outline,
                color: active ? Colors.red : null,
              ),
              tooltip: 'deleteProducts'.tr,
              onPressed: active
                  ? controller.exitDeleteSelection
                  : () => controller.startDeleteSelection(),
            );
          }),
          if (controller.canAccessFullStock && narrowDesktop)
            PopupMenuButton<VoidCallback>(
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: openImageExports,
                  enabled: !controller.isProductsCsvBusy.value,
                  child: Text('downloadStockImages'.tr),
                ),
                PopupMenuItem(
                  value: openSettings,
                  child: Text('stockInventorySettings'.tr),
                ),
                PopupMenuItem(
                  value: openArchive,
                  child: Text('archive'.tr),
                ),
              ],
            ),
          if (controller.canAccessFullStock && !narrowDesktop) ...[
            Obx(() {
              final busy = controller.isProductsCsvBusy.value;
              return IconButton(
                icon: busy
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_zip_outlined),
                tooltip: 'downloadStockImages'.tr,
                onPressed: busy ? null : openImageExports,
              );
            }),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'stockInventorySettings'.tr,
              onPressed: openSettings,
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'archive'.tr,
              onPressed: openArchive,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (desktop)
            Column(children: [tabs, Expanded(child: stockList)])
          else
            stockList,
          Positioned(
            bottom: isPhoneLandscape ? 22 : 50.h,
            right: isPhoneLandscape ? 14 : 20.w,
            child: Obx(
              () => controller.showScrollToTopButton.value
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
        ],
      ),
      bottomNavigationBar: const StockProductSelectionBar(),
      floatingActionButton: Obx(() {
        if (controller.currentTab.value == 4) {
          return FloatingActionButton(
            onPressed: () {
              Get.find<OfferPackagesController>().prepareCreate();
              Get.toNamed(AppRoutes.ADDEDITOFFERPACKAGESCREEN);
            },
            backgroundColor: AppColors.secondaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            child: const Icon(Icons.add),
          );
        }
        if (controller.currentTab.value == 5 ||
            controller.isSaleBlockedTab ||
            controller.isNegativeStockTab ||
            controller.isQuickEditTab) {
          return const SizedBox.shrink();
        }
        return StockProductsFab(
          isAddMenuOpen: controller.isAddMenuOpen,
          onTap: controller.toggleAddMenu,
          sizeAnimation: controller.sizeAnimation,
          opacityAnimation: controller.opacityAnimation,
          customWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BuildAddMenuItem(
                title: 'addProduct',
                iconAsset: AssetsManager.invoiceIcon,
                route: '',
                onTap: () {
                  controller.toggleAddMenu();
                  controller.prepareCreateProduct();
                  Get.toNamed(AppRoutes.EDITPRODUCTSCREEN);
                },
              ),
              BuildAddMenuItem(
                title: 'newProductComposition',
                iconAsset: AssetsManager.invoiceIcon,
                route: AppRoutes.ADDCOMBINATIONSCREEN,
                onTap: controller.toggleAddMenu,
              ),
            ],
          ),
        );
      }),
    );
  }
}
