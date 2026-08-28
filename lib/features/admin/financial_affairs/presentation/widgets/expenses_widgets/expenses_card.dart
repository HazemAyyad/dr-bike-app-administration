import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/expenses_models/expense_data_model.dart';
import '../../controllers/expenses_controller.dart';
import '../financial_operational_ui.dart';
import '../financial_image_cache.dart';

class ExpensesCard extends GetView<ExpensesController> {
  const ExpensesCard({Key? key, required this.expense}) : super(key: key);
  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) => FinancialOperationalCard(
        onTap: () {
          controller.isEditing.value = true;
          controller.isExpenseReadOnly.value = true;
          controller.getExpensesData(expenseId: expense.id.toString());
          Get.toNamed(AppRoutes.ADDEXPENSESCREEN);
        },
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: CachedNetworkImage(
              cacheManager: FinancialImageCache.instance,
              imageUrl: expense.image ?? '',
              width: 34.w,
              height: 34.w,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  SkeletonBlock(width: 34.w, height: 34.w, radius: 10),
              errorWidget: (_, __, ___) => Container(
                  width: 34.w,
                  height: 34.w,
                  color: AppColors.operationalSurface,
                  child: Icon(Icons.receipt_long_outlined,
                      color: AppColors.operationalPurple, size: 20.sp)),
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(expense.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.operationalNavy)),
                SizedBox(height: 3.h),
                Row(children: [
                  Icon(Icons.schedule,
                      size: 11.sp, color: AppColors.customGreyColor5),
                  SizedBox(width: 3.w),
                  Text(showData(expense.createdAt),
                      style: TextStyle(
                          fontSize: 10.sp, color: AppColors.customGreyColor5)),
                ]),
              ])),
          FinancialMiniChip(
              label:
                  '${NumberFormat('#,###.##').format(double.tryParse(expense.price) ?? 0)} ₪',
              color: AppColors.operationalPurple,
              icon: Icons.payments_outlined),
        ]),
      );
}
