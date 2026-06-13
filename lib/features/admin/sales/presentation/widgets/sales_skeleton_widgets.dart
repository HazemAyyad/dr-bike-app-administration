import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/skeleton_loading.dart';

/// Skeleton for the daily sales status strip on [SalesScreen].
class SalesDailyStatusBarSkeleton extends StatelessWidget {
  const SalesDailyStatusBarSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 140.w, height: 13.h),
                SizedBox(height: 6.h),
                SkeletonBlock(width: 100.w, height: 10.h),
                SizedBox(height: 4.h),
                SkeletonBlock(width: 160.w, height: 10.h),
              ],
            ),
          ),
          SkeletonBlock(width: 56.w, height: 28.h, radius: 6),
        ],
      ),
    );
  }
}

/// Skeleton rows for instant / profit sales tables.
class SalesInvoicesListSkeleton extends StatelessWidget {
  const SalesInvoicesListSkeleton({Key? key, this.rowCount = 7}) : super(key: key);

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tableHeaderSkeleton(),
        SizedBox(height: 10.h),
        SkeletonBlock(width: double.infinity, height: 34.h, radius: 4),
        SizedBox(height: 6.h),
        for (var i = 0; i < rowCount; i++) ...[
          _saleRowSkeleton(i),
          if (i < rowCount - 1) SizedBox(height: 6.h),
        ],
      ],
    );
  }

  Widget _tableHeaderSkeleton() {
    return Row(
      children: [
        Expanded(flex: 3, child: SkeletonBlock(width: double.infinity, height: 11.h)),
        SizedBox(width: 6.w),
        Expanded(child: SkeletonBlock(width: double.infinity, height: 11.h)),
        SizedBox(width: 6.w),
        Expanded(child: SkeletonBlock(width: double.infinity, height: 11.h)),
      ],
    );
  }

  Widget _saleRowSkeleton(int index) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SkeletonBlock(
              width: double.infinity,
              height: 12.h,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: SkeletonBlock(
              width: double.infinity,
              height: 12.h,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: SkeletonBlock(
              width: double.infinity,
              height: 12.h,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary strip + session tiles for daily history screens.
class SalesDailyHistorySkeleton extends StatelessWidget {
  const SalesDailyHistorySkeleton({Key? key, this.tileCount = 5}) : super(key: key);

  final int tileCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
      itemCount: tileCount + 1,
      separatorBuilder: (_, __) => SizedBox(height: 6.h),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SalesDailySummaryStripSkeleton(),
              SizedBox(height: 8.h),
              SkeletonBlock(width: 120.w, height: 10.h),
            ],
          );
        }
        return const SalesDailySessionTileSkeleton();
      },
    );
  }
}

class SalesDailySummaryStripSkeleton extends StatelessWidget {
  const SalesDailySummaryStripSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final bg = isDark ? AppColors.darkColor : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Column(
                  children: [
                    SkeletonBlock(width: 24.w, height: 18.h),
                    SizedBox(height: 4.h),
                    SkeletonBlock(width: 48.w, height: 9.h),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class SalesDailySessionTileSkeleton extends StatelessWidget {
  const SalesDailySessionTileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkColor : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 32.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SkeletonBlock(
                        width: double.infinity,
                        height: 13.h,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    SkeletonBlock(width: 52.w, height: 18.h, radius: 12),
                  ],
                ),
                SizedBox(height: 6.h),
                SkeletonBlock(width: double.infinity, height: 10.h),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    SkeletonBlock(width: 44.w, height: 18.h, radius: 6),
                    SizedBox(width: 6.w),
                    SkeletonBlock(width: 44.w, height: 18.h, radius: 6),
                    SizedBox(width: 6.w),
                    SkeletonBlock(width: 44.w, height: 18.h, radius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin closing / reopen / cancellation request cards.
class SalesDailyAdminRequestsSkeleton extends StatelessWidget {
  const SalesDailyAdminRequestsSkeleton({Key? key, this.count = 6}) : super(key: key);

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, __) => const SalesDailyAdminRequestCardSkeleton(),
    );
  }
}

class SalesDailyAdminRequestCardSkeleton extends StatelessWidget {
  const SalesDailyAdminRequestCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 140.w, height: 16.h),
            SizedBox(height: 8.h),
            SkeletonBlock(width: double.infinity, height: 11.h),
            SizedBox(height: 4.h),
            SkeletonBlock(width: 200.w, height: 11.h),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: SkeletonBlock(width: double.infinity, height: 36.h, radius: 8)),
                SizedBox(width: 10.w),
                Expanded(child: SkeletonBlock(width: double.infinity, height: 36.h, radius: 8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Session detail screen skeleton.
class SalesDailySessionDetailSkeleton extends StatelessWidget {
  const SalesDailySessionDetailSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 16.h),
      children: [
        _headerCard(),
        SizedBox(height: 12.h),
        SkeletonBlock(width: 100.w, height: 12.h),
        SizedBox(height: 8.h),
        _currencyTable(),
        SizedBox(height: 14.h),
        SkeletonBlock(width: 90.w, height: 12.h),
        SizedBox(height: 8.h),
        for (var i = 0; i < 4; i++) ...[
          _salesLogRow(),
          SizedBox(height: 6.h),
        ],
      ],
    );
  }

  Widget _headerCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonBlock(width: double.infinity, height: 16.h)),
              SkeletonBlock(width: 60.w, height: 22.h, radius: 12),
            ],
          ),
          SizedBox(height: 8.h),
          SkeletonBlock(width: 180.w, height: 10.h),
          SizedBox(height: 4.h),
          SkeletonBlock(width: 140.w, height: 10.h),
        ],
      ),
    );
  }

  Widget _currencyTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              children: List.generate(
                4,
                (_) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: SkeletonBlock(width: double.infinity, height: 10.h),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _salesLogRow() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: double.infinity, height: 12.h),
                SizedBox(height: 4.h),
                SkeletonBlock(width: 100.w, height: 9.h),
              ],
            ),
          ),
          SkeletonBlock(width: 48.w, height: 14.h),
        ],
      ),
    );
  }
}

/// Close-day form skeleton (currency cards).
class SalesDailyCloseSkeleton extends StatelessWidget {
  const SalesDailyCloseSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        SkeletonBlock(width: double.infinity, height: 14.h),
        SizedBox(height: 8.h),
        SkeletonBlock(width: 220.w, height: 12.h),
        SizedBox(height: 16.h),
        for (var i = 0; i < 3; i++) ...[
          _currencyCard(),
          SizedBox(height: 12.h),
        ],
        SizedBox(height: 8.h),
        SkeletonBlock(width: double.infinity, height: 48.h, radius: 10),
      ],
    );
  }

  Widget _currencyCard() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 48.w, height: 16.h),
          SizedBox(height: 10.h),
          for (var i = 0; i < 3; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBlock(width: 80.w, height: 10.h),
                SkeletonBlock(width: 60.w, height: 10.h),
              ],
            ),
            SizedBox(height: 6.h),
          ],
          SizedBox(height: 8.h),
          SkeletonBlock(width: double.infinity, height: 42.h, radius: 8),
          SizedBox(height: 8.h),
          SkeletonBlock(width: double.infinity, height: 42.h, radius: 8),
        ],
      ),
    );
  }
}
