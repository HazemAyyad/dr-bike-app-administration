import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import 'delivered_purchases_dialog.dart';

class ReturnPurchasesList extends StatelessWidget {
  const ReturnPurchasesList({
    Key? key,
    required this.month,
    required this.bills,
  }) : super(key: key);

  final String month;
  final List bills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Text(
            month,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                ),
          ),
          SizedBox(height: 8.h),
          ...bills.map((bill) => _ReturnPurchaseCard(bill: bill)),
        ],
      ),
    );
  }
}

class _ReturnPurchaseCard extends StatelessWidget {
  const _ReturnPurchaseCard({required this.bill});

  final dynamic bill;

  @override
  Widget build(BuildContext context) {
    final firstItem = bill.items.isEmpty ? null : bill.items.first;
    final total = double.tryParse(bill.total.toString()) ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        Get.dialog(
          DeliveredPurchasesDialog(
            billId: bill.id.toString(),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(32),
              blurRadius: 5.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.assignment_return_outlined,
                        color: AppColors.primaryColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'مرتجع #${bill.id}',
                            value: bill.createdAt?.toString() ?? '',
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${'sellerName1'.tr}: ${bill.seller.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          SizedBox(height: 5.h),
                          Wrap(
                            spacing: 5.w,
                            runSpacing: 5.h,
                            children: [
                              if (firstItem != null)
                                _MiniChip(
                                  icon: Icons.inventory_2_outlined,
                                  text: firstItem.productName,
                                ),
                              if (firstItem != null)
                                _MiniChip(
                                  icon: Icons.numbers_outlined,
                                  text:
                                      '${'quantity'.tr}: ${firstItem.quantity}',
                                ),
                              _MiniChip(
                                icon: Icons.list_alt_outlined,
                                text: '${bill.items.length} أصناف',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minWidth: 72.w, maxWidth: 110.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.customGreen1,
                borderRadius: Get.locale!.languageCode == 'en'
                    ? const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'total'.tr,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${NumberFormat('#,##0.00').format(total)} ₪',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor5,
                ),
          ),
        ),
        if (value.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor5,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.primaryColor),
          SizedBox(width: 4.w),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                ),
          ),
        ],
      ),
    );
  }
}
