import 'package:flutter/material.dart';

import '../../../../../core/utils/localized_number.dart';
import '../../../../../core/helpers/localized_number_input_formatter.dart';
import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';
import 'sales_order_notice.dart';

class SalesOrderSettlementSheet extends StatefulWidget {
  const SalesOrderSettlementSheet._(
      {required this.controller, required this.order});

  final SalesOrdersController controller;
  final SalesOrderDetailModel order;
  static bool _isOpen = false;

  static Future<void> show(BuildContext context,
      SalesOrdersController controller, int orderId) async {
    if (controller.isSubmitting.value || _isOpen) return;
    _isOpen = true;
    try {
      await _show(context, controller, orderId);
    } finally {
      _isOpen = false;
    }
  }

  static Future<void> _show(BuildContext context,
      SalesOrdersController controller, int orderId) async {
    final result = await controller.repository.getOrder(orderId);
    if (!context.mounted) return;
    await result.fold<Future<void>>(
      (failure) async => SalesOrderNotice.error(failure.errMessage),
      (order) async {
        if (order.status != 'delivered') {
          SalesOrderNotice.error('تغيّرت حالة الطلبية؛ حدّث القائمة وراجعها.');
          await controller.loadOrders();
          return;
        }
        if (order.canArchive) {
          final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                    title: const Text('أرشفة الطلبية المسددة؟',
                        style: TextStyle(
                            color: SalesOrdersController.textPrimary)),
                    content: const Text(
                        'لا يوجد رصيد مستحق على الزبون أو شركة التوصيل.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('رجوع')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('أرشفة')),
                    ],
                  ));
          if (confirmed == true) {
            await controller.runAction(
                () => controller.repository.archive(order.id),
                keepCurrentTab: true);
          }
          return;
        }
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) =>
              SalesOrderSettlementSheet._(controller: controller, order: order),
        );
      },
    );
  }

  @override
  State<SalesOrderSettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends State<SalesOrderSettlementSheet> {
  late final TextEditingController amount;
  late final TextEditingController fee;
  late bool archive;
  bool submitting = false;
  String? requestKey;
  String? requestSignature;

  bool get fromCarrier => widget.order.carrierReceivableBalance > 0;
  double get balance => fromCarrier
      ? widget.order.carrierReceivableBalance
      : widget.order.customerDebtBalance;
  double? get entered => tryParseLocalizedAmount(amount.text);
  double? get enteredFee => fromCarrier ? tryParseLocalizedAmount(fee.text) : 0;
  bool get clearsAll =>
      entered != null &&
      (entered! - balance).abs() < .001 &&
      (fromCarrier
              ? widget.order.customerDebtBalance
              : widget.order.carrierReceivableBalance) <=
          0;

  @override
  void initState() {
    super.initState();
    amount = TextEditingController(text: balance.toStringAsFixed(2));
    fee = TextEditingController(
        text: widget.order.suggestedCarrierFee.toStringAsFixed(2));
    archive = clearsAll;
  }

  @override
  void dispose() {
    amount.dispose();
    fee.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (submitting || widget.controller.isSubmitting.value) return;
    final gross = entered;
    final carrierFee = enteredFee;
    if (gross == null ||
        gross <= 0 ||
        gross > balance + .001 ||
        carrierFee == null ||
        carrierFee < 0 ||
        carrierFee > gross + .001) {
      SalesOrderNotice.error(
          'راجع مبلغ التسوية وأجرة الشركة؛ يجب ألا يتجاوزا الرصيد المستحق.');
      return;
    }
    final shouldArchive = archive && clearsAll;
    final signature = '$gross:$carrierFee:$shouldArchive';
    if (requestSignature != signature) {
      requestSignature = signature;
      requestKey =
          'settlement-${widget.order.id}-${DateTime.now().microsecondsSinceEpoch}';
    }
    setState(() => submitting = true);
    try {
      final succeeded = await widget.controller.submitSettlement(widget.order,
          amount: gross,
          carrierFee: carrierFee,
          archiveAfterSettlement: shouldArchive,
          idempotencyKey: requestKey!);
      if (succeeded && mounted) {
        Navigator.of(context).pop();
        SalesOrderNotice.successDeferred(
            shouldArchive ? 'تمت التسوية والأرشفة' : 'تمت التسوية');
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gross = entered ?? 0;
    final carrierFee = enteredFee ?? 0;
    return PopScope(
      canPop: !submitting,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  fromCarrier
                      ? 'تحصيل وتسوية شركة التوصيل'
                      : 'تحصيل دين الزبون',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: SalesOrdersController.textPrimary,
                      )),
              const SizedBox(height: 6),
              Text(
                  '${widget.order.customerName ?? ''} — ${widget.order.serialNumber ?? '#${widget.order.id}'}'),
              const SizedBox(height: 12),
              Text('الرصيد المستحق: ${balance.toStringAsFixed(2)} ₪'),
              const SizedBox(height: 12),
              TextField(
                  controller: amount,
                  enabled: !submitting,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    LocalizedNumberInputFormatter(decimal: true)
                  ],
                  decoration: const InputDecoration(
                      labelText: 'إجمالي مبلغ التسوية',
                      suffixText: '₪',
                      border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {
                        if (!clearsAll) archive = false;
                      })),
              if (fromCarrier) ...[
                const SizedBox(height: 12),
                TextField(
                    controller: fee,
                    enabled: !submitting,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [
                      LocalizedNumberInputFormatter(decimal: true)
                    ],
                    decoration: const InputDecoration(
                        labelText: 'أجرة الشركة المخصومة',
                        suffixText: '₪',
                        border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 8),
                Text(
                    widget.order.usesCustomerFeeEstimate
                        ? 'الأجرة مقترحة من التوصيل المحسوب على الزبون؛ راجعها مع كشف الشركة قبل التأكيد.'
                        : 'راجع الأجرة مع كشف الشركة. تُسجّل كمصروف ولا تدخل الصندوق.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              'إجمالي إغلاق الذمة: ${gross.toStringAsFixed(2)} ₪'),
                          if (fromCarrier)
                            Text(
                                'أجرة الشركة: ${carrierFee.toStringAsFixed(2)} ₪'),
                          const SizedBox(height: 6),
                          Text(
                              'صافي الداخل للصندوق: ${(gross - carrierFee).toStringAsFixed(2)} ₪',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ))),
              const Text(
                  'سيتم الإيداع في صندوق الطلبيات الخاص بالجلسة المفتوحة.'),
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: archive && clearsAll,
                  title: const Text('أرشفة الطلبية بعد التسوية'),
                  subtitle: clearsAll
                      ? null
                      : const Text('تتاح الأرشفة بعد سداد جميع المستحقات.'),
                  onChanged: submitting || !clearsAll
                      ? null
                      : (value) => setState(() => archive = value ?? false)),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: submitting ? null : submit,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(submitting
                          ? 'جارٍ الحفظ…'
                          : archive && clearsAll
                              ? 'تأكيد التسوية والأرشفة'
                              : 'تأكيد التسوية'))),
            ],
          ),
        ),
      ),
    );
  }
}
