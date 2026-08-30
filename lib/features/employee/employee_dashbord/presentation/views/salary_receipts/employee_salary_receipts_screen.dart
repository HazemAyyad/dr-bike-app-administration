import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../../controllers/employee_salary_receipt_controller.dart';

class EmployeeSalaryReceiptsScreen
    extends GetView<EmployeeSalaryReceiptController> {
  const EmployeeSalaryReceiptsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => controller.loadHistory());
    return Scaffold(
      appBar: CustomAppBar(
        title: 'سندات رواتبي',
        action: false,
        actions: [
          IconButton(
            tooltip: 'فلترة السندات',
            onPressed: () => _filters(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.historyLoading.value && controller.allReceipts.isEmpty) {
          return const _ReceiptsSkeleton();
        }
        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: controller.allReceipts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: 110.h),
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 66.sp,
                      color: AppColors.operationalPurple.withValues(alpha: .32),
                    ),
                    SizedBox(height: 12.h),
                    const Text(
                      'لا توجد سندات رواتب مطابقة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      'ستظهر سندات الصرف والتوقيع هنا',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 70.h),
                  itemCount: controller.allReceipts.length,
                  separatorBuilder: (_, __) => SizedBox(height: 9.h),
                  itemBuilder: (_, index) =>
                      _ReceiptCard(row: controller.allReceipts[index]),
                ),
        );
      }),
    );
  }

  void _filters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'فلترة سندات الرواتب',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 12.h),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.historyStatus.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'حالة الإقرار',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('كل الحالات')),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('بانتظار التوقيع'),
                    ),
                    DropdownMenuItem(
                      value: 'received',
                      child: Text('تم الاستلام'),
                    ),
                    DropdownMenuItem(
                      value: 'disputed',
                      child: Text('معترض عليه'),
                    ),
                  ],
                  onChanged: (value) =>
                      controller.historyStatus.value = value ?? '',
                )),
            SizedBox(height: 10.h),
            Obx(() => ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(
                      color: AppColors.operationalCardBorder,
                    ),
                  ),
                  leading: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.operationalPurple,
                  ),
                  title: const Text('شهر الراتب'),
                  subtitle: Text(controller.historyMonth.value.isEmpty
                      ? 'كل الأشهر'
                      : controller.historyMonth.value),
                  trailing: controller.historyMonth.value.isEmpty
                      ? const Icon(Icons.chevron_left_rounded)
                      : IconButton(
                          onPressed: () => controller.historyMonth.value = '',
                          icon: const Icon(Icons.close_rounded),
                        ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(
                            '${controller.historyMonth.value}-01',
                          ) ??
                          now,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(now.year + 1, 12),
                      helpText: 'اختر شهر الراتب',
                    );
                    if (picked != null) {
                      controller.historyMonth.value =
                          DateFormat('yyyy-MM').format(picked);
                    }
                  },
                )),
            SizedBox(height: 13.h),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                controller.loadHistory();
              },
              icon: const Icon(Icons.filter_alt_rounded),
              label: const Text('تطبيق الفلاتر'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends GetView<EmployeeSalaryReceiptController> {
  const _ReceiptCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final period = row['salary_period'];
    final batch = row['batch'];
    final status = '${row['receipt_status'] ?? 'pending'}';
    final id = int.tryParse('${row['id']}') ?? 0;
    final monthRaw = period is Map ? '${period['salary_month'] ?? ''}' : '';
    final month = monthRaw.length >= 7 ? monthRaw.substring(0, 7) : monthRaw;
    final color = status == 'received'
        ? AppColors.customGreen1
        : status == 'disputed'
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: .32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.receipt_long_rounded, color: color),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سند راتب $month',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'رقم السند #$id • ${batch is Map ? batch['payment_date'] ?? '' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              status == 'received'
                  ? 'تم الاستلام'
                  : status == 'disputed'
                      ? 'اعتراض'
                      : 'بانتظار التوقيع',
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ]),
        SizedBox(height: 11.h),
        Row(children: [
          Expanded(
            child: _Amount(
              label: 'الاستحقاق',
              value: period is Map ? period['gross_entitlement'] : 0,
            ),
          ),
          Expanded(
            child: _Amount(
              label: 'السلف',
              value: period is Map ? period['advances_applied'] : 0,
            ),
          ),
          Expanded(
            child: _Amount(
              label: 'الدفعة',
              value: row['amount_paid'],
              color: AppColors.customGreen1,
            ),
          ),
        ]),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 43.h,
          child: Obx(() => OutlinedButton.icon(
                onPressed: controller.downloadingReceiptId.value == null
                    ? () => controller.downloadReceipt(id)
                    : null,
                icon: controller.downloadingReceiptId.value == id
                    ? SizedBox.square(
                        dimension: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(controller.downloadingReceiptId.value == id
                    ? 'جاري تجهيز السند...'
                    : 'عرض وتنزيل سند الراتب PDF'),
              )),
        ),
      ]),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.color});
  final String label;
  final dynamic value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(
          label,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9.sp),
        ),
        FittedBox(
          child: Text(
            EmployeeSalaryReceiptController.money(value),
            style: TextStyle(
              color: color ?? AppColors.operationalNavy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text('شيكل', style: TextStyle(fontSize: 8.sp)),
      ]);
}

class _ReceiptsSkeleton extends StatelessWidget {
  const _ReceiptsSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: EdgeInsets.all(13.r),
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(height: 9.h),
        itemBuilder: (_, __) => SkeletonBlock(
          width: double.infinity,
          height: 168.h,
          radius: 16,
        ),
      );
}
