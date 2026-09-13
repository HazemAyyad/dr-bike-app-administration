import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../data/models/product_details_model.dart';

class InventorySummarySection extends StatelessWidget {
  const InventorySummarySection({
    Key? key,
    required this.product,
    required this.onAdjust,
    required this.onRevalue,
  }) : super(key: key);

  final ProductDetailsModel product;
  final VoidCallback onAdjust;
  final VoidCallback onRevalue;

  String money(double? value, String currency) =>
      value == null ? '—' : '${value.toStringAsFixed(2)} $currency';
  String qty(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  void showCosts(BuildContext context, InventorySummary inventory) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تفاصيل طبقات التكلفة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              SizedBox(height: 10.h),
              if (inventory.costLayers.isEmpty)
                const Text('لا توجد طبقات تكلفة متبقية.')
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: inventory.costLayers.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final layer = inventory.costLayers[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                            '${layer.sourceType} • ${qty(layer.remainingQuantity)} وحدة'),
                        subtitle: Text(layer.effectiveAt ?? ''),
                        trailing: Text(
                            '${money(layer.unitCost, layer.currency)}\n${money(layer.remainingValue, layer.currency)}',
                            textAlign: TextAlign.end),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = product.inventory;
    if (inventory == null) return const SizedBox.shrink();
    final showCost = product.canViewInventoryCost || canViewCostPrice;
    final hasMissingCost = inventory.missingCostQuantity > 0.0001;
    final method = inventory.costingMethod == 'moving_average'
        ? 'المتوسط المتحرك'
        : 'FIFO';
    final values = <MapEntry<String, String>>[
      MapEntry('الكمية الحالية', qty(inventory.quantityOnHand)),
      MapEntry('طريقة التكلفة', method),
      if (showCost)
        MapEntry('قيمة المخزون',
            money(inventory.inventoryValue, inventory.currency)),
      if (showCost)
        MapEntry('متوسط التكلفة المتبقية',
            money(inventory.averageUnitCost, inventory.currency)),
      if (showCost && inventory.costingMethod == 'fifo')
        MapEntry('تكلفة وحدة FIFO التالية',
            money(inventory.nextFifoUnitCost, inventory.currency)),
      if (showCost && hasMissingCost)
        MapEntry('كمية بلا تكلفة', qty(inventory.missingCostQuantity)),
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AdminUiColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: inventory.coverageComplete
              ? Colors.transparent
              : Colors.orange.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.inventory_2_outlined),
            SizedBox(width: 8.w),
            Expanded(
                child: Text('ملخص المخزون',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900))),
          ]),
          if (!inventory.coverageComplete) ...[
            SizedBox(height: 8.h),
            const Text('تغطية تكلفة المخزون غير مكتملة وتحتاج مراجعة إدارية.',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w700)),
          ],
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: values
                .map((entry) => Container(
                      width: 150.w,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                          color: AdminUiColors.subtleOverlay(context),
                          borderRadius: BorderRadius.circular(10.r)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: Theme.of(context).textTheme.labelSmall),
                            SizedBox(height: 3.h),
                            Text(entry.value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                          ]),
                    ))
                .toList(),
          ),
          if (inventory.variants.isNotEmpty) ...[
            SizedBox(height: 10.h),
            const Text('تفصيل المتغيرات',
                style: TextStyle(fontWeight: FontWeight.w800)),
            ...inventory.variants.map((variant) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${variant.sizeLabel} / ${variant.colorLabel}'),
                  subtitle: showCost
                      ? Text(
                          'المتوسط: ${money(variant.averageUnitCost, variant.currency)}')
                      : null,
                  trailing: Text(qty(variant.quantityOnHand),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                )),
          ],
          if (inventory.recentMovements.isNotEmpty) ...[
            SizedBox(height: 10.h),
            const Text('آخر حركات المخزون',
                style: TextStyle(fontWeight: FontWeight.w800)),
            ...inventory.recentMovements.take(3).map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${entry.type ?? 'حركة'} • ${qty(entry.quantity ?? 0)}',
                    ),
                    subtitle: Text(
                      [entry.variantLabel, entry.reason, entry.createdAt]
                          .where((value) => value?.isNotEmpty == true)
                          .join(' • '),
                    ),
                    trailing: entry.stockAfter == null
                        ? null
                        : Text('بعد: ${qty(entry.stockAfter!)}'),
                  ),
                ),
          ],
          if (inventory.lastAdjustments.isNotEmpty) ...[
            SizedBox(height: 8.h),
            const Text('آخر التسويات',
                style: TextStyle(fontWeight: FontWeight.w800)),
            ...inventory.lastAdjustments.take(3).map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.reason ?? entry.type ?? 'تسوية مخزون'),
                    subtitle: Text(
                      [entry.reference, entry.createdBy, entry.createdAt]
                          .where((value) => value?.isNotEmpty == true)
                          .join(' • '),
                    ),
                    trailing: Text(qty(entry.quantity ?? 0)),
                  ),
                ),
          ],
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (canAdjustInventoryStock)
                FilledButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune),
                  label: const Text('تسوية المخزون'),
                ),
              if (showCost)
                OutlinedButton.icon(
                  onPressed: () => showCosts(context, inventory),
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('تفاصيل التكلفة'),
                ),
              if (showCost &&
                  canAdjustInventoryCost &&
                  inventory.quantityOnHand > 0.0001)
                OutlinedButton.icon(
                  onPressed: onRevalue,
                  icon: const Icon(Icons.price_change_outlined),
                  label: Text(hasMissingCost
                      ? 'إدخال سعر التكلفة'
                      : 'إعادة تقييم التكلفة'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
