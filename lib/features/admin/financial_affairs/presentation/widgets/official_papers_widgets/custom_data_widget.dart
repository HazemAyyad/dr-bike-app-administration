import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../financial_operational_ui.dart';

class CustomDataWidget extends StatelessWidget {
  const CustomDataWidget({
    Key? key,
    required this.onTap,
    required this.title,
    required this.value,
    this.onLongPress,
  }) : super(key: key);

  final Function() onTap;
  final String title;
  final String value;
  final Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return FinancialOperationalCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title.isNotEmpty)
              Text(
                title.tr,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.operationalNavy,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            SizedBox(height: 5.h),
            Flexible(
              child: Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.operationalPurple,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
