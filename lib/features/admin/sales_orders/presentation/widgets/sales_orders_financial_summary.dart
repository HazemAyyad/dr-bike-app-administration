import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../sales/presentation/controllers/sales_controller.dart';
import '../controllers/sales_orders_controller.dart';

class SalesOrdersFinancialSummary extends GetView<SalesOrdersController> {
  const SalesOrdersFinancialSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Obx(() {
        final sales = Get.isRegistered<SalesController>()
            ? Get.find<SalesController>()
            : null;
        final payload = sales?.salesOrdersDailySessionPayload.value;
        final session = payload?.session;
        final hasDrawer = session != null && session.status != 'closed';
        final rows = hasDrawer ? payload!.salesOrdersCurrencies : const [];
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      hasDrawer
                          ? 'صندوق الطلبيات — ${session!.employeeName ?? ''} — ${session.businessDate}'
                          : payload == null
                              ? 'بيانات صندوق الطلبيات غير متاحة؛ حدّث الشاشة'
                              : 'صندوق الطلبيات مغلق',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (hasDrawer && session!.status == 'closing_requested')
                    const Text('بانتظار اعتماد الإغلاق'),
                  for (final row in rows)
                    Wrap(spacing: 18, runSpacing: 8, children: [
                      _Metric('رصيد الصندوق', row.boxBalance, row.currency),
                      _Metric('صافي تحصيلات الجلسة', row.salesCollected,
                          row.currency),
                    ]),
                  if (controller.financialSummary.isNotEmpty) ...[
                    const Divider(),
                    const Text('المستحق حسب البحث والمصدر — جميع الحالات',
                        style: TextStyle(fontSize: 11)),
                    Wrap(spacing: 18, runSpacing: 8, children: [
                      _Metric(
                          'عند شركات التوصيل',
                          controller.financialSummary['carrier_receivable'] ??
                              0,
                          'شيكل'),
                      _Metric(
                          'ديون الزبائن',
                          controller.financialSummary['customer_debt'] ?? 0,
                          'شيكل'),
                    ]),
                  ],
                ]),
          ),
        );
      });
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.amount, this.currency);
  final String label;
  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text('${amount.toStringAsFixed(2)} $currency',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amount < 0 ? Colors.red : null)),
        ]),
      );
}
