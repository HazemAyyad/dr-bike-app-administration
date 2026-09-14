import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../../data/models/negative_stock_item_model.dart';
import '../controllers/stock_controller.dart';
import '../utils/open_product_purchase.dart';
import '../views/product_stock_movements_screen.dart';
import 'stock_quick_adjust_sheet.dart';

class NegativeStockTab extends GetView<StockController> {
  const NegativeStockTab({Key? key}) : super(key: key);

  Future<void> _adjust(
    BuildContext context,
    NegativeStockItemModel row,
  ) async {
    if (!canAdjustInventoryStock) {
      AppFailureNotice.show(
        context: context,
        title: 'error'.tr,
        message: 'permissionDenied'.tr,
      );
      return;
    }
    final result = await showStockQuickAdjustSheet(
      context: context,
      title: row.productName,
      subtitle: row.variantLabel,
      currentStock: row.stock,
    );
    if (result == null) return;
    final saved = await controller.adjustProductStock(
      productId: row.productId,
      sizeColorId: row.sizeColorId,
      actualQuantity: result.actualQuantity,
      reason: result.reason,
      notes: result.notes,
      unitCost: result.unitCost,
    );
    if (saved) await controller.loadNegativeStock();
  }

  Future<void> _details(NegativeStockItemModel row) async {
    await controller.getProductDetails(productId: row.productId);
    await Get.toNamed(AppRoutes.PRODUCTDETAILSSCREEN);
    await controller.loadNegativeStock();
  }

  void _movements(NegativeStockItemModel row) {
    Get.toNamed(
      AppRoutes.PRODUCTSTOCKMOVEMENTSSCREEN,
      arguments: ProductStockMovementsArgs(
        productId: row.productId,
        productName: row.productName,
        currentStock: row.stock,
        hasVariants: row.sizeColorId != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isNegativeStockLoading.value &&
          controller.negativeStockItems.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final rows = controller.filteredNegativeStockItems;
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Summary(controller: controller),
            SizedBox(height: 10.h),
            TextField(
              controller: controller.negativeStockSearchController,
              onChanged: (value) =>
                  controller.negativeStockSearch.value = value,
              decoration: InputDecoration(
                hintText: 'ابحث بالمنتج أو الموظف أو رقم الفاتورة',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.negativeStockSearch.value.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          controller.negativeStockSearchController.clear();
                          controller.negativeStockSearch.value = '';
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: AdminUiColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (rows.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 50.h),
                child: const Center(child: Text('لا يوجد مخزون سالب حاليًا')),
              )
            else
              ...rows.map((row) => _NegativeStockCard(
                    row: row,
                    onDetails: () => _details(row),
                    onMovements: () => _movements(row),
                    onAdjust: () => _adjust(context, row),
                    onPurchase: () => openProductPurchase(
                      context: context,
                      productId: row.productId,
                      sizeColorId: row.sizeColorId,
                    ),
                  )),
          ],
        ),
      );
    });
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.controller});

  final StockController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${controller.negativeStockItems.length} صنف/متغير سالب · '
              'النقص ${controller.negativeStockMissingQuantity.value} قطعة · '
              'تكلفة معلقة ${controller.negativeStockPendingCostQuantity.value.toStringAsFixed(0)} قطعة',
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: controller.isNegativeStockLoading.value
                ? null
                : controller.loadNegativeStock,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _NegativeStockCard extends StatelessWidget {
  const _NegativeStockCard({
    required this.row,
    required this.onDetails,
    required this.onMovements,
    required this.onAdjust,
    required this.onPurchase,
  });

  final NegativeStockItemModel row;
  final VoidCallback onDetails;
  final VoidCallback onMovements;
  final VoidCallback onAdjust;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final latestCause = row.causes.isEmpty ? null : row.causes.first;
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF45272B)
          : const Color(0xFFFFF5F5),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onDetails,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: SizedBox(
                      width: 58.w,
                      height: 58.w,
                      child: ProductPriorityImage(
                        imageUrls: row.image.isEmpty ? const [] : [row.image],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.productName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        if (row.variantLabel?.isNotEmpty == true)
                          Text(row.variantLabel!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        if (row.productCode.isNotEmpty)
                          Text('الكود: ${row.productCode}'),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${row.stock}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'آخر حركة أنشأت/زادت السالب: ${row.lastCreatedByName ?? 'غير معروف'}'
              '${row.lastInvoiceNumber == null ? '' : ' · ${row.lastInvoiceNumber}'}'
              '${row.lastNegativeAt == null ? '' : ' · ${row.lastNegativeAt}'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (latestCause != null && row.causes.length > 1)
              Text('يوجد ${row.causes.length} حركات سالبة ظاهرة في السجل.'),
            if (row.pendingCostQuantity > 0)
              Text(
                'تكلفة ${row.pendingCostQuantity.toStringAsFixed(0)} قطعة معلقة حتى الاستلام أو التسوية.',
                style: const TextStyle(color: Color(0xFFC62828)),
              ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                FilledButton.icon(
                  onPressed: onPurchase,
                  icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                  label: const Text('شراء جديد'),
                ),
                OutlinedButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('تسوية المخزون'),
                ),
                TextButton.icon(
                  onPressed: onMovements,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('السجل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
