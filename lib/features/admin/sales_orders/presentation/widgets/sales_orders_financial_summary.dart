import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../../core/utils/app_colors.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../controllers/sales_orders_controller.dart';

class SalesOrdersFinancialSummary extends GetView<SalesOrdersController> {
  const SalesOrdersFinancialSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const _FinancialSummaryPanel();
}

class _FinancialSummaryPanel extends StatefulWidget {
  const _FinancialSummaryPanel();

  @override
  State<_FinancialSummaryPanel> createState() => _FinancialSummaryState();
}

class _FinancialSummaryState extends State<_FinancialSummaryPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _motion.forward();
    } else {
      _motion.reverse();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final orders = Get.find<SalesOrdersController>();
        final sales = Get.isRegistered<SalesController>()
            ? Get.find<SalesController>()
            : null;
        final payload = sales?.salesOrdersDailySessionPayload.value;
        final session = payload?.session;
        final open = session != null && session.status != 'closed';
        final rows = payload?.salesOrdersCurrencies;
        final cash = rows?.firstWhereOrNull((row) => row.currency == 'شيكل') ??
            rows?.firstWhereOrNull((_) => true);
        final currency = cash?.currency ?? 'شيكل';
        final drawerAvailable = open && cash != null;
        final drawerDescription = payload == null
            ? 'تعذر عرض بيانات الصندوق. اسحب الشاشة للتحديث.'
            : !open
                ? 'صندوق الطلبيات مغلق حاليًا.'
                : 'صاحب الجلسة: ${session!.employeeName ?? '—'}، بتاريخ ${session.businessDate}.'
                    '${session.status == 'closing_requested' ? ' بانتظار اعتماد الإغلاق.' : ''}';
        final summary = orders.financialSummary;
        final metrics = [
          _BalanceTile(
            label: 'رصيد الصندوق',
            amount: drawerAvailable ? cash!.boxBalance : null,
            currency: currency,
            color: const Color(0xFF2563EB),
            description:
                'الرصيد المسجل في صندوق الطلبيات بعد الحركات المالية. $drawerDescription',
          ),
          _BalanceTile(
            label: 'تحصيلات الجلسة',
            amount: drawerAvailable ? cash!.salesCollected : null,
            currency: currency,
            color: const Color(0xFF059669),
            description:
                'صافي المقبوض من الطلبيات خلال الجلسة، بعد خصم أجور الشركات وعكس الدفعات. $drawerDescription',
          ),
          _BalanceTile(
            label: 'شركات التوصيل',
            amount: summary['carrier_receivable'],
            currency: 'شيكل',
            color: const Color(0xFFD97706),
            description: summary.containsKey('carrier_receivable')
                ? 'المبالغ المتبقية بذمة شركات التوصيل، قبل خصم أجرتها. حسب البحث والمصدر عبر جميع حالات الطلبيات.'
                : 'تعذر جلب المستحق لدى شركات التوصيل. اسحب الشاشة للتحديث.',
          ),
          _BalanceTile(
            label: 'ديون الزبائن',
            amount: summary['customer_debt'],
            currency: 'شيكل',
            color: const Color(0xFF7C3AED),
            description: summary.containsKey('customer_debt')
                ? 'المبالغ المتبقية على الزبائن للتحصيل. حسب البحث والمصدر عبر جميع حالات الطلبيات.'
                : 'تعذر جلب ديون الزبائن. اسحب الشاشة للتحديث.',
          ),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
          child: LayoutBuilder(builder: (context, constraints) {
            const buttonSize = 48.0;
            const gap = 6.0;
            const tileHeight = 86.0;
            final stripWidth =
                math.max(0.0, constraints.maxWidth - buttonSize - gap);
            final rtl = Directionality.of(context) == TextDirection.rtl;
            return AnimatedBuilder(
              animation: _motion,
              builder: (context, _) {
                final progress = Curves.easeInOutCubic.transform(_motion.value);
                return SizedBox(
                  height: buttonSize + (tileHeight - buttonSize) * progress,
                  child: Row(children: [
                    ClipRect(
                        child: SizedBox(
                      width: stripWidth * progress,
                      height: tileHeight,
                      child: OverflowBox(
                        alignment: AlignmentDirectional.centerStart,
                        minWidth: stripWidth,
                        maxWidth: stripWidth,
                        minHeight: tileHeight,
                        maxHeight: tileHeight,
                        child: ExcludeSemantics(
                          excluding: progress < 1,
                          child: IgnorePointer(
                            ignoring: progress < 1,
                            child: Row(children: [
                              for (var i = 0; i < metrics.length; i++) ...[
                                if (i > 0) const SizedBox(width: 5),
                                Expanded(child: metrics[i]),
                              ],
                            ]),
                          ),
                        ),
                      ),
                    )),
                    SizedBox(width: gap * progress),
                    Tooltip(
                      message: _expanded ? 'طي الأرصدة' : 'عرض الأرصدة',
                      child: Semantics(
                        button: true,
                        expanded: _expanded,
                        label: _expanded ? 'طي الأرصدة' : 'عرض الأرصدة',
                        child: Transform.rotate(
                          angle: (rtl ? -1 : 1) * progress * math.pi * 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: .18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: IconButton(
                              onPressed: _toggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                  width: buttonSize, height: buttonSize),
                              icon: const Icon(Icons.payments_outlined,
                                  color: Colors.white, size: 23),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
              },
            );
          }),
        );
      });
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile(
      {required this.label,
      required this.amount,
      required this.currency,
      required this.color,
      required this.description});

  final String label;
  final double? amount;
  final String currency;
  final Color color;
  final String description;
  static final _money = NumberFormat('#,##0.00', 'en');

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = amount != null && amount! < 0
        ? const Color(0xFFDC2626)
        : dark
            ? Color.lerp(color, Colors.white, .4)!
            : color;
    return Tooltip(
      message: description,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      showDuration: const Duration(seconds: 6),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      textStyle:
          const TextStyle(fontSize: 12, color: Colors.white, height: 1.5),
      decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(10)),
      child: Container(
        height: 86,
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? .18 : .09),
          border: Border.all(color: color.withValues(alpha: .24)),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Icon(Icons.info_outline_rounded,
                  size: 13, color: foreground)),
          const SizedBox(height: 2),
          SizedBox(
              height: 25,
              child: Center(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: foreground)))),
          const Spacer(),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(amount == null ? '—' : _money.format(amount),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: foreground))),
          Center(
              child: Text(currency,
                  style:
                      TextStyle(fontSize: 9, height: 1.2, color: foreground))),
        ]),
      ),
    );
  }
}
