import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_daily_history_controller.dart';
import '../widgets/sales_daily_ui_widgets.dart';
import '../widgets/sales_skeleton_widgets.dart';

class SalesDailyHistoryScreen extends GetView<SalesDailyHistoryController> {
  const SalesDailyHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'salesDailyHistoryTitle',
          action: false,
          bottom: TabBar(
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontSize: 13.sp),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: 'salesDailyTodayTab'.tr),
              Tab(text: 'salesDailyHistoryTab'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const SalesDailyHistorySkeleton();
          }
          return TabBarView(
            children: [
              _TodayTab(controller: controller),
              _HistoryTab(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.controller});

  final SalesDailyHistoryController controller;

  @override
  Widget build(BuildContext context) {
    final overview = controller.todayOverview.value;
    if (overview == null || overview.sessions.isEmpty) {
      return const Center(child: ShowNoData());
    }

    return RefreshIndicator(
      onRefresh: controller.loadAll,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
        itemCount: overview.sessions.length + 1,
        separatorBuilder: (_, __) => SizedBox(height: 6.h),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SalesDailySummaryStrip(
                  openCount: overview.openCount,
                  pendingCount: overview.closingRequestedCount,
                  closedCount: overview.closedCount,
                ),
                SizedBox(height: 8.h),
                Text(
                  '${'salesDailyBusinessDate'.tr}: ${overview.businessDate}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }

          final item = overview.sessions[index - 1];
          return SalesDailySessionTile(
            item: item,
            onTap: () => controller.openSessionDetail(item.id),
          );
        },
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.controller});

  final SalesDailyHistoryController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.historySessions.isEmpty) {
      return const Center(child: ShowNoData());
    }

    return RefreshIndicator(
      onRefresh: controller.loadAll,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
        itemCount: controller.historySessions.length,
        separatorBuilder: (_, __) => SizedBox(height: 6.h),
        itemBuilder: (context, index) {
          final item = controller.historySessions[index];
          return SalesDailySessionTile(
            item: item,
            onTap: () => controller.openSessionDetail(item.id),
          );
        },
      ),
    );
  }
}
