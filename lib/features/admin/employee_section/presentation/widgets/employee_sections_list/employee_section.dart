import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_no_data.dart';
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
          return const SliverFillRemaining(
            child: ShowNoData(),
          );
        }
        return sliverList;
      },
    );
  }
}
