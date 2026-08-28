import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/assets_controller.dart';
import '../controllers/expenses_controller.dart';
import '../controllers/official_papers_controller.dart';
import '../widgets/financial_filters_modal.dart';
import '../widgets/assets_widget/assets_data.dart';
import 'assets_screens/assets_screen.dart';
import 'expenses_screens/expenses_screen.dart';
import 'financial_reports_screen.dart';
import 'official_papers_screens/official_papers_screen.dart';

class FinancialAffairsScreen extends StatefulWidget {
  const FinancialAffairsScreen({Key? key}) : super(key: key);

  @override
  State<FinancialAffairsScreen> createState() => _FinancialAffairsScreenState();
}

class _FinancialAffairsScreenState extends State<FinancialAffairsScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: selectedTab == 0
              ? 'المصاريف'
              : selectedTab == 1
                  ? 'الأصول'
                  : 'الأوراق الرسمية',
          action: false,
          actions: [
            _searchAction(),
            _appBarAction(
              tooltip: 'الفلاتر',
              onPressed: () => _openFilters(context),
              icon: Icons.tune_rounded,
            ),
            if (selectedTab == 1)
              _appBarAction(
                tooltip: 'تنفيذ إهلاك أصول الشهر',
                onPressed: () => Get.dialog(const AssetsConsumption()),
                icon: Icons.trending_down_rounded,
              ),
            if (selectedTab == 1)
              _appBarAction(
                tooltip: 'سجل إهلاك الأصول',
                onPressed: () {
                  final controller = Get.find<AssetsController>();
                  controller.getAssetsLogs();
                  Get.toNamed(AppRoutes.ASSETLOGSCREEN);
                },
                icon: Icons.history_rounded,
              ),
            if (selectedTab != 2)
              _appBarAction(
                tooltip: 'التقارير',
                onPressed: () => showFinancialReportsModal(
                  context,
                  kind: selectedTab == 0
                      ? FinancialReportsKind.expenses
                      : FinancialReportsKind.assets,
                ),
                icon: Icons.assessment_outlined,
              ),
            if (selectedTab == 2)
              _appBarAction(
                tooltip: 'الخزن والملفات',
                onPressed: () {
                  final controller = Get.find<OfficialPapersController>();
                  controller.getTreasury();
                  Get.toNamed(AppRoutes.SAFESSCREEN);
                },
                icon: Icons.inventory_2_outlined,
              ),
            SizedBox(width: 5.w),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(62.h),
            child: Container(
              margin: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 8.h),
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.operationalSurface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.operationalCardBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.operationalNavy.withValues(alpha: .06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                onTap: (index) => setState(() => selectedTab = index),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.operationalPurple,
                      AppColors.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.operationalPurple.withValues(alpha: .24),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: ThemeService.isDark.value
                    ? Colors.white70
                    : AppColors.operationalNavy,
                labelPadding: EdgeInsets.zero,
                tabs: [
                  _tab(Icons.receipt_long_outlined, 'المصاريف', 0),
                  _tab(Icons.inventory_2_outlined, 'الأصول', 1),
                  _tab(Icons.folder_copy_outlined, 'الأوراق', 2),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            ExpensesScreen(embedded: true),
            AssetsScreen(embedded: true),
            OfficialPapersScreen(embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int index) => Tab(
        height: 45.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: selectedTab == index ? 19.sp : 17.sp),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight:
                      selectedTab == index ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _searchAction() {
    if (selectedTab == 0) {
      final controller = Get.find<ExpensesController>();
      return Obx(() => _appBarAction(
            tooltip: 'search'.tr,
            onPressed: controller.toggleSearch,
            icon: controller.isSearchVisible.value
                ? Icons.search_off_rounded
                : Icons.search_rounded,
          ));
    }
    if (selectedTab == 1) {
      final controller = Get.find<AssetsController>();
      return Obx(() => _appBarAction(
            tooltip: 'search'.tr,
            onPressed: controller.toggleSearch,
            icon: controller.isSearchVisible.value
                ? Icons.search_off_rounded
                : Icons.search_rounded,
          ));
    }
    final controller = Get.find<OfficialPapersController>();
    return Obx(() => _appBarAction(
          tooltip: 'search'.tr,
          onPressed: controller.toggleSearch,
          icon: controller.isSearchVisible.value
              ? Icons.search_off_rounded
              : Icons.search_rounded,
        ));
  }

  Widget _appBarAction({
    required String tooltip,
    required VoidCallback onPressed,
    required IconData icon,
  }) =>
      IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: BoxConstraints.tightFor(width: 36.w, height: 40.h),
        icon: Icon(icon, size: 21.sp),
      );

  void _openFilters(BuildContext context) {
    if (selectedTab == 0) {
      final controller = Get.find<ExpensesController>();
      showExpenseFiltersModal(context, controller);
      return;
    }
    if (selectedTab == 1) {
      final controller = Get.find<AssetsController>();
      showAssetFiltersModal(context, controller);
      return;
    }
    showOfficialPapersFiltersModal(
      context,
      Get.find<OfficialPapersController>(),
    );
  }
}
