import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../../core/utils/app_colors.dart';
import '../../controllers/payroll_controller.dart';
import '../../widgets/financial_image_cache.dart';
import '../../widgets/financial_operational_ui.dart';
import '../../widgets/financial_skeletons.dart';

class SalaryPeriodDetailsScreen extends StatefulWidget {
  const SalaryPeriodDetailsScreen({Key? key}) : super(key: key);

  @override
  State<SalaryPeriodDetailsScreen> createState() =>
      _SalaryPeriodDetailsScreenState();
}

class _SalaryPeriodDetailsScreenState extends State<SalaryPeriodDetailsScreen> {
  late final PayrollController controller;
  late final int periodId;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PayrollController>();
    periodId = _int(Get.arguments is Map ? Get.arguments['period_id'] : null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (periodId > 0) controller.loadPeriodProfile(periodId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: CustomAppBar(
          title: 'ملف الراتب',
          action: false,
          actions: [
            Obx(() {
              final profile = controller.periodProfile.value;
              final payments = _list(profile?['payments']);
              if (payments.isEmpty) return const SizedBox.shrink();
              final id = _int(payments.first['id']);
              final loading = controller.downloadingReceiptId.value == id;
              return IconButton(
                tooltip: 'تصدير أحدث سند PDF',
                onPressed:
                    loading ? null : () => controller.downloadReceipt(id),
                icon: loading
                    ? SizedBox.square(
                        dimension: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
              );
            }),
            SizedBox(width: 5.w),
          ],
        ),
        body: Obx(() {
          if (controller.isPeriodProfileLoading.value) {
            return const SingleChildScrollView(child: FinancialFormSkeleton());
          }
          final profile = controller.periodProfile.value;
          if (profile == null) {
            return _LoadError(
                onRetry: () => controller.loadPeriodProfile(periodId));
          }
          return RefreshIndicator(
            onRefresh: () => controller.loadPeriodProfile(periodId),
            child: _SalaryProfile(profile: profile, controller: controller),
          );
        }),
      );
}

class _SalaryProfile extends StatelessWidget {
  const _SalaryProfile({required this.profile, required this.controller});
  final Map<String, dynamic> profile;
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final employee = _map(profile['employee']);
    final user = _map(employee['user']);
    final payments = _list(profile['payments']);
    final expense = _map(profile['expense']);
    final month = _month(profile['salary_month']);
    return ListView(
      padding: EdgeInsets.fromLTRB(13.w, 10.h, 13.w, 42.h),
      children: [
        _ProfileHero(
          employeeName: '${user['name'] ?? 'موظف'}',
          month: month,
          status: '${profile['status'] ?? ''}',
          paymentsCount: payments.length,
        ),
        SizedBox(height: 10.h),
        _SummaryGrid(profile: profile),
        SizedBox(height: 12.h),
        const FinancialGroupTitle(title: 'تفاصيل الاحتساب'),
        FinancialOperationalCard(
          child: Column(children: [
            _InfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'الراتب الأساسي',
              value: _money(profile['normal_salary']),
            ),
            _InfoRow(
              icon: Icons.more_time_rounded,
              label: 'العمل الإضافي',
              value: _money(profile['overtime_salary']),
            ),
            _InfoRow(
              icon: Icons.workspace_premium_outlined,
              label: 'المكافآت',
              value: _money(profile['bonuses']),
            ),
            _InfoRow(
              icon: Icons.savings_outlined,
              label: 'السلف المخصومة',
              value: _money(profile['advances_applied']),
              color: Colors.orange.shade800,
              last: true,
            ),
          ]),
        ),
        if (expense.isNotEmpty) ...[
          SizedBox(height: 12.h),
          const FinancialGroupTitle(title: 'القيد المحاسبي'),
          FinancialOperationalCard(
            child: Row(children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.operationalPurple.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.operationalPurple),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${expense['name'] ?? 'قيد الراتب'}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      'قيد محمي مرتبط بهذا الملف ولا يُعدّل كمصروف يدوي',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.lock_rounded, color: AppColors.customGreen1),
            ]),
          ),
        ],
        SizedBox(height: 12.h),
        FinancialGroupTitle(
            title: 'دفعات وسندات الراتب', count: payments.length),
        if (payments.isEmpty)
          const FinancialOperationalCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text('لا توجد دفعات مسجلة لهذا الشهر',
                  textAlign: TextAlign.center),
            ),
          )
        else
          ...payments.map((payment) => Padding(
                padding: EdgeInsets.only(bottom: 9.h),
                child: _PaymentCard(payment: payment, controller: controller),
              )),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.employeeName,
    required this.month,
    required this.status,
    required this.paymentsCount,
  });
  final String employeeName;
  final String month;
  final String status;
  final int paymentsCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.operationalNavy, AppColors.operationalPurple],
          ),
          borderRadius: BorderRadius.circular(19.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.operationalPurple.withValues(alpha: .18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          Row(children: [
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: const Icon(Icons.badge_rounded, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employeeName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900)),
                  Text('راتب شهر $month • $paymentsCount دفعة',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          fontSize: 11.sp)),
                ],
              ),
            ),
            _StatusBadge(status: status),
          ]),
          SizedBox(height: 13.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Row(children: [
              Icon(Icons.verified_user_outlined, color: Colors.white, size: 19),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'كل دفعة تحتفظ بحالة الاستلام والتوقيع وسند PDF مستقل',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ]),
          ),
        ]),
      );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: _SummaryTile(
            label: 'الاستحقاق',
            value: profile['gross_entitlement'],
            icon: Icons.calculate_outlined,
            color: AppColors.operationalPurple,
          ),
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: _SummaryTile(
            label: 'المدفوع',
            value: profile['total_paid'],
            icon: Icons.payments_rounded,
            color: AppColors.customGreen1,
          ),
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: _SummaryTile(
            label: 'المتبقي',
            value: profile['remaining'],
            icon: Icons.hourglass_bottom_rounded,
            color: Colors.orange.shade800,
          ),
        ),
      ]);
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: .22)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 21.sp),
          SizedBox(height: 5.h),
          Text(label,
              style: TextStyle(
                  fontSize: 9.5.sp, color: AppColors.customGreyColor5)),
          FittedBox(
            child: Text('${_money(value)} ₪',
                style: TextStyle(fontWeight: FontWeight.w900, color: color)),
          ),
        ]),
      );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.controller});
  final Map<String, dynamic> payment;
  final PayrollController controller;

  @override
  Widget build(BuildContext context) {
    final id = _int(payment['id']);
    final status = '${payment['receipt_status'] ?? 'pending'}';
    final batch = _map(payment['batch']);
    final box = _map(batch['box']);
    final creator = _map(batch['creator']);
    final signaturePath = '${payment['employee_signature_path'] ?? ''}'.trim();
    final signed = status == 'received' && signaturePath.isNotEmpty;
    final statusColor = status == 'received'
        ? AppColors.customGreen1
        : status == 'disputed'
            ? Colors.red
            : Colors.orange;
    return FinancialOperationalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              status == 'received'
                  ? Icons.verified_rounded
                  : status == 'disputed'
                      ? Icons.report_problem_rounded
                      : Icons.pending_actions_rounded,
              color: statusColor,
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('دفعة #$id • ${_money(payment['amount_paid'])} ₪',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(_receiptLabel(status),
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w700)),
            ]),
          ),
          Text(_date(batch['payment_date']),
              style: Theme.of(context).textTheme.bodySmall),
        ]),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.operationalSurface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(children: [
            _CompactLine(label: 'الصندوق', value: '${box['name'] ?? '—'}'),
            _CompactLine(
                label: 'تم الصرف بواسطة', value: '${creator['name'] ?? '—'}'),
            _CompactLine(
              label: 'تاريخ تأكيد الموظف',
              value: status == 'received'
                  ? _dateTime(payment['received_at'])
                  : '—',
            ),
          ]),
        ),
        if (status == 'disputed') ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(color: Colors.red.withValues(alpha: .2)),
            ),
            child: Text(
                'سبب الاعتراض: ${payment['dispute_reason'] ?? 'غير محدد'}'),
          ),
        ],
        if (signed) ...[
          SizedBox(height: 9.h),
          Row(children: [
            const Text('توقيع الموظف',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            Text('${payment['employee_signature_name'] ?? 'التوقيع المعتمد'}',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          SizedBox(height: 6.h),
          Container(
            height: 105.h,
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.operationalCardBorder),
            ),
            child: CachedNetworkImage(
              cacheManager: FinancialImageCache.instance,
              imageUrl: ShowNetImage.getPhoto(signaturePath),
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Text('تعذر عرض صورة التوقيع'),
              ),
            ),
          ),
        ],
        SizedBox(height: 10.h),
        Obx(() {
          final loading = controller.downloadingReceiptId.value == id;
          return FilledButton.icon(
            onPressed: loading ? null : () => controller.downloadReceipt(id),
            icon: loading
                ? SizedBox.square(
                    dimension: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            label:
                Text(loading ? 'جاري تجهيز السند...' : 'تصدير سند الراتب PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.operationalNavy,
              minimumSize: Size.fromHeight(47.h),
            ),
          );
        }),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.operationalCardBorder)),
        ),
        child: Row(children: [
          Icon(icon, size: 20.sp, color: color ?? AppColors.operationalPurple),
          SizedBox(width: 8.w),
          Expanded(child: Text(label)),
          Text('$value ₪',
              style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ]),
      );
}

class _CompactLine extends StatelessWidget {
  const _CompactLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Row(children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(_salaryLabel(status),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined,
                size: 58.sp, color: AppColors.operationalPurple),
            SizedBox(height: 10.h),
            const Text('تعذر تحميل ملف الراتب',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            SizedBox(height: 10.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ]),
        ),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
    : <Map<String, dynamic>>[];

int _int(dynamic value) => int.tryParse('$value') ?? 0;
String _money(dynamic value) =>
    (double.tryParse('$value') ?? 0).toStringAsFixed(2);
String _month(dynamic value) {
  final text = '$value';
  return text.length >= 7 ? text.substring(0, 7) : text;
}

String _date(dynamic value) {
  final parsed = DateTime.tryParse('$value');
  return parsed == null ? '—' : DateFormat('yyyy-MM-dd').format(parsed);
}

String _dateTime(dynamic value) {
  final parsed = DateTime.tryParse('$value')?.toLocal();
  return parsed == null ? '—' : DateFormat('yyyy-MM-dd • HH:mm').format(parsed);
}

String _receiptLabel(String status) => status == 'received'
    ? 'تم الاستلام والتوقيع'
    : status == 'disputed'
        ? 'اعترض الموظف على الدفعة'
        : 'بانتظار توقيع الموظف';

String _salaryLabel(String status) => status == 'paid'
    ? 'مدفوع بالكامل'
    : status == 'partially_paid'
        ? 'مدفوع جزئيًا'
        : status == 'cancelled'
            ? 'ملغي'
            : 'قيد الاحتساب';
