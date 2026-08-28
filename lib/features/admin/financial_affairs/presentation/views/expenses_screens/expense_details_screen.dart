import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/expenses_controller.dart';
import '../../widgets/financial_image_cache.dart';
import '../../widgets/financial_operational_ui.dart';
import '../../widgets/financial_skeletons.dart';

class ExpenseDetailsScreen extends GetView<ExpensesController> {
  const ExpenseDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل المصروف',
        action: false,
        actions: [
          IconButton(
            tooltip: 'تعديل المصروف',
            onPressed: () {
              controller.isEditing.value = true;
              controller.isExpenseReadOnly.value = false;
              Get.toNamed(AppRoutes.ADDEXPENSESCREEN);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: GetBuilder<ExpensesController>(builder: (_) {
        if (controller.isLoadingGet.value ||
            controller.selectedExpense.value == null) {
          return const SingleChildScrollView(child: FinancialFormSkeleton());
        }
        final expense = controller.selectedExpense.value!;
        final images = <String>[...expense.invoiceImg, ...expense.media];
        final typeLabel = expense.expenseType == 'salary'
            ? 'مصروف راتب'
            : expense.expenseType == 'destruction'
                ? 'مصروف إتلاف بضاعة'
                : 'مصروف عمومي';
        return ListView(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 36.h),
          children: [
            FinancialOperationalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: AppColors.operationalSurface,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.receipt_long_outlined,
                          color: AppColors.operationalPurple, size: 23.sp),
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.name,
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.operationalNavy)),
                          SizedBox(height: 3.h),
                          Text(typeLabel,
                              style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: AppColors.customGreyColor5)),
                        ],
                      ),
                    ),
                    FinancialMiniChip(
                      label:
                          '${NumberFormat('#,###.##').format(double.tryParse(expense.price) ?? 0)} ₪',
                      color: AppColors.operationalPurple,
                      icon: Icons.payments_outlined,
                    ),
                  ]),
                  SizedBox(height: 12.h),
                  Row(children: [
                    Expanded(
                      child: _DetailTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'الصندوق',
                        value: expense.boxName.isEmpty
                            ? 'صندوق #${expense.boxId}'
                            : expense.boxName,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _DetailTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'تاريخ المصروف',
                        value: DateFormat('yyyy-MM-dd')
                            .format(expense.expenseDate),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            const FinancialGroupTitle(title: 'الملاحظات'),
            FinancialOperationalCard(
              child: Text(
                (expense.notes ?? '').trim().isEmpty
                    ? 'لا توجد ملاحظات'
                    : expense.notes!,
                style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.6,
                    color: AppColors.operationalNavy),
              ),
            ),
            SizedBox(height: 10.h),
            FinancialGroupTitle(title: 'المرفقات', count: images.length),
            if (images.isEmpty)
              FinancialOperationalCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  child: const Text('لا توجد مرفقات',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.customGreyColor5)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) => InkWell(
                  onTap: () => showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Dismiss',
                    pageBuilder: (_, __, ___) => FullScreenZoomImage(
                      imageUrl: images[index],
                      imageUrls: images,
                      downloadFolderSegments: [
                        'Expenses',
                        expense.name,
                        'Attachments'
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11.r),
                    child: CachedNetworkImage(
                      cacheManager: FinancialImageCache.instance,
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.operationalSurface),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.operationalSurface,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(9.r),
        decoration: BoxDecoration(
          color: AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(children: [
          Icon(icon, size: 18.sp, color: AppColors.operationalPurple),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 8.5.sp, color: AppColors.customGreyColor5)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.operationalNavy)),
              ],
            ),
          ),
        ]),
      );
}
