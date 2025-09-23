import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../employee/my_orders/widgets/row_text.dart';
import '../controllers/sales_controller.dart';
import '../widgets/proudact_details_widget.dart';

class BillDetailsScreen extends GetView<SalesController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'billDetails', action: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              height: 32.h,
              decoration: BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.secondaryColor
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox.shrink(),
                  Flexible(child: RowText(title: 'productName')),
                  SizedBox.shrink(),
                  Flexible(child: RowText(title: 'quantity')),
                  Flexible(child: RowText(title: 'price')),
                  Flexible(child: RowText(title: 'total')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          GetBuilder<SalesController>(
            builder: (controller) {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.invoiceModel == null) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              final invoice = controller.invoiceModel!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return ProudactDetailsWidget(
                        image: invoice.productImage,
                        cost: invoice.cost.toString(),
                        product: invoice.product.toString(),
                        quantity: invoice.quantity.toString(),
                      );
                    } else {
                      final sub = invoice.subProducts[index - 1];
                      return ProudactDetailsWidget(
                        image: sub.productImage,
                        cost: sub.cost.toString(),
                        product: sub.productName.toString(),
                        quantity: sub.quantity.toString(),
                      );
                    }
                  },
                  childCount: 1 + invoice.subProducts.length,
                ),
              );
            },
          ),
          GetBuilder<SalesController>(
            builder: (controller) {
              if (controller.invoiceModel == null) {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 20.h),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30.w),
                      height: 1.h,
                      width: double.infinity,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
                      child: Text(
                        '${'discount'.tr} : ${controller.invoiceModel!.discount}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
                      child: Text(
                        '${'totalBill'.tr} : ${NumberFormat("#,###").format(double.parse(controller.invoiceModel!.totalCost))}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
