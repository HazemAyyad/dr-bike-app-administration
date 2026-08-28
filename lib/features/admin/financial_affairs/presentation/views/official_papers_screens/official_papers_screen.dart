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
import '../../widgets/financial_skeletons.dart';
import '../../widgets/financial_operational_ui.dart';

class OfficialPapersScreen extends GetView<OfficialPapersController> {
  const OfficialPapersScreen({Key? key, this.embedded = false})
      : super(key: key);
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded
          ? null
          : CustomAppBar(
              title: 'officialPapers',
              action: false,
              actions: [
                Obx(() => IconButton(
                      tooltip: 'search'.tr,
                      onPressed: controller.toggleSearch,
                      icon: Icon(
                        controller.isSearchVisible.value
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                      ),
                    )),
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
          if (embedded)
            SliverToBoxAdapter(
              child: FinancialSectionToolbar(
                onSearch: controller.toggleSearch,
                onFilter: () => _showArchiveFilters(context),
                onReset: controller.resetFilters,
                extraAction: OutlinedButton.icon(
                  onPressed: () {
                    controller.getTreasury();
                    Get.toNamed(AppRoutes.SAFESSCREEN);
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('الخزن والملفات'),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: AppTabs(
              tabs: controller.tabs,
              currentTab: controller.currentTab,
              changeTab: controller.changeTab,
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                child: Row(
                  children: [
                    _ArchiveChip(
                      label: 'النشطة',
                      value: 'active',
                      selected:
                          controller.archiveStatusFilter.value == 'active',
                      onSelected: controller.setArchiveStatusFilter,
                    ),
                    _ArchiveChip(
                      label: 'المؤرشفة',
                      value: 'archived',
                      selected:
                          controller.archiveStatusFilter.value == 'archived',
                      onSelected: controller.setArchiveStatusFilter,
                    ),
                    _ArchiveChip(
                      label: 'الكل',
                      value: 'all',
                      selected: controller.archiveStatusFilter.value == 'all',
                      onSelected: controller.setArchiveStatusFilter,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() => controller.isSearchVisible.value
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    child: SearchBar(
                      controller: controller.searchController,
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                      leading: const Icon(Icons.search),
                      trailing: [
                        IconButton(
                          tooltip: 'cancel'.tr,
                          onPressed: controller.closeSearch,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                      hintText: 'search'.tr,
                      backgroundColor: WidgetStateProperty.all(
                        ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.customGreyColor7,
                      ),
                      onChanged: controller.searchBar,
                    ),
                  )
                : const SizedBox.shrink()),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<OfficialPapersController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return controller.currentTab.value == 0
                    ? const FinancialListSkeletonSliver()
                    : const FinancialGridSkeletonSliver();
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
                          vertical: 2.h,
                          horizontal: 12.w,
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
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.88,
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

  void _showArchiveFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('فلترة الأوراق والصور',
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.operationalNavy)),
              SizedBox(height: 8.h),
              for (final option in const <Map<String, dynamic>>[
                {
                  'value': 'active',
                  'label': 'النشطة فقط',
                  'icon': Icons.verified_outlined
                },
                {
                  'value': 'archived',
                  'label': 'المؤرشفة فقط',
                  'icon': Icons.archive_outlined
                },
                {
                  'value': 'all',
                  'label': 'النشطة والمؤرشفة',
                  'icon': Icons.all_inbox_outlined
                },
              ])
                ListTile(
                  leading: Icon(option['icon'] as IconData,
                      color: AppColors.operationalPurple),
                  title: Text(option['label'] as String),
                  trailing: Obx(() =>
                      controller.archiveStatusFilter.value == option['value']
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.operationalPurple)
                          : const Icon(Icons.circle_outlined)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    controller
                        .setArchiveStatusFilter(option['value'] as String);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveChip extends StatelessWidget {
  const _ArchiveChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}
