import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/widgets/skeleton_loading.dart';
import 'stock_product_grid_layout.dart';

/// Skeleton grid for [StockScreen] product tabs.
class StockProductsGridSkeleton extends StatelessWidget {
  const StockProductsGridSkeleton({
    Key? key,
    this.itemCount = 12,
    this.aspectRatio = 0.92,
  }) : super(key: key);

  final int itemCount;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: StockProductGridLayout.delegate(
          aspectRatio: aspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _StockProductCardSkeleton(),
      ),
    );
  }
}

class _StockProductCardSkeleton extends StatelessWidget {
  const _StockProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SkeletonBlock(
              width: double.infinity,
              height: double.infinity,
              radius: 8,
            ),
          ),
          SizedBox(height: 6.h),
          SkeletonBlock(width: double.infinity, height: 10.h),
          SizedBox(height: 4.h),
          SkeletonBlock(width: 48.w, height: 8.h),
        ],
      ),
    );
  }
}

/// Skeleton for [ProductDetailsScreen] while product loads.
class ProductDetailsPageSkeleton extends StatelessWidget {
  const ProductDetailsPageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 6.h),
          SkeletonBlock(width: double.infinity, height: 88.h, radius: 16),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(child: SkeletonBlock(width: double.infinity, height: 56.h)),
              SizedBox(width: 8.w),
              Expanded(child: SkeletonBlock(width: double.infinity, height: 56.h)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: SkeletonBlock(width: double.infinity, height: 56.h)),
              SizedBox(width: 8.w),
              Expanded(child: SkeletonBlock(width: double.infinity, height: 56.h)),
            ],
          ),
          SizedBox(height: 12.h),
          SkeletonBlock(width: double.infinity, height: 120.h, radius: 16),
          SizedBox(height: 12.h),
          SkeletonBlock(width: double.infinity, height: 52.h, radius: 14),
          SizedBox(height: 12.h),
          SkeletonBlock(width: double.infinity, height: 140.h, radius: 16),
        ],
      ),
    );
  }
}

/// Skeleton for product stock movements page.
class ProductStockMovementsPageSkeleton extends StatelessWidget {
  const ProductStockMovementsPageSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          SkeletonBlock(width: double.infinity, height: 72.h, radius: 12),
          SizedBox(height: 14.h),
          for (var i = 0; i < 8; i++) ...[
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBlock(width: 120.w, height: 12.h),
                        SizedBox(height: 6.h),
                        SkeletonBlock(width: 80.w, height: 9.h),
                        SizedBox(height: 4.h),
                        SkeletonBlock(width: 100.w, height: 9.h),
                      ],
                    ),
                  ),
                  SkeletonBlock(width: 36.w, height: 18.h),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
