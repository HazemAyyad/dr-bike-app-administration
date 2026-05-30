import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';
import 'ledger_format.dart';
import 'share_sheet.dart';

class PersonReportScreen extends StatelessWidget {
  const PersonReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: LedgerColors.primaryBlue,
          elevation: 0,
          centerTitle: true,
          title: Text(
            controller.selectedPerson?.name ?? '',
            style: TextStyle(
              color: LedgerColors.primaryBlue,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Obx(() {
          final detail = controller.personDetail.value;
          if (controller.personLoading.value || detail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currency = controller.selectedCurrency.value;
          final stats = controller.personCurrencyBalance ??
              detail.balanceFor(controller.selectedCurrency.value);
          final transactions = detail.transactions;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 16.h),
                  children: [
                    _ReportHeader(
                      controller: controller,
                      stats: stats,
                      currency: currency,
                    ),
                    SizedBox(height: 22.h),
                    _TransactionsTitle(count: transactions.length),
                    SizedBox(height: 12.h),
                    if (transactions.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.h),
                        child: Center(child: Text('ledgerNoTransactions'.tr)),
                      )
                    else
                      ...transactions.map(
                        (tx) => _ReportTransactionRow(transaction: tx),
                      ),
                  ],
                ),
              ),
              _ReportBottomActions(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({
    required this.controller,
    required this.stats,
    required this.currency,
  });

  final DebtLedgerController controller;
  final LedgerCurrencyBalance stats;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final balanceColor = controller.balanceColor(stats.balance);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PeriodChip(
                label: _periodLabel(controller),
                onTap: () => Get.bottomSheet(
                  const ReportPeriodSheet(),
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: LedgerColors.primaryBlue,
                side: BorderSide.none,
                backgroundColor: LedgerColors.primaryBlue.withValues(
                  alpha: .08,
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
              onPressed: () => Get.bottomSheet(
                const ReportPeriodSheet(),
                isScrollControlled: true,
                backgroundColor: Colors.white,
              ),
              child: Text(
                'ledgerChangePeriod'.tr,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        Row(
          children: [
            Expanded(
              child: _ReportStat(
                label: 'took'.tr,
                amount: stats.totalTaken,
                currency: currency,
                color: LedgerColors.takenGreen,
              ),
            ),
            Container(width: 1, height: 52.h, color: Colors.grey.shade200),
            Expanded(
              child: _ReportStat(
                label: 'gave'.tr,
                amount: stats.totalGiven,
                currency: currency,
                color: LedgerColors.givenRed,
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        Divider(color: Colors.grey.shade200),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ledgerBalance'.tr,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              LedgerFormat.money(
                stats.balance.abs(),
                currency: currency,
                fractionDigits: 1,
              ),
              style: TextStyle(
                color: balanceColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _periodLabel(DebtLedgerController controller) {
    switch (controller.selectedPeriod.value) {
      case 'today':
        return 'ledgerPeriodToday'.tr;
      case 'yesterday':
        return 'ledgerPeriodYesterday'.tr;
      case 'current_week':
        return 'ledgerPeriodCurrentWeek'.tr;
      case 'last_week':
        return 'ledgerPeriodLastWeek'.tr;
      case 'current_month':
        return 'ledgerPeriodCurrentMonth'.tr;
      case 'last_month':
        return 'ledgerPeriodLastMonth'.tr;
      case 'custom':
        return 'ledgerPeriodCustom'.tr;
      case 'all':
      default:
        return 'ledgerPeriodAll'.tr;
    }
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: LedgerColors.primaryBlue,
              size: 30.sp,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          LedgerFormat.money(amount, currency: currency, fractionDigits: 1),
          style: TextStyle(
            color: color,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TransactionsTitle extends StatelessWidget {
  const _TransactionsTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '${'ledgerTransactions'.tr} ($count ${'ledgerActive'.tr})',
        style: TextStyle(
          color: LedgerColors.primaryBlue,
          fontSize: 17.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReportTransactionRow extends StatelessWidget {
  const _ReportTransactionRow({required this.transaction});

  final LedgerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();
    final isTaken = transaction.isTaken;
    final color = isTaken ? LedgerColors.takenGreen : LedgerColors.givenRed;

    return InkWell(
      onTap: () => controller.openTransactionDetail(transaction),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: LedgerColors.primaryBlue.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTaken ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.black87,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.formatTransactionTime(transaction),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (transaction.displayDescription.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      transaction.displayDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  LedgerFormat.money(
                    transaction.amount,
                    currency: transaction.currency,
                    fractionDigits: 1,
                  ),
                  style: TextStyle(
                    color: color,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  transaction.typeLabel,
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12.sp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBottomActions extends StatelessWidget {
  const _ReportBottomActions({required this.controller});

  final DebtLedgerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LedgerColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () async {
                  final file = await controller.downloadPersonReport();
                  if (file != null) controller.openDownloadedReport(file);
                },
                child: Text(
                  'ledgerPdfReport'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF5FD),
                  foregroundColor: LedgerColors.primaryBlue,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () => Get.bottomSheet(
                  const ShareSheet(),
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'ledgerShareReport'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportPeriodSheet extends StatefulWidget {
  const ReportPeriodSheet({Key? key}) : super(key: key);

  @override
  State<ReportPeriodSheet> createState() => _ReportPeriodSheetState();
}

class _ReportPeriodSheetState extends State<ReportPeriodSheet> {
  late String period;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<DebtLedgerController>();
    period = controller.selectedPeriod.value;
    startDate = controller.customStartDate.value;
    endDate = controller.customEndDate.value;
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      _PeriodOption('all', 'ledgerPeriodAll'.tr, Icons.calendar_month_outlined),
      _PeriodOption('today', 'ledgerPeriodToday'.tr, Icons.today_outlined),
      _PeriodOption(
        'yesterday',
        'ledgerPeriodYesterday'.tr,
        Icons.event_repeat_outlined,
      ),
      _PeriodOption(
        'current_week',
        'ledgerPeriodCurrentWeek'.tr,
        Icons.calendar_view_week_outlined,
      ),
      _PeriodOption(
        'last_week',
        'ledgerPeriodLastWeek'.tr,
        Icons.calendar_view_week_outlined,
      ),
      _PeriodOption(
        'current_month',
        'ledgerPeriodCurrentMonth'.tr,
        Icons.calendar_month_outlined,
      ),
      _PeriodOption(
        'last_month',
        'ledgerPeriodLastMonth'.tr,
        Icons.calendar_month_outlined,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          padding: EdgeInsets.fromLTRB(22.w, 16.h, 22.w, 22.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    color: LedgerColors.primaryBlue,
                  ),
                  Expanded(
                    child: Text(
                      'ledgerReportPeriod'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LedgerColors.primaryBlue,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
              SizedBox(height: 16.h),
              _CustomDateSection(
                selected: period == 'custom',
                startDate: startDate,
                endDate: endDate,
                onSelect: () => setState(() => period = 'custom'),
                onPickStart: () => _pickDate(start: true),
                onPickEnd: () => _pickDate(start: false),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.grey.shade100,
                    height: 1,
                  ),
                  itemBuilder: (_, index) {
                    final option = options[index];
                    final selected = period == option.key;
                    return ListTile(
                      onTap: () => setState(() => period = option.key),
                      leading: Icon(
                        option.icon,
                        color: LedgerColors.primaryBlue,
                      ),
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check,
                              color: LedgerColors.primaryBlue,
                            )
                          : null,
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LedgerColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: _apply,
                child: Text(
                  'ledgerApply'.tr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? startDate : endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() {
      period = 'custom';
      if (start) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  Future<void> _apply() async {
    final controller = Get.find<DebtLedgerController>();
    if (period == 'custom') {
      await controller.setCustomPeriod(startDate, endDate);
    } else {
      await controller.applyPeriod(period);
    }
    await controller.loadPersonDetail();
    Get.back();
  }
}

class _PeriodOption {
  const _PeriodOption(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class _CustomDateSection extends StatelessWidget {
  const _CustomDateSection({
    required this.selected,
    required this.startDate,
    required this.endDate,
    required this.onSelect,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final bool selected;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onSelect;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.date_range_outlined,
                  color: LedgerColors.primaryBlue,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'ledgerPeriodCustom'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: LedgerColors.primaryBlue),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: 'ledgerStartDate'.tr,
                    date: startDate,
                    onTap: onPickStart,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DateBox(
                    label: 'ledgerEndDate'.tr,
                    date: endDate,
                    onTap: onPickEnd,
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

class _DateBox extends StatelessWidget {
  const _DateBox(
      {required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          date == null ? label : DateFormat('yyyy-MM-dd').format(date!),
          style: TextStyle(
            color: date == null ? Colors.grey.shade400 : Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
