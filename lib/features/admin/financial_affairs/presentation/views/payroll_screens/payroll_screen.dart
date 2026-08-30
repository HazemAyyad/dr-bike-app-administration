import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../../core/services/theme_service.dart';
import '../../../../../../../core/utils/app_colors.dart';
import '../../../../../../../core/widgets/skeleton_loading.dart';
import '../../controllers/payroll_controller.dart';
import '../../widgets/financial_operational_ui.dart';

class PayrollScreen extends GetView<PayrollController> {
  const PayrollScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'دفع الرواتب',
            action: false,
            actions: [
              IconButton(
                tooltip: 'تقرير الرواتب',
                onPressed: () => _showReportModal(context),
                icon: const Icon(Icons.assessment_outlined),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(55.h),
              child: Container(
                height: 47.h,
                margin: EdgeInsets.fromLTRB(14.w, 0, 14.w, 8.h),
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor
                      : AppColors.operationalSurface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.operationalCardBorder),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: const LinearGradient(colors: [
                      AppColors.operationalPurple,
                      AppColors.secondaryColor,
                    ]),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: ThemeService.isDark.value
                      ? Colors.white70
                      : AppColors.operationalNavy,
                  tabs: const [
                    Tab(icon: Icon(Icons.payments_rounded), text: 'صرف جديد'),
                    Tab(icon: Icon(Icons.receipt_long_rounded), text: 'السجل'),
                  ],
                ),
              ),
            ),
          ),
          body: const TabBarView(children: [
            _NewPaymentTab(),
            _HistoryTab(),
          ]),
        ),
      );

  void _showReportModal(BuildContext context) {
    final controller = Get.find<PayrollController>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.operationalPurple.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: AppColors.operationalPurple,
                  ),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تقرير الرواتب الشهري',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Obx(() => Text(
                            'شهر ${controller.month.value} • حسب الفلاتر الحالية',
                          )),
                    ],
                  ),
                ),
              ]),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.operationalSurface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.operationalCardBorder),
                ),
                child: const Text(
                  'يتضمن الاستحقاقات، السلف المسواة، المدفوع، المتبقي، وحالات توقيع أو اعتراض كل موظف. يتم إنشاء PDF عربي بخط Almarai.',
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 13.h),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  controller.downloadPayrollReport();
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('إنشاء وتنزيل التقرير PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.operationalPurple,
                  minimumSize: Size.fromHeight(49.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPaymentTab extends GetView<PayrollController> {
  const _NewPaymentTab();

  @override
  Widget build(BuildContext context) => Obx(() {
        if (controller.isLoading.value) return const _PayrollSkeleton();
        return RefreshIndicator(
          onRefresh: controller.loadInitial,
          child: ListView(
            padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 90.h),
            children: [
              _CycleCard(),
              SizedBox(height: 9.h),
              _EmployeesCard(),
              SizedBox(height: 10.h),
              if (controller.previewRows.isEmpty)
                _PreviewButton()
              else ...[
                _SummaryCard(rows: controller.previewRows),
                SizedBox(height: 9.h),
                ...controller.previewRows.map(
                  (row) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _EmployeeAmountCard(row: row),
                  ),
                ),
                _SubmitCard(),
              ],
            ],
          ),
        );
      });
}

class _CycleCard extends GetView<PayrollController> {
  @override
  Widget build(BuildContext context) => FinancialOperationalCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Title(
            icon: Icons.calendar_month_rounded,
            title: 'دورة الراتب',
            subtitle: 'حدد الشهر وصندوق الدفع النقدي',
          ),
          SizedBox(height: 10.h),
          Row(children: [
            Expanded(
              child: Obx(() => _Picker(
                    icon: Icons.event_rounded,
                    label: 'الشهر',
                    value: controller.month.value,
                    onTap: () => controller.selectMonth(context),
                  )),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Obx(() {
                final box = controller.boxes.firstWhereOrNull(
                  (e) =>
                      int.tryParse('${e['id']}') ==
                      controller.selectedBoxId.value,
                );
                return _Picker(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'الصندوق',
                  value: '${box?['name'] ?? 'اختر الصندوق'}',
                  color: box == null ? Colors.orange : AppColors.customGreen1,
                  onTap: () => _boxesSheet(context),
                );
              }),
            ),
          ]),
        ]),
      );

  void _boxesSheet(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const _Title(
                icon: Icons.account_balance_wallet_rounded,
                title: 'صندوق الدفع',
                subtitle: 'الصناديق المسموحة واليومية المفتوحة فقط',
              ),
              SizedBox(height: 10.h),
              if (controller.boxes.isEmpty)
                const ListTile(title: Text('لا يوجد صندوق شيكل متاح')),
              ...controller.boxes.map((box) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.operationalPurple.withValues(alpha: .1),
                      child: const Icon(Icons.wallet_rounded,
                          color: AppColors.operationalPurple),
                    ),
                    title: Text('${box['name']}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '${PayrollController.money(box['total'])} شيكل${box['is_daily_open'] == true ? ' • يومي مفتوح' : ''}'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () {
                      controller.selectedBoxId.value =
                          int.tryParse('${box['id']}');
                      Navigator.pop(context);
                    },
                  )),
            ]),
          ),
        ),
      );
}

class _EmployeesCard extends GetView<PayrollController> {
  @override
  Widget build(BuildContext context) => FinancialOperationalCard(
        child: Column(children: [
          Row(children: [
            const Expanded(
              child: _Title(
                icon: Icons.groups_rounded,
                title: 'الموظفون',
                subtitle: 'موظف واحد أو عدة موظفين معاً',
              ),
            ),
            TextButton.icon(
              onPressed: controller.selectAllVisible,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('الكل'),
            ),
          ]),
          SizedBox(height: 8.h),
          TextField(
            controller: controller.employeeSearchController,
            onChanged: (_) => controller.update(),
            decoration: InputDecoration(
              hintText: 'ابحث باسم الموظف أو المسمى',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 7.h),
          GetBuilder<PayrollController>(builder: (_) {
            final rows = controller.filteredEmployees;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 245.h),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final row = rows[index];
                  final id = int.tryParse('${row['id']}') ?? 0;
                  return Obx(() => CheckboxListTile(
                        value: controller.selectedEmployeeIds.contains(id),
                        onChanged: (_) => controller.toggleEmployee(id),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text('${row['name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${row['job_title'] ?? 'موظف'}'),
                        secondary: CircleAvatar(
                          backgroundColor:
                              AppColors.operationalPurple.withValues(alpha: .1),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.operationalPurple),
                        ),
                      ));
                },
              ),
            );
          }),
        ]),
      );
}

class _PreviewButton extends GetView<PayrollController> {
  @override
  Widget build(BuildContext context) => Obx(() => SizedBox(
        height: 51.h,
        child: FilledButton.icon(
          onPressed:
              controller.isPreviewLoading.value ? null : controller.preview,
          icon: controller.isPreviewLoading.value
              ? SizedBox.square(
                  dimension: 20.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.calculate_rounded),
          label: Text(controller.isPreviewLoading.value
              ? 'جاري احتساب الرواتب...'
              : 'معاينة الحسبة قبل الصرف'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.operationalPurple,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      ));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});
  final List<Map<String, dynamic>> rows;

  double total(String key) =>
      rows.fold(0, (v, e) => v + (double.tryParse('${e[key]}') ?? 0));

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(15.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            AppColors.operationalNavy,
            AppColors.operationalPurple,
          ]),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.operationalPurple.withValues(alpha: .2),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ملخص الدفعة',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
          SizedBox(height: 11.h),
          Row(children: [
            Expanded(
                child: _SummaryValue(
                    label: 'الاستحقاق', value: total('gross_entitlement'))),
            Expanded(
                child: _SummaryValue(
                    label: 'السلف', value: total('advances_to_apply'))),
            Expanded(
                child: _SummaryValue(
                    label: 'المتبقي النقدي',
                    value: total('remaining'),
                    highlight: true)),
          ]),
        ]),
      );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue(
      {required this.label, required this.value, this.highlight = false});
  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .7), fontSize: 9.5.sp)),
        SizedBox(height: 3.h),
        FittedBox(
          child: Text(value.toStringAsFixed(2),
              style: TextStyle(
                  color: highlight ? const Color(0xFFFFD166) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.sp)),
        ),
        Text('شيكل',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .6), fontSize: 9.sp)),
      ]);
}

class _EmployeeAmountCard extends GetView<PayrollController> {
  const _EmployeeAmountCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse('${row['employee_id']}') ?? 0;
    final remaining = double.tryParse('${row['remaining']}') ?? 0;
    return FinancialOperationalCard(
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: AppColors.operationalPurple.withValues(alpha: .1),
            child: const Icon(Icons.person_rounded,
                color: AppColors.operationalPurple),
          ),
          SizedBox(width: 9.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${row['employee_name']}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                    'راتب ${row['salary_month']} • ${_salaryStatus('${row['status']}')}',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
          _StatusChip(status: '${row['status']}'),
        ]),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(
              child: _Amount(
                  label: 'الاستحقاق',
                  value: row['gross_entitlement'],
                  color: AppColors.operationalNavy)),
          Expanded(
              child: _Amount(
                  label: 'خصم السلف',
                  value: row['advances_to_apply'],
                  color: Colors.orange.shade800)),
          Expanded(
              child: _Amount(
                  label: 'مدفوع سابقاً',
                  value: row['total_paid'],
                  color: AppColors.customGreen1)),
        ]),
        SizedBox(height: 10.h),
        TextFormField(
          controller: controller.paymentAmounts[id],
          enabled: remaining > 0,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'المبلغ المدفوع الآن',
            helperText:
                'الحد الأعلى ${remaining.toStringAsFixed(2)} شيكل — يمكن دفع جزء',
            prefixIcon: const Icon(Icons.payments_outlined),
            suffixText: 'شيكل',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(13.r)),
          ),
        ),
      ]),
    );
  }
}

class _SubmitCard extends GetView<PayrollController> {
  @override
  Widget build(BuildContext context) => FinancialOperationalCard(
        child: Column(children: [
          TextField(
            controller: controller.notesController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'ملاحظات الدفعة (اختياري)',
              prefixIcon: const Icon(Icons.notes_rounded),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(13.r)),
            ),
          ),
          SizedBox(height: 10.h),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 51.h,
                child: FilledButton.icon(
                  onPressed: controller.isPaying.value
                      ? null
                      : () => _confirm(context),
                  icon: controller.isPaying.value
                      ? SizedBox.square(
                          dimension: 20.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_rounded),
                  label: Text(controller.isPaying.value
                      ? 'جاري صرف الرواتب...'
                      : 'تأكيد وصرف الرواتب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.customGreen1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                ),
              )),
        ]),
      );

  Future<void> _confirm(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.payments_rounded,
            color: AppColors.customGreen1, size: 42),
        title: const Text('تأكيد صرف الرواتب'),
        content: const Text(
          'سيتم خصم الدفعة النقدية من الصندوق وإرسال طلب توقيع الاستلام لكل موظف.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('مراجعة')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('صرف الآن')),
        ],
      ),
    );
    if (accepted == true) await controller.pay();
  }
}

class _HistoryTab extends GetView<PayrollController> {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: controller.loadHistory,
        child: ListView(
          padding: EdgeInsets.fromLTRB(13.w, 12.h, 13.w, 70.h),
          children: [
            FinancialOperationalCard(
              child: TextField(
                controller: controller.historySearchController,
                onChanged: (_) => controller.update(),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الموظف',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => _filters(context),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13.r)),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            GetBuilder<PayrollController>(builder: (_) {
              final rows = controller.filteredPeriods;
              if (rows.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: 70.h),
                  child: Column(children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 58.sp,
                        color:
                            AppColors.operationalPurple.withValues(alpha: .35)),
                    SizedBox(height: 9.h),
                    const Text('لا توجد رواتب مطابقة',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const Text('ستظهر الدفعات وإقرارات الاستلام هنا'),
                  ]),
                );
              }
              return Column(
                children: rows
                    .map((row) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _PeriodCard(row: row),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      );

  void _filters(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 22.h),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Title(
                    icon: Icons.tune_rounded,
                    title: 'فلترة سجل الرواتب',
                    subtitle: 'حسب حالة الدفع وإقرار الموظف'),
                SizedBox(height: 12.h),
                Obx(() => DropdownButtonFormField<String>(
                      initialValue: controller.historyStatus.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'حالة الراتب',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('كل الحالات')),
                        DropdownMenuItem(
                            value: 'partially_paid',
                            child: Text('مدفوع جزئياً')),
                        DropdownMenuItem(
                            value: 'paid', child: Text('مدفوع بالكامل')),
                      ],
                      onChanged: (value) =>
                          controller.historyStatus.value = value ?? '',
                    )),
                SizedBox(height: 9.h),
                Obx(() => DropdownButtonFormField<String>(
                      initialValue: controller.receiptStatus.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'إقرار الاستلام',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: '', child: Text('كل الإقرارات')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('بانتظار التوقيع')),
                        DropdownMenuItem(
                            value: 'received', child: Text('تم الاستلام')),
                        DropdownMenuItem(
                            value: 'disputed', child: Text('معترض عليه')),
                      ],
                      onChanged: (value) =>
                          controller.receiptStatus.value = value ?? '',
                    )),
                SizedBox(height: 12.h),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.loadHistory();
                  },
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: const Text('تطبيق الفلاتر'),
                ),
              ]),
        ),
      );
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PayrollController>();
    final employee = row['employee'];
    final user = employee is Map ? employee['user'] : null;
    final payments =
        row['payments'] is List ? row['payments'] as List : const [];
    final month = '${row['salary_month'] ?? ''}';
    return FinancialOperationalCard(
      child: Column(children: [
        Row(children: [
          const CircleAvatar(child: Icon(Icons.person_rounded)),
          SizedBox(width: 9.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${user is Map ? user['name'] ?? '' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('شهر ${month.length >= 7 ? month.substring(0, 7) : month}',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
          _StatusChip(status: '${row['status']}'),
        ]),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(
              child: _Amount(
                  label: 'الاستحقاق',
                  value: row['gross_entitlement'],
                  color: AppColors.operationalNavy)),
          Expanded(
              child: _Amount(
                  label: 'السلف',
                  value: row['advances_applied'],
                  color: Colors.orange.shade800)),
          Expanded(
              child: _Amount(
                  label: 'المتبقي',
                  value: row['remaining'],
                  color: AppColors.customGreen1)),
        ]),
        if (payments.isNotEmpty) ...[
          const Divider(),
          ...payments.map((p) => Obx(() => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  p['receipt_status'] == 'received'
                      ? Icons.verified_rounded
                      : p['receipt_status'] == 'disputed'
                          ? Icons.report_problem_rounded
                          : Icons.pending_actions_rounded,
                  color: p['receipt_status'] == 'received'
                      ? AppColors.customGreen1
                      : p['receipt_status'] == 'disputed'
                          ? Colors.red
                          : Colors.orange,
                ),
                title: Text('${PayrollController.money(p['amount_paid'])} شيكل',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(p['receipt_status'] == 'received'
                    ? 'تم الاستلام والتوقيع'
                    : p['receipt_status'] == 'disputed'
                        ? 'اعترض الموظف'
                        : 'بانتظار توقيع الموظف'),
                trailing: controller.downloadingReceiptId.value ==
                        int.tryParse('${p['id']}')
                    ? SizedBox.square(
                        dimension: 19.r,
                        child: const CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.red),
                onTap: () =>
                    controller.downloadReceipt(int.parse('${p['id']}')),
              ))),
        ],
      ]),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.operationalPurple.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(icon, color: AppColors.operationalPurple, size: 21.sp),
        ),
        SizedBox(width: 8.w),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]);
}

class _Picker extends StatelessWidget {
  const _Picker(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap,
      this.color = AppColors.operationalPurple});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13.r),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .05),
            border: Border.all(color: color.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 6.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ])),
            Icon(Icons.expand_more_rounded, color: color, size: 19.sp),
          ]),
        ),
      );
}

class _Amount extends StatelessWidget {
  const _Amount(
      {required this.label, required this.value, required this.color});
  final String label;
  final dynamic value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 9.sp)),
        SizedBox(height: 2.h),
        FittedBox(
            child: Text(PayrollController.money(value),
                style: TextStyle(color: color, fontWeight: FontWeight.w900))),
      ]);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color =
        status == 'paid' ? AppColors.customGreen1 : Colors.orange.shade800;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20.r)),
      child: Text(_salaryStatus(status),
          style: TextStyle(
              color: color, fontSize: 9.sp, fontWeight: FontWeight.w900)),
    );
  }
}

class _PayrollSkeleton extends StatelessWidget {
  const _PayrollSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: EdgeInsets.all(13.r),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (_, index) => SkeletonBlock(
          width: double.infinity,
          height: index == 1 ? 250.h : 125.h,
          radius: 16,
        ),
      );
}

String _salaryStatus(String status) {
  if (status == 'paid') return 'مدفوع بالكامل';
  if (status == 'partially_paid') return 'مدفوع جزئياً';
  if (status == 'cancelled') return 'ملغي';
  return 'محسوب';
}
