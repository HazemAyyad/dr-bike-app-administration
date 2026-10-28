import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/expentions.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/utils/localized_number.dart';
import '../../data/datasources/stock_datasource.dart';
import '../../data/models/product_details_model.dart';
import 'stock_variant_adjust_sheet.dart';

Future<bool?> showMissingSalesCostSheet({
  required BuildContext context,
  required ProductDetailsModel product,
}) async {
  String? variantId;
  String? variantLabel;
  var currency = product.inventory?.currency ?? 'شيكل';
  if (product.inventory?.hasVariants == true ||
      (product.sizes ?? <Size>[])
          .any((size) => (size.colorSizes ?? <ColorSize>[]).isNotEmpty)) {
    final target =
        await showStockVariantAdjustSheet(context: context, product: product);
    if (target == null || !context.mounted) return null;
    variantId = target.sizeColorId;
    variantLabel = target.subtitle;
    currency = product.inventory?.variants
            .firstWhereOrNull((variant) => variant.sizeColorId == variantId)
            ?.currency ??
        currency;
  }
  if (!context.mounted) return null;
  AppDependencyRegistry.ensureStock();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => MissingSalesCostSheet(
        productId: product.id,
        productName: product.nameAr,
        variantId: variantId,
        variantLabel: variantLabel,
        currency: currency == 'mixed' ? 'شيكل' : currency,
        datasource: Get.find<StockDatasource>()),
  );
}

class MissingSalesCostSheet extends StatefulWidget {
  const MissingSalesCostSheet(
      {Key? key,
      required this.productId,
      required this.productName,
      required this.datasource,
      this.variantId,
      this.variantLabel,
      this.currency = 'شيكل'})
      : super(key: key);
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantLabel;
  final String currency;
  final StockDatasource datasource;
  @override
  State<MissingSalesCostSheet> createState() => _MissingSalesCostSheetState();
}

class _MissingSalesCostSheetState extends State<MissingSalesCostSheet> {
  final _cost = TextEditingController();
  final _reason = TextEditingController();
  final _selected = <int>{};
  Map<String, dynamic>? _preview;
  bool _busy = false;
  String? _error;
  late String _currency = widget.currency;
  List<Map<String, dynamic>> get _sales => (_preview?['sales'] as List? ?? [])
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
  double get _addedCost => _sales
      .where((row) => _selected.contains(row['id']))
      .fold(0, (total, row) => total + (row['added_cost'] as num).toDouble());

  @override
  void dispose() {
    _cost.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_busy,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
              child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('إدخال تكلفة المبيعات الناقصة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text([
                      widget.productName,
                      if (widget.variantLabel != null) widget.variantLabel!
                    ].join(' — ')),
                    const Text(
                        'متاح حتى لو المخزون صفر. يسجل تكلفة القطع المباعة دون تغيير الكمية أو مبلغ البيع والمدفوعات.'),
                    const SizedBox(height: 10),
                    Expanded(
                        child: ListView(children: [
                      TextField(
                          controller: _cost,
                          enabled: !_busy && _preview == null,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: 'تكلفة الوحدة',
                              suffixText: _currency)),
                      DropdownButtonFormField<String>(
                          initialValue: _currency,
                          items: ['شيكل', 'دولار', 'دينار']
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: _busy || _preview != null
                              ? null
                              : (value) => setState(() => _currency = value!),
                          decoration:
                              const InputDecoration(labelText: 'عملة التكلفة')),
                      TextField(
                          controller: _reason,
                          enabled: !_busy,
                          maxLength: 190,
                          decoration: const InputDecoration(
                              labelText: 'سبب إدخال التكلفة (مطلوب)')),
                      if (_preview != null) ...[
                        TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _preview = null;
                                      _selected.clear();
                                      _error = null;
                                    }),
                            child: const Text('تعديل التكلفة وإعادة المراجعة')),
                        if (_sales.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                  'لا توجد مبيعات ناقصة التكلفة لهذا الصنف. الرصيد صفر وحده لا يعني وجود مبيعات بلا تكلفة.')),
                        ..._sales.map((row) => CheckboxListTile(
                              value: _selected.contains(row['id']),
                              onChanged: _busy || row['eligible'] != true
                                  ? null
                                  : (value) => setState(() {
                                        if (value == true) {
                                          _selected.add(row['id'] as int);
                                        } else {
                                          _selected.remove(row['id']);
                                        }
                                      }),
                              title: Text(
                                  '${row['invoice_number']} — ${row['sold_at'] ?? ''}'),
                              subtitle: Text(
                                  'الكمية المباعة: ${row['quantity']}، الناقصة: ${row['missing_quantity']}\n'
                                  '${row['sale_price_included_in_package'] == true ? 'سعر البيع: ضمن سعر الباكيج' : 'سعر بيع القطعة المسجل: ${row['sale_unit_price'] ?? 'غير مسجل'} ${row['currency']}'}\n'
                                  'إجمالي بيع الصنف قبل خصم الفاتورة: ${row['sale_line_total'] ?? 'غير مسجل'} ${row['currency']}\n'
                                  'إجمالي الفاتورة: ${row['invoice_total'] ?? 'غير مسجل'} ${row['currency']}'
                                  '${(row['invoice_discount'] as num? ?? 0) > 0 ? ' — خصم الفاتورة: ${row['invoice_discount']}' : ''}\n'
                                  'التكلفة المعروفة: ${row['known_cost']} ${row['currency']}\n'
                                  'التكلفة بعد التصحيح: ${row['new_total_cost']} ${row['currency']}\n'
                                  'انخفاض الربح: ${row['added_cost']} ${row['currency']}'
                                  '${row['blocked_reason'] == null ? '' : '\n${row['blocked_reason']}'}'),
                              isThreeLine: false,
                              controlAffinity: ListTileControlAffinity.leading,
                            )),
                      ],
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                    ])),
                    if (_preview != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                              'المحدد: ${_selected.length} — التكلفة المضافة وانخفاض الربح: ${_addedCost.toStringAsFixed(2)} $_currency',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                    FilledButton(
                        onPressed:
                            _busy || (_preview != null && _selected.isEmpty)
                                ? null
                                : _submit,
                        child: Text(_busy
                            ? 'جارٍ التحميل...'
                            : _preview == null
                                ? 'مراجعة المبيعات'
                                : 'تأكيد تكلفة المبيعات المحددة')),
                    TextButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء')),
                  ]),
            ),
          )),
        ));
  }

  Future<void> _submit() async {
    if (_busy) return;
    final unitCost = tryParseLocalizedAmount(_cost.text);
    if (unitCost == null ||
        !unitCost.isFinite ||
        unitCost <= 0 ||
        _reason.text.trim().isEmpty) {
      setState(() => _error = 'أدخل تكلفة وحدة أكبر من صفر وسبب إدخالها.');
      return;
    }
    final applying = _preview != null;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.datasource.reviewMissingSalesCost(
          productId: widget.productId,
          sizeColorId: widget.variantId,
          unitCost: unitCost,
          currency: _currency,
          saleIds: applying ? _selected.toList() : null,
          reviewToken: applying ? _preview!['review_token'] as String : null,
          reason: applying ? _reason.text : null);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (!applying) _preview = result;
      });
      if (applying) {
        final pending =
            (result['invoices_still_missing_cost'] as num?)?.toInt() ?? 0;
        if (pending > 0) {
          await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                      title: const Text('تم تسجيل تكلفة الأصناف المحددة'),
                      content: Text(
                          'بقيت $pending فاتورة فيها أصناف أخرى ناقصة التكلفة. تحتاج إكمالها ليكتمل اعتماد التكلفة المحاسبية للفاتورة.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('حسنًا'))
                      ]));
        }
        if (mounted) Navigator.pop(context, true);
      }
    } on ServerException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.errorModel.errorMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'تعذر تسجيل التكلفة. أعد فتح المراجعة وحاول مجددًا.';
        });
      }
    }
  }
}
