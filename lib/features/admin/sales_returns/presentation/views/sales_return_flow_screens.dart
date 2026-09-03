import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
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
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الهاتف',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Obx(() => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'customer',
                        label: Text('الزبائن'),
                        icon: Icon(Icons.people_outline)),
                    ButtonSegment(
                        value: 'seller',
                        label: Text('التجار / الموردون'),
                        icon: Icon(Icons.storefront_outlined)),
                  ],
                  selected: {controller.personType.value},
                  onSelectionChanged: (value) =>
                      controller.personType.value = value.first,
                ),
              )),
          Expanded(child: Obx(() {
            if (controller.isLoading.value && controller.people.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = controller.visiblePeople;
            if (rows.isEmpty) {
              return const _EmptyState(
                  icon: Icons.person_search_outlined,
                  text: 'لا يوجد أشخاص لديهم مشتريات قابلة للإرجاع');
            }
            return RefreshIndicator(
              onRefresh: controller.loadPeople,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final person = rows[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                          color: AppColors.operationalCardBorder),
                    ),
                    child: ListTile(
                      onTap: () => controller.choosePerson(person),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primaryColor.withValues(alpha: .12),
                        child: Icon(
                            person.isCustomer
                                ? Icons.person_outline
                                : Icons.storefront_outlined,
                            color: AppColors.primaryColor),
                      ),
                      title: Text(person.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${person.typeLabel}${person.phone.isEmpty ? '' : ' • ${person.phone}'}'),
                      trailing: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                    ),
                  );
                },
              ),
            );
          })),
        ]),
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
          Obx(() => Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14)),
                child: Text('المشتري: ${controller.person.value?.name ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث بالمنتج أو رقم الفاتورة',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          Expanded(child: Obx(() {
            final rows = controller.filteredItems(search.text);
            if (rows.isEmpty) {
              return const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  text: 'لا توجد منتجات متبقية قابلة للإرجاع');
            }
            final width = MediaQuery.sizeOf(context).width;
            final count = width >= 1100
                ? 4
                : width >= 700
                    ? 3
                    : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: width < 500 ? .72 : .9,
              ),
              itemCount: rows.length,
              itemBuilder: (_, index) =>
                  _ReturnProductCard(item: rows[index], controller: controller),
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

class _ReturnProductCard extends StatelessWidget {
  const _ReturnProductCard({required this.item, required this.controller});
  final SalesReturnAvailableItem item;
  final SalesReturnsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selected.containsKey(item.key);
      return Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.toggle(item),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.operationalCardBorder,
                  width: selected ? 2 : 1),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Checkbox(
                    value: selected, onChanged: (_) => controller.toggle(item)),
                Expanded(
                    child: Text('فاتورة ${item.invoiceSerial}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
              Expanded(child: Center(child: _ProductImage(path: item.image))),
              Text(item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (item.sizeLabel.isNotEmpty || item.colorLabel.isNotEmpty)
                Text(
                    [item.sizeLabel, item.colorLabel]
                        .where((e) => e.isNotEmpty)
                        .join(' • '),
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${item.originalUnitPrice.toStringAsFixed(2)} ₪',
                  style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w800)),
              Text('المتاح: ${item.availableQuantity}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              if (selected) ...[
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _QtyButton(
                      icon: Icons.remove,
                      onTap: () =>
                          controller.changeQuantity(item, item.quantity - 1)),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                  _QtyButton(
                      icon: Icons.add,
                      onTap: () =>
                          controller.changeQuantity(item, item.quantity + 1)),
                ]),
              ],
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
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryHeader(
                  person: controller.person.value,
                  items: rows.length,
                  total: total),
              const SizedBox(height: 12),
              ...rows.map((item) => _CheckoutLine(
                    item: item,
                    price: prices[item.key]!,
                    reason: reasons[item.key]!,
                    controller: controller,
                    onChanged: () => setState(() {}),
                  )),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                        color: AppColors.operationalCardBorder)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تسوية قيمة المرتجع',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 6),
                        const Text(
                            'اكتب ما سيتم رده نقدًا من صندوق المبيعات، والباقي يسجل رصيدًا للطرف.'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: cash,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                              labelText: 'المبلغ النقدي المسترد',
                              suffixText: '₪',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _AmountTile(
                                  label: 'نقدي من الصندوق',
                                  value: cashValue,
                                  color: Colors.red.shade700)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _AmountTile(
                                  label: 'رصيد في دفتر الديون',
                                  value: credit,
                                  color: Colors.blue.shade700)),
                        ]),
                        const SizedBox(height: 12),
                        TextField(
                            controller: note,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'سبب المرتجع / ملاحظات',
                                border: OutlineInputBorder())),
                      ]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
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
              const SizedBox(height: 20),
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
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.operationalCardBorder)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _ProductImage(path: item.image, size: 58),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                      'فاتورة ${item.invoiceSerial} • السعر الأصلي ${item.originalUnitPrice.toStringAsFixed(2)} ₪',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Text('الكمية'),
            const Spacer(),
            _QtyButton(
                icon: Icons.remove,
                onTap: () =>
                    controller.changeQuantity(item, item.quantity - 1)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            _QtyButton(
                icon: Icons.add,
                onTap: () =>
                    controller.changeQuantity(item, item.quantity + 1)),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'سعر الوحدة المسترد',
                suffixText: '₪',
                border: OutlineInputBorder()),
            onChanged: (value) {
              item.unitPrice = double.tryParse(value.replaceAll(',', '')) ?? 0;
              controller.selected.refresh();
              onChanged();
            },
          ),
          if (item.priceWasChanged) ...[
            const SizedBox(height: 10),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                  labelText: 'سبب تعديل السعر (إلزامي)',
                  border: OutlineInputBorder()),
              onChanged: (value) => item.priceOverrideReason = value,
            ),
          ],
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('الإجمالي: ${item.lineTotal.toStringAsFixed(2)} ₪',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const CircleAvatar(
              backgroundColor: Colors.white24,
              child:
                  Icon(Icons.assignment_return_outlined, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(person?.name ?? '-',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                Text('$items أصناف محددة',
                    style: const TextStyle(color: Colors.white70)),
              ])),
          Text('${total.toStringAsFixed(2)} ₪',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
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
