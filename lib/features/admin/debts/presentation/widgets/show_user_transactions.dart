import 'package:doctorbike/features/admin/debts/data/models/user_transactions_data_model.dart';
import 'package:doctorbike/features/admin/debts/presentation/widgets/user_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/debts_controller.dart';
import 'app_bar.dart';
import 'gave_and_took_button.dart';
import 'user_transactions_widget.dart';

class ShowUserTransactions extends GetView<DebtsController> {
  const ShowUserTransactions({Key? key, required this.debt}) : super(key: key);

  final dynamic debt;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        appBar: appBar(
          debt.customerName,
          false,
          context,
          Get.find<DebtsController>(),
          '',
          null,
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              UserAccount(),
              SizedBox(height: 20.h),
              Obx(
                () => Text(
                  '${'transactions'.tr} (${controller.dataService.userTransactionsDataModel.value == null ? 0 : controller.dataService.userTransactionsDataModel.value!.customerDebts.length})',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: ThemeService.isDark.value
                            ? AppColors.primaryColor
                            : AppColors.secondaryColor,
                      ),
                ),
              ),
              SizedBox(height: 10.h),
              Obx(
                () {
                  if (controller.userTransactionsLoading.value) {
                    return const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
                    );
                  } else if (controller
                          .dataService.userTransactionsDataModel.value ==
                      null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 200.h),
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 100.h,
                            color: AppColors.graywhiteColor,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'noDebts'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.graywhiteColor,
                                ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Expanded(
                    child: ListView.builder(
                      itemCount: controller
                          .dataService
                          .userTransactionsDataModel
                          .value!
                          .customerDebts
                          .length,
                      itemBuilder: (context, index) {
                        final reversedIndex = controller
                                .dataService
                                .userTransactionsDataModel
                                .value!
                                .customerDebts
                                .length -
                            1 -
                            index;

                        Debt debt = controller
                            .dataService
                            .userTransactionsDataModel
                            .value!
                            .customerDebts[reversedIndex];
                        return UserTransactionsWidget(debt: debt, index: index);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: GaveAndTookButton(),
      ),
    );
  }
}
