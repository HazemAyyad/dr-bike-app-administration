import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../widgets/unified_partner_selector.dart';
import '../../data/sales_return_models.dart';
import '../controllers/sales_returns_controller.dart';

class SalesReturnPersonScreen extends GetView<SalesReturnsController> {
  const SalesReturnPersonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'فاتورة مرتجع مبيعات', action: false),
        body: Obx(() {
          if (controller.isLoading.value && controller.people.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.people.isEmpty) {
            return const _EmptyState(
              icon: Icons.person_search_outlined,
              text: 'لا يوجد أشخاص لديهم مشتريات قابلة للإرجاع',
            );
          }
          return RefreshIndicator(
            onRefresh: controller.loadPeople,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                UnifiedPartnerSelector<SalesReturnPerson>(
                  customers: controller.people
                      .where((person) => person.isCustomer)
                      .toList(),
                  sellers: controller.people
                      .where((person) => !person.isCustomer)
                      .toList(),
                  selected: controller.person.value,
                  selectedIsSeller:
                      controller.person.value?.isCustomer == false,
                  idOf: (person) => person.id,
                  nameOf: (person) => person.name,
                  phoneOf: (person) => person.phone,
                  requiredSelection: true,
                  title: 'اختر صاحب الفاتورة المرتجعة',
                  onSelected: (person, _) => controller.choosePerson(person),
                  onCleared: () => controller.person.value = null,
                ),
                const SizedBox(height: 18),
                const _EmptyState(
                  icon: Icons.assignment_return_outlined,
                  text: 'اختر الزبون أو المورد لعرض المنتجات التي اشتراها',
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class SalesReturnProductPickerScreen extends StatefulWidget {
  const SalesReturnProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<SalesReturnProductPickerScreen> createState() =>
      _SalesReturnProductPickerScreenState();
}

class _SalesReturnProductPickerScreenState
    extends State<SalesReturnProductPickerScreen> {
  final search = TextEditingController();
  SalesReturnsController get controller => Get.find();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _changePerson() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              child: Obx(() => UnifiedPartnerSelector<SalesReturnPerson>(
                    customers: controller.people
                        .where((person) => person.isCustomer)
                        .toList(),
                    sellers: controller.people
                        .where((person) => !person.isCustomer)
                        .toList(),
                    selected: controller.person.value,
                    selectedIsSeller:
                        controller.person.value?.isCustomer == false,
                    idOf: (person) => person.id,
                    nameOf: (person) => person.name,
                    phoneOf: (person) => person.phone,
                    requiredSelection: true,
                    title: 'تغيير المشتري',
                    onSelected: (person, _) async {
                      final loaded = await controller.changePerson(person);
                      if (loaded && sheetContext.mounted) {
                        search.clear();
                        Navigator.pop(sheetContext);
                        setState(() {});
                      }
                    },
                    onCleared: () {},
                  )),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'اختيار منتجات المرتجع',
          action: false,
          actions: [
            Obx(() => Badge(
                  isLabelVisible: controller.selected.isNotEmpty,
                  label: Text('${controller.selected.length}'),
                  child: IconButton(
                    tooltip: 'متابعة',
                    onPressed: controller.goToCheckout,
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  ),
                )),
          ],
        ),
        body: Column(children: [
          Obx(() => Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Material(
                  color: AppColors.primaryColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _changePerson,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: Row(children: [
                        const Icon(Icons.person_outline,
                            color: AppColors.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المشتري',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.black54)),
                              Text(controller.person.value?.name ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const Text('تعديل',
                            style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 3),
                        const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.primaryColor),
                      ]),
                    ),
                  ),
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث برقم الفاتورة أو المنتج',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          Expanded(child: Obx(() {
            final invoices = controller.filteredInvoices(search.text);
            if (invoices.isEmpty) {
              return const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  text: 'لا توجد فواتير فيها منتجات قابلة للإرجاع');
            }
            final width = MediaQuery.sizeOf(context).width;
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: width < 500
                    ? .62
                    : width < 900
                        ? .82
                        : 1.05,
              ),
              itemCount: invoices.length,
              itemBuilder: (_, index) => _ReturnInvoiceCard(
                invoice: invoices[index],
                controller: controller,
              ),
            );
          })),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => FilledButton.icon(
                      onPressed: controller.selected.isEmpty
                          ? null
                          : controller.goToCheckout,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text('متابعة (${controller.selected.length})'),
                    )),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReturnInvoiceCard extends StatelessWidget {
  const _ReturnInvoiceCard({required this.invoice, required this.controller});

  final SalesReturnInvoiceGroup invoice;
  final SalesReturnsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCount = invoice.items
          .where((item) => controller.selected.containsKey(item.key))
          .length;
      return Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showInvoiceProducts(context),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selectedCount > 0
                      ? AppColors.primaryColor
                      : AppColors.operationalCardBorder,
                  width: selectedCount > 0 ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(invoice.sourceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 10)),
                  ),
                  if (selectedCount > 0)
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.primaryColor,
                      child: Text('$selectedCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                ]),
                const SizedBox(height: 7),
                Text(invoice.invoiceSerial,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
                const SizedBox(height: 5),
                Text(_formatInvoiceDate(invoice.invoiceDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
                const Spacer(),
                Text('${invoice.items.length} أصناف',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${invoice.availablePieces} قطعة متاحة',
                    style:
                        TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text('${invoice.availableValue.toStringAsFixed(2)} ₪',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w900)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _showInvoiceProducts(context),
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label:
                        const Text('المنتجات', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _showInvoiceProducts(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _InvoiceProductsSheet(
          invoice: invoice,
          controller: controller,
        ),
      );

  String _formatInvoiceDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _InvoiceProductsSheet extends StatelessWidget {
  const _InvoiceProductsSheet({
    required this.invoice,
    required this.controller,
  });

  final SalesReturnInvoiceGroup invoice;
  final SalesReturnsController controller;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .78,
          maxChildSize: .94,
          minChildSize: .45,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('فاتورة ${invoice.invoiceSerial}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('${invoice.items.length} أصناف قابلة للإرجاع',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: invoice.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _ReturnProductRow(
                    item: invoice.items[index],
                    controller: controller,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('تم اختيار المنتجات'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnProductRow extends StatelessWidget {
  const _ReturnProductRow({required this.item, required this.controller});

  final SalesReturnAvailableItem item;
  final SalesReturnsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selected.containsKey(item.key);
      return Material(
        color: selected
            ? AppColors.primaryColor.withValues(alpha: .06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.toggle(item),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primaryColor
                    : AppColors.operationalCardBorder,
              ),
            ),
            child: Row(children: [
              Checkbox(
                  value: selected, onChanged: (_) => controller.toggle(item)),
              _ProductImage(path: item.image, size: 52),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (item.sizeLabel.isNotEmpty || item.colorLabel.isNotEmpty)
                      Text(
                        [item.sizeLabel, item.colorLabel]
                            .where((value) => value.isNotEmpty)
                            .join(' • '),
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 11),
                      ),
                    Text(
                      '${item.originalUnitPrice.toStringAsFixed(2)} ₪ • المتاح ${item.availableQuantity}',
                      style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (selected)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _QtyButton(
                      icon: Icons.remove,
                      onTap: () =>
                          controller.changeQuantity(item, item.quantity - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  _QtyButton(
                      icon: Icons.add,
                      onTap: () =>
                          controller.changeQuantity(item, item.quantity + 1)),
                ]),
            ]),
          ),
        ),
      );
    });
  }
}

class SalesReturnCheckoutScreen extends StatefulWidget {
  const SalesReturnCheckoutScreen({Key? key}) : super(key: key);
  @override
  State<SalesReturnCheckoutScreen> createState() =>
      _SalesReturnCheckoutScreenState();
}

class _SalesReturnCheckoutScreenState extends State<SalesReturnCheckoutScreen> {
  SalesReturnsController get controller => Get.find();
  final cash = TextEditingController(text: '0');
  final note = TextEditingController();
  final Map<String, TextEditingController> prices = {};
  final Map<String, TextEditingController> reasons = {};

  @override
  void initState() {
    super.initState();
    for (final item in controller.selected.values) {
      prices[item.key] =
          TextEditingController(text: item.unitPrice.toStringAsFixed(2));
      reasons[item.key] = TextEditingController(text: item.priceOverrideReason);
    }
  }

  @override
  void dispose() {
    cash.dispose();
    note.dispose();
    for (final value in prices.values) {
      value.dispose();
    }
    for (final value in reasons.values) {
      value.dispose();
    }
    super.dispose();
  }

  double get cashValue => double.tryParse(cash.text.replaceAll(',', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'ملخص فاتورة المرتجع', action: false),
        body: Obx(() {
          final rows = controller.selected.values.toList();
          final total = controller.total;
          final credit = (total - cashValue).clamp(0, total).toDouble();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _SummaryHeader(
                  person: controller.person.value,
                  items: rows.length,
                  total: total),
              const SizedBox(height: 8),
              ...rows.map((item) => _CheckoutLine(
                    item: item,
                    price: prices[item.key]!,
                    reason: reasons[item.key]!,
                    controller: controller,
                    onChanged: () => setState(() {}),
                  )),
              const SizedBox(height: 4),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                        color: AppColors.operationalCardBorder)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تسوية قيمة المرتجع',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 3),
                        const Text('النقدي من الصندوق، والباقي يسجل رصيدًا.',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: cash,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'النقدي المسترد',
                                suffixText: '₪',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: note,
                              maxLines: 1,
                              decoration: const InputDecoration(
                                labelText: 'سبب المرتجع / ملاحظة',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: _AmountTile(
                                  label: 'نقدي من الصندوق',
                                  value: cashValue,
                                  color: Colors.red.shade700)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _AmountTile(
                                  label: 'رصيد في دفتر الديون',
                                  value: credit,
                                  color: Colors.blue.shade700)),
                        ]),
                      ]),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => controller.submit(
                          cashRefund: cashValue, note: note.text),
                  icon: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(controller.isSubmitting.value
                      ? 'جارٍ إتمام المرتجع...'
                      : 'إتمام فاتورة المرتجع'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }
}

class _CheckoutLine extends StatelessWidget {
  const _CheckoutLine(
      {required this.item,
      required this.price,
      required this.reason,
      required this.controller,
      required this.onChanged});
  final SalesReturnAvailableItem item;
  final TextEditingController price;
  final TextEditingController reason;
  final SalesReturnsController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 7),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.operationalCardBorder)),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _ProductImage(path: item.image, size: 44),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                      'فاتورة ${item.invoiceSerial} • السعر الأصلي ${item.originalUnitPrice.toStringAsFixed(2)} ₪',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                ])),
            Text('${item.lineTotal.toStringAsFixed(2)} ₪',
                style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 7),
          Row(children: [
            _QtyButton(
                icon: Icons.remove,
                onTap: () =>
                    controller.changeQuantity(item, item.quantity - 1)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            _QtyButton(
                icon: Icons.add,
                onTap: () =>
                    controller.changeQuantity(item, item.quantity + 1)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'سعر الوحدة',
                  suffixText: '₪',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  item.unitPrice =
                      double.tryParse(value.replaceAll(',', '')) ?? 0;
                  controller.selected.refresh();
                  onChanged();
                },
              ),
            ),
          ]),
          if (item.priceWasChanged) ...[
            const SizedBox(height: 7),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                  labelText: 'سبب تعديل السعر (إلزامي)',
                  isDense: true,
                  border: OutlineInputBorder()),
              onChanged: (value) => item.priceOverrideReason = value,
            ),
          ],
        ]),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader(
      {required this.person, required this.items, required this.total});
  final SalesReturnPerson? person;
  final int items;
  final double total;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child:
                  Icon(Icons.assignment_return_outlined, color: Colors.white)),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(person?.name ?? '-',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text('$items أصناف محددة',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
          Text('${total.toStringAsFixed(2)} ₪',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
        ]),
      );
}

class _AmountTile extends StatelessWidget {
  const _AmountTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(9)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(2)} ₪',
              style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.path, this.size = 90});
  final String path;
  final double size;
  @override
  Widget build(BuildContext context) {
    final url = path.startsWith('http')
        ? path
        : '${EndPoints.baserUrlForImage}${path.replaceFirst(RegExp(r'^public/'), '')}';
    if (path.isEmpty) {
      return Icon(Icons.inventory_2_outlined,
          size: size * .6, color: Colors.grey.shade400);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_outlined,
              size: size * .6, color: Colors.grey.shade400)),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.primaryColor)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
      ]));
}
