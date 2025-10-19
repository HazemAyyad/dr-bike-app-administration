import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/show_no_data.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../controllers/bills_controller.dart';
import '../../widgets/bills_widgets/bill_details.dart';
import '../../widgets/bills_widgets/bill_seller_details.dart';
import '../../widgets/bills_widgets/bill_title.dart';
import '../../widgets/purchase_orders_widgets/cancel_bill.dart';

class BillDetailsScreen extends GetView<BillsController> {
  const BillDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String page = Get.arguments;
    return Scaffold(
      appBar: CustomAppBar(
        title: 'billDetails',
        action: false,
        actions: [
          IconButton(
            onPressed: () {
              controller.getBillDetails(
                context: context,
                billId: controller.billDetails!.billId.toString(),
                isDownload: true,
              );
            },
            icon: Icon(
              Icons.file_download_outlined,
              color: AppColors.primaryColor,
              size: 30.sp,
            ),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(child: BillTitle(page: page)),
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          GetBuilder<BillsController>(
            builder: (controller) {
              if (controller.isAddLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.billDetails == null) {
                return const SliverFillRemaining(
                  child: Center(child: ShowNoData()),
                );
              }
              return SliverToBoxAdapter(
                child: Column(
                  children: [
                    BillDetails(page: page),
                    const BillSellerDetails(),
                    SizedBox(height: 10.h),
                    page == '3' || page == '4'
                        ? CancelBill(billId: controller.billDetails!.billId)
                        : const SizedBox.shrink(),
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
