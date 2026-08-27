import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/widgets/skeleton_loading.dart';

class FinancialListSkeletonSliver extends StatelessWidget {
  const FinancialListSkeletonSliver({Key? key, this.itemCount = 7})
      : super(key: key);

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              SkeletonBlock(width: 56.w, height: 56.h, radius: 12),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: 150.w, height: 14.h, radius: 6),
                    SizedBox(height: 10.h),
                    SkeletonBlock(width: 95.w, height: 11.h, radius: 5),
                  ],
                ),
              ),
              SkeletonBlock(width: 56.w, height: 28.h, radius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class FinancialGridSkeletonSliver extends StatelessWidget {
  const FinancialGridSkeletonSliver({Key? key, this.itemCount = 8})
      : super(key: key);

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      sliver: SliverGrid.builder(
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14.w,
          mainAxisSpacing: 14.h,
          mainAxisExtent: 72.h,
        ),
        itemBuilder: (context, index) =>
            SkeletonBlock(width: double.infinity, height: 72.h, radius: 12),
      ),
    );
  }
}
