import 'dart:math';

import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sales_controller.dart';

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
      Get.snackbar('تعذر تحميل الحسابات', e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                        padding: const EdgeInsets.all(16),
                        itemCount: accounts.length,
                        itemBuilder: (_, i) {
                          final a = accounts[i];
                          final balance = number(a['outstanding_balance']);
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: const CircleAvatar(
                                  child: Icon(Icons.local_shipping_outlined)),
                              title: Text(
                                  '${a['delivery_company_name'] ?? 'شركة توصيل'}'),
                              subtitle: Text(
                                  'طلبيات غير مسددة: ${a['outstanding_orders_count'] ?? 0}'),
                              trailing: Text(balance.toStringAsFixed(2),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: balance > 0
                                          ? Colors.red
                                          : Colors.green)),
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
      Get.snackbar('تعذر تحميل الحساب', e.toString());
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
      appBar: AppBar(title: Text(companyName)),
      bottomNavigationBar: selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: settle,
                icon: const Icon(Icons.payments_outlined),
                label: Text(
                    'تسوية المحدد (${selected.length}) — ${selectedTotal.toStringAsFixed(2)}'),
              ),
            )),
      body: loading && account.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي المبلغ المطلوب من الشركة'),
                          Text(
                              number(account['outstanding_balance'])
                                  .toStringAsFixed(2),
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                        ]),
                  ),
                ),
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
                  CheckboxListTile(
                    value: selected.contains((o['id'] as num).toInt()),
                    onChanged: (v) => setState(() {
                      final id = (o['id'] as num).toInt();
                      v == true ? selected.add(id) : selected.remove(id);
                    }),
                    title: Text(
                        '${o['serial_number'] ?? '#${o['id']}'} — ${o['customer_name'] ?? 'زبون'}'),
                    subtitle: Text('تاريخ الطلبية: ${date(o['created_at'])}'),
                    secondary: Text(
                        number(o['carrier_receivable_balance'])
                            .toStringAsFixed(2),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                const SizedBox(height: 20),
                const Text('سجل طلبيات الشركة',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final o in orders)
                  Card(
                    child: ListTile(
                      title: Text(
                          '${o['serial_number'] ?? '#${o['id']}'} — ${o['customer_name'] ?? 'زبون'}'),
                      subtitle: Text(
                          '${date(o['created_at'])}\nتم قبض: ${number(o['settled_amount']).toStringAsFixed(2)}'),
                      trailing: Text(
                        number(o['carrier_receivable_balance']) <= 0
                            ? 'مسددة'
                            : 'باقي ${number(o['carrier_receivable_balance']).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: number(o['carrier_receivable_balance']) <= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text('سجل التسويات الجماعية',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (batches.isEmpty)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('لا توجد تسويات مسجلة')))),
                for (final b in batches) batchCard(b),
                const SizedBox(height: 90),
              ]),
            ),
    );
  }

  Widget batchCard(Map b) {
    final raw = b['allocations'];
    final allocations = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return Card(
        child: ExpansionTile(
      title: Text('تسوية بقيمة ${number(b['amount']).toStringAsFixed(2)}'),
      subtitle: Text(
          '${date(b['created_at'])} — ${b['created_by'] ?? '-'}\nالصندوق: ${b['box_name'] ?? 'صندوق الطلبيات اليومي'}'),
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
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
  late final TextEditingController total;
  final notes = TextEditingController();
  final Map<int, TextEditingController> allocations = {};
  bool saving = false;
  double get maximum => widget.orders
      .fold(0, (sum, o) => sum + number(o['carrier_receivable_balance']));

  @override
  void initState() {
    super.initState();
    total = TextEditingController(text: maximum.toStringAsFixed(2));
    for (final o in widget.orders) {
      allocations[(o['id'] as num).toInt()] = TextEditingController(
          text: number(o['carrier_receivable_balance']).toStringAsFixed(2));
    }
  }

  void distribute() {
    var remaining = double.tryParse(total.text.trim()) ?? -1;
    if (remaining <= 0 || remaining > maximum + .001) {
      Get.snackbar('تنبيه', 'المبلغ يجب أن يكون أكبر من صفر ولا يتجاوز الرصيد');
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

  Future<void> submit() async {
    final received = double.tryParse(total.text.trim()) ?? 0;
    if (received <= 0 || received > maximum + .001) {
      Get.snackbar('تنبيه', 'أدخل مبلغاً صحيحاً لا يتجاوز الرصيد المحدد');
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
    if ((sum - received).abs() > .01 || rows.isEmpty) {
      Get.snackbar('تنبيه', 'مجموع توزيع الطلبيات يجب أن يساوي المبلغ المقبوض');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.api.post(EndPoints.settleDeliveryCompanyAccount, data: {
        'delivery_company_id': widget.companyId,
        'delivery_company_name': widget.companyName,
        'allocations': rows,
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        'idempotency_key':
            'carrier-${widget.companyId}-${DateTime.now().microsecondsSinceEpoch}',
      });
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().loadDailySession();
      }
      Get.back(result: true);
      Get.snackbar('تمت التسوية',
          'تمت الإضافة إلى صندوق الطلبيات اليومي وبقيت أي مديونية متبقية');
    } catch (e) {
      Get.snackbar('تعذر تنفيذ التسوية', e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('تسوية ${widget.companyName}'),
        content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: total,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: 'المبلغ المقبوض',
                        helperText:
                            'الحد الأعلى: ${maximum.toStringAsFixed(2)}',
                        border: const OutlineInputBorder())),
                Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                        onPressed: distribute,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: const Text('توزيع على الأقدم أولاً'))),
                const Divider(),
                const Text('يمكن تعديل حصة كل طلبية يدوياً'),
                const SizedBox(height: 8),
                for (final o in widget.orders) ...[
                  TextField(
                      controller: allocations[(o['id'] as num).toInt()],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: '${o['serial_number'] ?? '#${o['id']}'}',
                          helperText:
                              'الرصيد: ${number(o['carrier_receivable_balance']).toStringAsFixed(2)}',
                          border: const OutlineInputBorder())),
                  const SizedBox(height: 10),
                ],
                TextField(
                    controller: notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text(
                    'المبلغ يدخل صندوق الطلبيات اليومي، وأي باقي يظل مديونية على الشركة.'),
              ],
            ))),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Get.back(result: false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: saving ? null : submit,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('تأكيد التسوية')),
        ],
      );
}

double number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? 0}') ?? 0;

String date(dynamic value) {
  final parsed = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (parsed == null) return '-';
  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}
