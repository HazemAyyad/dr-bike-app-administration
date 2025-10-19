import 'package:doctorbike/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/bills_controller.dart';
import '../purchase_orders_widgets/chang_product_status.dart';
import '../purchase_orders_widgets/change_one_product_status.dart';

class BillDetails extends GetView<BillsController> {
  const BillDetails({Key? key, required this.page}) : super(key: key);

  final String page;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...controller.billDetails!.products.map(
          (e) => Container(
            margin: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 5.h,
            ),
            height: 40.h,
            decoration: BoxDecoration(
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.customGreyColor6,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 80.w,
                  child: Text(
                    e.productName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                        ),
                  ),
                ),
                Text(
                  e.quantity.toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                      ),
                ),
                Text(
                  e.price.toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                      ),
                ),
                Text(
                  e.subTotal.toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                      ),
                ),
                InkWell(
                  onTap: page != '2'
                      ? null
                      : () {
                          Get.dialog(
                            ChangProductStatus(
                              productId: e.productId,
                              billId: controller.billDetails!.billId.toString(),
                            ),
                          );
                        },
                  child: Text(
                    e.productStatus.tr.toString(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                SizedBox(
                  width: 50.w,
                  child: InkWell(
                    onTap: page != '4'
                        ? null
                        : () {
                            Get.dialog(
                              ChangeOneProductStatus(
                                billId:
                                    controller.billDetails!.billId.toString(),
                                productId: e.productId,
                              ),
                            );
                          },
                    child: Text(
                      e.notCompatibleAmount.isNotEmpty
                          ? e.notCompatibleAmount
                          : e.missingAmount.isNotEmpty
                              ? '${'missing_extra'.tr} ${e.missingAmount}'
                              : e.extraAmount.isNotEmpty
                                  ? e.extraAmount
                                  : '----',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
