import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/app_pull_to_refresh.dart';
import '../controllers/suspended_invoices_controller.dart';
import '../widgets/sales_daily_status_bar.dart';
import '../widgets/suspended_invoices_table.dart';

class SuspendedInvoicesScreen extends GetView<SuspendedInvoicesController> {
  const SuspendedInvoicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'suspendedInvoices',
        action: false,
      ),
      body: Obx(
        () {
          if (controller.isLoading.value && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return AppPullToRefresh(
            onRefresh: controller.loadItems,
            child: CustomScrollView(
              physics: kRefreshableScrollPhysics,
              slivers: [
                const SliverToBoxAdapter(child: SalesDailyStatusBar()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
                    child: TextField(
                      controller: controller.searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => controller.loadItems(),
                      decoration: InputDecoration(
                        hintText: 'searchInvoicesHint'.tr,
                        prefixIcon: Icon(
                          Icons.search,
                          color: ThemeService.isDark.value
                              ? AppColors.whiteColor
                              : AppColors.secondaryColor,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: controller.loadItems,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.whiteColor2,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 12.w,
                        ),
                      ),
                    ),
                  ),
                ),
                if (controller.items.isEmpty)
                  const SliverFillRemaining(child: ShowNoData())
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                    sliver: SliverToBoxAdapter(
                      child: SuspendedInvoicesTable(
                        items: controller.items,
                        showOwner: controller.isAdmin,
                        onResume: controller.resumeItem,
                        onCancel: (item) =>
                            controller.cancelItem(context, item),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
