import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_no_data.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';

class EmployeeSection extends StatelessWidget {
  const EmployeeSection({
    Key? key,
    required this.isLoading,
    required this.onCount,
    required this.itemBuilder,
  }) : super(key: key);

  final RxBool isLoading;
  final int Function() onCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = onCount();
      if (isLoading.value) {
        return const _EmployeeSectionSkeletonSliver();
      }
      if (count == 0) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: ShowNoData(),
        );
      }
      return SliverList.builder(
        itemCount: count,
        itemBuilder: itemBuilder,
      );
    });
  }
}

class _EmployeeSectionSkeletonSliver extends StatelessWidget {
  const _EmployeeSectionSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Row(
              children: [
                SkeletonCircle(size: 68.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: index.isEven ? 0.62 : 0.78,
                        child: SkeletonBlock(
                          width: double.infinity,
                          height: 14.h,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      FractionallySizedBox(
                        widthFactor: index.isEven ? 0.45 : 0.55,
                        child: SkeletonBlock(
                          width: double.infinity,
                          height: 11.h,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                SkeletonBlock(width: 70.w, height: 72.h, radius: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
