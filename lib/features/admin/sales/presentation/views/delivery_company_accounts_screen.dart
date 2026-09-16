import 'dart:math';

import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sales_controller.dart';
import '../../../../../core/helpers/app_success_notice.dart';

import '../../../../../core/helpers/app_failure_notice.dart';

const _navy = Color(0xFF12304A);
const _surface = Color(0xFFF4F7F9);
const _border = Color(0xFFDDE5EA);
const _warning = Color(0xFFB45309);

class DeliveryCompanyAccountsScreen extends StatefulWidget {
  const DeliveryCompanyAccountsScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryCompanyAccountsScreen> createState() => _AccountsState();
}

class _AccountsState extends State<DeliveryCompanyAccountsScreen> {
  final DioConsumer api = Get.find<DioConsumer>();
  List<Map<String, dynamic>> accounts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final response = await api.get(EndPoints.deliveryCompanyAccounts);
      final raw = response.data is Map ? response.data['accounts'] : null;
      if (mounted) {
        setState(() => accounts = raw is List
            ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : []);
      }
    } catch (e) {
      AppFailureNotice.show(
        title: 'تعذر تحميل الحسابات',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(title: const Text('حسابات شركات التوصيل')),
        body: loading && accounts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: load,
                child: accounts.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 180),
                        Icon(Icons.account_balance_wallet_outlined, size: 64),
                        Center(child: Text('لا توجد حسابات شركات توصيل بعد')),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                        itemCount: accounts.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            final total = accounts.fold<double>(
                              0,
                              (sum, row) =>
                                  sum + number(row['outstanding_balance']),
                            );
                            final orderCount = accounts.fold<int>(
                              0,
                              (sum, row) =>
                                  sum +
                                  (row['outstanding_orders_count'] as num? ?? 0)
                                      .toInt(),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AccountsOverview(
                                companies: accounts.length,
                                orders: orderCount,
                                balance: total,
                              ),
                            );
                          }
                          final accountIndex = i - 1;
                          final a = accounts[accountIndex];
                          final balance = number(a['outstanding_balance']);
                          final count =
                              (a['outstanding_orders_count'] as num? ?? 0)
                                  .toInt();
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: _border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (balance > 0 ? _warning : Colors.green)
                                      .withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color: balance > 0 ? _warning : Colors.green,
                                ),
                              ),
                              title: Text(
                                '${a['delivery_company_name'] ?? 'شركة توصيل'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                              subtitle: Text(
                                count == 0
                                    ? 'الحساب مسدد بالكامل'
                                    : '$count طلبيات بانتظار التسوية',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${balance.toStringAsFixed(2)} ₪',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color:
                                          balance > 0 ? _warning : Colors.green,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left_rounded,
                                      size: 18),
                                ],
                              ),
                              onTap: () async {
                                await Get.to(() =>
                                    DeliveryCompanyAccountDetailScreen(
                                        account: a));
                                await load();
                              },
                            ),
                          );
                        },
                      ),
              ),
      );
}

class _AccountsOverview extends StatelessWidget {
  const _AccountsOverview({
    required this.companies,
    required this.orders,
    required this.balance,
  });
  final int companies;
  final int orders;
  final double balance;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('المبالغ المنتظرة من شركات التوصيل',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('${balance.toStringAsFixed(2)} ₪',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _overviewValue('الشركات', '$companies')),
              Expanded(child: _overviewValue('طلبيات معلقة', '$orders')),
            ]),
          ],
        ),
      );

  Widget _overviewValue(String label, String value) => Container(
        margin: const EdgeInsetsDirectional.only(end: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$label  $value',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      );
}

class DeliveryCompanyAccountDetailScreen extends StatefulWidget {
  const DeliveryCompanyAccountDetailScreen({
    required this.account,
    Key? key,
  }) : super(key: key);
  final Map<String, dynamic> account;

  @override
  State<DeliveryCompanyAccountDetailScreen> createState() =>
      _AccountDetailState();
}

class _AccountDetailState extends State<DeliveryCompanyAccountDetailScreen> {
  final DioConsumer api = Get.find<DioConsumer>();
  Map<String, dynamic> account = {};
  final Set<int> selected = {};
  bool loading = true;
  int section = 0;

  int get companyId => (widget.account['delivery_company_id'] as num).toInt();
  String get companyName => '${widget.account['delivery_company_name'] ?? ''}';
  List<Map<String, dynamic>> get orders {
    final raw = account['orders'];
    return raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  }

  List<Map<String, dynamic>> get outstanding =>
      orders.where((o) => number(o['carrier_receivable_balance']) > 0).toList();
  double get selectedTotal => outstanding
      .where((o) => selected.contains((o['id'] as num).toInt()))
      .fold(0, (sum, o) => sum + number(o['carrier_receivable_balance']));

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final response = await api.get(EndPoints.deliveryCompanyAccount,
          queryParameters: {
            'delivery_company_id': companyId,
            'delivery_company_name': companyName
          });
      final raw = response.data is Map ? response.data['account'] : null;
      if (raw is Map && mounted) {
        setState(() => account = Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      AppFailureNotice.show(
        title: 'تعذر تحميل الحساب',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawBatches = account['batches'];
    final batches =
        rawBatches is List ? rawBatches.whereType<Map>().toList() : <Map>[];
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(title: Text(companyName)),
      bottomNavigationBar: selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: settle,
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                    'تسوية ${selected.length} طلبيات — ${selectedTotal.toStringAsFixed(2)} ₪'),
              ),
            )),
      body: loading && account.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                  elevation: 0,
                  color: const Color(0xFFEAF3FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFC6DAE8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                              child: Text('إجمالي المبلغ المطلوب من الشركة',
                                  style: TextStyle(
                                      color: Color(0xFF526475),
                                      fontWeight: FontWeight.w700))),
                          Text(
                              '${number(account['outstanding_balance']).toStringAsFixed(2)} ₪',
                              style: const TextStyle(
                                  color: _navy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                        ]),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _sectionChip(0, 'بانتظار التسوية', outstanding.length),
                    _sectionChip(1, 'كل الطلبيات', orders.length),
                    _sectionChip(2, 'سجل التسويات', batches.length),
                  ]),
                ),
                if (section == 0) ...[
                  Row(children: [
                    const Expanded(
                        child: Text('الطلبيات غير المسددة',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    TextButton(
                      onPressed: outstanding.isEmpty
                          ? null
                          : () => setState(() {
                                if (selected.length == outstanding.length) {
                                  selected.clear();
                                } else {
                                  selected
                                    ..clear()
                                    ..addAll(outstanding
                                        .map((o) => (o['id'] as num).toInt()));
                                }
                              }),
                      child: Text(selected.length == outstanding.length &&
                              outstanding.isNotEmpty
                          ? 'إلغاء تحديد الكل'
                          : 'تحديد الكل'),
                    ),
                  ]),
                  if (outstanding.isEmpty)
                    const Card(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('الحساب مسدد بالكامل')))),
                  for (final o in outstanding)
                    _orderAccountCard(o, selectable: true),
                ],
                if (section == 1) ...[
                  const SizedBox(height: 20),
                  const Text('سجل طلبيات الشركة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final o in orders) _orderAccountCard(o),
                ],
                if (section == 2) ...[
                  const SizedBox(height: 20),
                  const Text('سجل التسويات الجماعية',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (batches.isEmpty)
                    const Card(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child:
                                Center(child: Text('لا توجد تسويات مسجلة')))),
                  for (final b in batches) batchCard(b),
                ],
                const SizedBox(height: 90),
              ]),
            ),
    );
  }

  Widget _orderAccountCard(
    Map<String, dynamic> order, {
    bool selectable = false,
  }) {
    final id = (order['id'] as num).toInt();
    final isSelected = selected.contains(id);
    final balance = number(order['carrier_receivable_balance']);
    final isSettled = balance <= 0;
    final accent =
        isSettled ? const Color(0xFF15803D) : const Color(0xFFB42318);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? const Color(0xFFF2F7FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? const Color(0xFF8EB8DA) : _border,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selectable ? () => _toggleOrderSelection(id) : null,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (selectable) ...[
                      Checkbox(
                        value: isSelected,
                        activeColor: _navy,
                        onChanged: (_) => _toggleOrderSelection(id),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['serial_number'] ?? '#$id'}',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order['customer_name'] ?? 'زبون'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        isSettled
                            ? 'مسددة'
                            : 'متبقي ${balance.toStringAsFixed(2)} ₪',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      date(order['created_at']),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _orderMetric(
                          'إجمالي الزبون',
                          number(order['total']),
                        ),
                        const VerticalDivider(width: 1),
                        _orderMetric(
                          'توصيل الزبون',
                          number(order['customer_delivery_fee']),
                        ),
                        const VerticalDivider(width: 1),
                        _orderMetric(
                          'أجرة الجهة',
                          number(order['carrier_delivery_cost']),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!selectable) ...[
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _settlementValue(
                          'أُغلق من الذمة',
                          number(order['settled_amount']),
                        ),
                      ),
                      Expanded(
                        child: _settlementValue(
                          'دخل الصندوق',
                          number(order['settled_cash_amount']),
                        ),
                      ),
                      Expanded(
                        child: _settlementValue(
                          'أجرة مسجلة',
                          number(order['settled_carrier_fee']),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderMetric(String label, double amount) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${amount.toStringAsFixed(2)} ₪',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _settlementValue(String label, double amount) => Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${amount.toStringAsFixed(2)} ₪',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );

  void _toggleOrderSelection(int id) {
    setState(() {
      selected.contains(id) ? selected.remove(id) : selected.add(id);
    });
  }

  Widget _sectionChip(int value, String label, int count) {
    final active = section == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 7, top: 6),
      child: ChoiceChip(
        selected: active,
        showCheckmark: false,
        selectedColor: _navy,
        side: const BorderSide(color: _border),
        labelStyle: TextStyle(
            color: active ? Colors.white : _navy, fontWeight: FontWeight.w700),
        label: Text('$label ($count)'),
        onSelected: (_) => setState(() => section = value),
      ),
    );
  }

  Widget batchCard(Map b) {
    final raw = b['allocations'];
    final allocations = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: const BorderSide(color: _border)),
        child: ExpansionTile(
          title: Text('إغلاق ذمة ${number(b['amount']).toStringAsFixed(2)} ₪'),
          subtitle: Text(
              '${date(b['created_at'])} — ${b['created_by'] ?? '-'}\nصافي الصندوق: ${number(b['cash_amount']).toStringAsFixed(2)} ₪ • أجرة الشركة: ${number(b['carrier_fee']).toStringAsFixed(2)} ₪'),
          children: [
            for (final a in allocations)
              ListTile(
                  dense: true,
                  title: Text('${a['serial_number'] ?? '#${a['order_id']}'}'),
                  trailing: Text(number(a['amount']).toStringAsFixed(2))),
            if ('${b['notes'] ?? ''}'.trim().isNotEmpty)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('ملاحظات: ${b['notes']}'))),
          ],
        ));
  }

  Future<void> settle() async {
    final chosen = outstanding
        .where((o) => selected.contains((o['id'] as num).toInt()))
        .toList();
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => BatchSettlementDialog(
          companyId: companyId,
          companyName: companyName,
          orders: chosen,
          api: api),
    );
    if (done == true) {
      selected.clear();
      await load();
    }
  }
}

class BatchSettlementDialog extends StatefulWidget {
  const BatchSettlementDialog({
    required this.companyId,
    required this.companyName,
    required this.orders,
    required this.api,
    Key? key,
  }) : super(key: key);
  final int companyId;
  final String companyName;
  final List<Map<String, dynamic>> orders;
  final DioConsumer api;

  @override
  State<BatchSettlementDialog> createState() => _BatchSettlementState();
}

class _BatchSettlementState extends State<BatchSettlementDialog> {
  late final TextEditingController cashReceived;
  late final TextEditingController carrierFee;
  final notes = TextEditingController();
  final Map<int, TextEditingController> allocations = {};
  bool saving = false;
  double get maximum => widget.orders
      .fold(0, (sum, o) => sum + number(o['carrier_receivable_balance']));

  @override
  void initState() {
    super.initState();
    final suggestedFee = widget.orders.fold<double>(0, (sum, order) {
      final expected = number(order['carrier_delivery_cost']);
      final recorded = number(order['settled_carrier_fee']);
      final remainingCost = max(0, expected - recorded);
      return sum +
          min(number(order['carrier_receivable_balance']), remainingCost);
    });
    carrierFee = TextEditingController(text: suggestedFee.toStringAsFixed(2));
    cashReceived = TextEditingController(
      text: max(0, maximum - suggestedFee).toStringAsFixed(2),
    );
    for (final o in widget.orders) {
      allocations[(o['id'] as num).toInt()] = TextEditingController(
          text: number(o['carrier_receivable_balance']).toStringAsFixed(2));
    }
  }

  @override
  void dispose() {
    cashReceived.dispose();
    carrierFee.dispose();
    notes.dispose();
    for (final controller in allocations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void distribute() {
    var remaining = settlementAmount;
    if (remaining <= 0 || remaining > maximum + .001) {
      Get.snackbar(
        'تنبيه',
        'مجموع النقد المستلم وأجرة الشركة يجب ألا يتجاوز الرصيد',
      );
      return;
    }
    for (final o in widget.orders) {
      final id = (o['id'] as num).toInt();
      final amount =
          min(number(o['carrier_receivable_balance']), max(0, remaining));
      allocations[id]!.text = amount.toStringAsFixed(2);
      remaining -= amount;
    }
    setState(() {});
  }

  void _redistributeAfterAmountChange() {
    var remaining = settlementAmount;
    if (remaining < 0 || remaining > maximum + .001) {
      setState(() {});
      return;
    }
    for (final order in widget.orders) {
      final id = (order['id'] as num).toInt();
      final amount = min(
        number(order['carrier_receivable_balance']),
        max(0, remaining),
      );
      allocations[id]!.text = amount.toStringAsFixed(2);
      remaining -= amount;
    }
    setState(() {});
  }

  Future<void> submit() async {
    final receivedCash = parsedCashReceived;
    final fee = double.tryParse(carrierFee.text.trim()) ?? 0;
    final settledAmount = receivedCash + fee;
    if (receivedCash < 0 ||
        settledAmount <= 0 ||
        settledAmount > maximum + .001) {
      Get.snackbar(
        'تنبيه',
        'النقد المستلم مع أجرة الشركة يجب ألا يتجاوز الرصيد المحدد',
      );
      return;
    }
    if (fee < 0) {
      Get.snackbar('تنبيه', 'أجرة الشركة لا يمكن أن تكون سالبة');
      return;
    }
    final rows = <Map<String, dynamic>>[];
    var sum = 0.0;
    for (final o in widget.orders) {
      final id = (o['id'] as num).toInt();
      final amount = double.tryParse(allocations[id]!.text.trim()) ?? -1;
      if (amount < 0 ||
          amount > number(o['carrier_receivable_balance']) + .001) {
        Get.snackbar(
            'تنبيه', 'توزيع الطلبية ${o['serial_number'] ?? id} غير صحيح');
        return;
      }
      if (amount > 0) rows.add({'order_id': id, 'amount': amount});
      if (amount > 0) sum += amount;
    }
    if ((sum - settledAmount).abs() > .01 || rows.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'مجموع توزيع الطلبيات يجب أن يساوي النقد المستلم مع أجرة الشركة',
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.api.post(EndPoints.settleDeliveryCompanyAccount, data: {
        'delivery_company_id': widget.companyId,
        'delivery_company_name': widget.companyName,
        'allocations': rows,
        'carrier_fee': fee,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        'idempotency_key':
            'carrier-${widget.companyId}-${DateTime.now().microsecondsSinceEpoch}',
      });
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().loadDailySession();
      }
      Get.back(result: true);
      AppSuccessNotice.show(
        title: 'تمت التسوية',
        message: 'تم إغلاق الذمة وإضافة الصافي فقط إلى صندوق الطلبيات اليومي',
      );
    } catch (e) {
      AppFailureNotice.show(
        title: 'تعذر تنفيذ التسوية',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  double get parsedCashReceived =>
      double.tryParse(cashReceived.text.trim()) ?? 0;

  double get parsedCarrierFee => double.tryParse(carrierFee.text.trim()) ?? 0;

  double get settlementAmount => parsedCashReceived + parsedCarrierFee;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final cash = parsedCashReceived;
    final fee = parsedCarrierFee;
    final settled = cash + fee;
    final remainingBalance =
        (maximum - settled).clamp(0, double.infinity).toDouble();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2EDF5),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تسوية ${widget.companyName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${widget.orders.length} طلبيات محددة',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed:
                            saving ? null : () => Get.back(result: false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _summaryBox(
                          'ذمة الشركة',
                          maximum,
                          Icons.receipt_long_outlined,
                        ),
                        const SizedBox(width: 8),
                        _summaryBox(
                          'المتبقي بعدها',
                          remainingBalance,
                          Icons.pending_actions_outlined,
                          accent: remainingBalance > .001
                              ? const Color(0xFFB45309)
                              : const Color(0xFF047857),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 560;
                        final received = _moneyField(
                          controller: cashReceived,
                          label: 'النقد المستلم فعلياً',
                          helper: 'هذا المبلغ فقط سيدخل الصندوق',
                        );
                        final companyFee = _moneyField(
                          controller: carrierFee,
                          label: 'أجرة الشركة المخصومة',
                          helper: 'تُغلق من الذمة ولا تدخل الصندوق',
                        );
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: received),
                              const SizedBox(width: 10),
                              Expanded(child: companyFee),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            received,
                            const SizedBox(height: 10),
                            companyFee,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC6DAE8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calculate_outlined,
                            color: _navy,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سيُغلق من ذمة الشركة ${settled.toStringAsFixed(2)} ₪ '
                              '= ${cash.toStringAsFixed(2)} نقد + ${fee.toStringAsFixed(2)} أجرة',
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'توزيع المبلغ',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'عدّل حصة أي طلبية عند الحاجة',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: distribute,
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('الأقدم أولاً'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < widget.orders.length;
                              index++) ...[
                            _allocationRow(widget.orders[index]),
                            if (index < widget.orders.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'سيُغلق المبلغ من ذمة الشركة، ويدخل الصافي بعد خصم أجرتها إلى صندوق الطلبيات.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : () => Get.back(result: false),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: saving ? null : submit,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('تأكيد التسوية'),
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

  Widget _summaryBox(
    String label,
    double amount,
    IconData icon, {
    Color accent = _navy,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: accent.withValues(alpha: .18)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${amount.toStringAsFixed(2)} ₪',
                        style: TextStyle(
                          color: accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    required String helper,
  }) =>
      TextField(
        controller: controller,
        onChanged: (_) => _redistributeAfterAmountChange(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          suffixText: '₪',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _allocationRow(Map<String, dynamic> order) {
    final id = (order['id'] as num).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order['serial_number'] ?? '#$id'}',
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${order['customer_name'] ?? 'زبون'} • الرصيد ${number(order['carrier_receivable_balance']).toStringAsFixed(2)} ₪',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: TextField(
              controller: allocations[id],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: '₪',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? 0}') ?? 0;

String date(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return '-';
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}
