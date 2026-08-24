import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/skeleton_loading.dart';

class BuyingBillsTableSkeleton extends StatelessWidget {
  const BuyingBillsTableSkeleton({Key? key, this.rowCount = 6})
      : super(key: key);

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
      child: Column(
        children: [
          Container(
            height: 43.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.customGreyColor7,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBlock(width: 58, height: 12, radius: 4),
                SkeletonBlock(width: 48, height: 12, radius: 4),
                SkeletonBlock(width: 52, height: 12, radius: 4),
                SkeletonBlock(width: 42, height: 12, radius: 4),
              ],
            ),
          ),
          Container(
            height: 48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.customGreyColor7.withValues(alpha: 0.7),
              border: Border(
                left: BorderSide(color: Colors.grey.shade200),
                right: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: const SkeletonBlock(width: 165, height: 14, radius: 4),
          ),
          for (var i = 0; i < rowCount; i++) const _BuyingBillRowSkeleton(),
        ],
      ),
    );
  }
}

class BuyingReturnListSkeleton extends StatelessWidget {
  const BuyingReturnListSkeleton({Key? key, this.rowCount = 5})
      : super(key: key);

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 24.h),
      child: Column(
        children: [
          Container(
            height: 44.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.customGreyColor7.withValues(alpha: 0.75),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const SkeletonBlock(width: 150, height: 14, radius: 4),
          ),
          for (var i = 0; i < rowCount; i++) const _BuyingReturnRowSkeleton(),
        ],
      ),
    );
  }
}

class _BuyingBillRowSkeleton extends StatelessWidget {
  const _BuyingBillRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 18,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBlock(width: 56, height: 13, radius: 4),
                SizedBox(height: 8.h),
                const SkeletonBlock(width: 64, height: 11, radius: 4),
              ],
            ),
          ),
          const Expanded(
            flex: 13,
            child: Center(
              child: SkeletonBlock(width: 42, height: 13, radius: 4),
            ),
          ),
          Expanded(
            flex: 22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBlock(width: 62, height: 13, radius: 4),
                SizedBox(height: 8.h),
                const SkeletonBlock(width: 48, height: 11, radius: 4),
              ],
            ),
          ),
          const Expanded(
            flex: 10,
            child: Center(
              child: SkeletonBlock(width: 24, height: 13, radius: 4),
            ),
          ),
          const Expanded(
            flex: 25,
            child: Center(
              child: SkeletonBlock(width: 76, height: 13, radius: 4),
            ),
          ),
          Expanded(
            flex: 22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBlock(width: 62, height: 12, radius: 4),
                SizedBox(height: 8.h),
                const SkeletonBlock(width: 54, height: 11, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyingReturnRowSkeleton extends StatelessWidget {
  const _BuyingReturnRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 38),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SkeletonBlock(width: 120, height: 14, radius: 4),
                SizedBox(height: 9.h),
                const SkeletonBlock(width: 82, height: 12, radius: 4),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SkeletonBlock(width: 52, height: 13, radius: 4),
              SizedBox(height: 9.h),
              const SkeletonBlock(width: 38, height: 12, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}
