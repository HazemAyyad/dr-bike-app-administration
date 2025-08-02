import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_colors.dart';

Widget orderCard(BuildContext context, Map<String, dynamic> order) {
  return Column(
    children: [
      InkWell(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        onTap: () {
          // Handle order card tap
          print('Order tapped: ${order['products']}');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: SizedBox(
                width: 140.w,
                child: Text(
                  order['products'],
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.customGreyColor5,
                      ),
                ),
              ),
            ),
            Text(
              '${order['date']}',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.customGreyColor5,
                  ),
            ),
            Column(
              children: [
                Container(
                  height: 25.h,
                  width: Get.locale!.languageCode == 'en' ? 90.w : 70.w,
                  decoration: BoxDecoration(
                    color: order['statusColor'],
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Center(
                    child: Text(
                      '${order['status']}'.tr,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: order['textColor'],
                          ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                order['status'] == 'active'
                    ? GestureDetector(
                        onTap: () {
                          // Handle cancel order action
                          print('Cancel order: ${order['products']}');
                        },
                        child: Container(
                          height: 25.h,
                          width: Get.locale!.languageCode == 'en' ? 90.w : 70.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red,
                              width: 1.w,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'cancel'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                ),
                                SizedBox(width: 5.w),
                                Icon(
                                  Icons.block_flipped,
                                  color: Colors.red, // لون علامة الإكس
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(),
              ],
            ),
          ],
        ),
      ),
      Divider(color: const Color.fromRGBO(217, 217, 217, 1), thickness: 1),
    ],
  );
}
