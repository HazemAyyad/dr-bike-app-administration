import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/expenses_models/expense_data_model.dart';
import '../../controllers/expenses_controller.dart';

class ExpensesCard extends GetView<ExpensesController> {
  const ExpensesCard({Key? key, required this.expense}) : super(key: key);

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.isEditing.value = true;
        controller.getExpensesData(expenseId: expense.id.toString());
        Get.toNamed(AppRoutes.ADDEXPENSESCREEN);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.all(5.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.r),
                child: CachedNetworkImage(
                  cacheManager: CacheManager(
                    Config(
                      'imagesCache',
                      stalePeriod: const Duration(days: 7),
                      maxNrOfCacheObjects: 100,
                    ),
                  ),
                  imageBuilder: (context, imageProvider) => Container(
                    height: 50.h,
                    width: 60.w,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  imageUrl: expense.image!,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                expense.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.graywhiteColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    borderRadius: Get.locale!.languageCode != 'ar'
                        ? BorderRadius.only(
                            bottomRight: Radius.circular(4.r),
                            topRight: Radius.circular(4.r),
                          )
                        : BorderRadius.only(
                            bottomLeft: Radius.circular(4.r),
                            topLeft: Radius.circular(4.r),
                          ),
                    color: AppColors.graywhiteColor,
                  ),
                  height: 60.h,
                  width: 60.w,
                  child: Center(
                    child: Text(
                      NumberFormat('#,###').format(double.parse(expense.price)),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.blackColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
