import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';

class EmployeeSection extends StatelessWidget {
  const EmployeeSection({
    Key? key,
    required this.list,
    required this.sliverList,
    required this.isLoading,
  }) : super(key: key);

  final dynamic list;
  final SliverList sliverList;
  final RxBool isLoading;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme.bodyMedium!;

    return Obx(
      () {
        if (isLoading.value) {
          return SliverToBoxAdapter(
            child: SizedBox(
              height: 600.h,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
            ),
          );
        } else if (list.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 150.h),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100.h,
                    color: AppColors.graywhiteColor,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'noDebts'.tr,
                    style: theme.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.graywhiteColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return sliverList;
      },
    );
  }
}
