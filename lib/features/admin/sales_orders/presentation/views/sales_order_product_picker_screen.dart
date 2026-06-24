import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/utils/app_colors.dart';

import '../../../sales/presentation/controllers/sales_controller.dart';
import '../../../sales/presentation/widgets/sales_location_filter_fab.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_cart_sheet.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_product_picker_skeleton.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_picker_partner_bar.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_product_card.dart';
import '../../../sales/presentation/widgets/new_instant_sale/instant_sale_product_detail_sheet.dart';
import '../controllers/sales_orders_controller.dart';
import '../widgets/sales_order_notice.dart';

/// Sales-order creation using the exact InstantSale product picker UI.
class SalesOrderProductPickerScreen extends StatefulWidget {
  const SalesOrderProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<SalesOrderProductPickerScreen> createState() =>
      _SalesOrderProductPickerScreenState();
}

class _SalesOrderProductPickerScreenState
    extends State<SalesOrderProductPickerScreen> {
  SalesController get sales => Get.find<SalesController>();
  SalesOrdersController get orders => Get.find<SalesOrdersController>();

  final _searchController = TextEditingController();

  static const int _maxRows = 4;
  static const int _minRows = 2;
  static const int _visibleColumns = 4;

  @override
  void initState() {
    super.initState();
    sales.enablePickerReservedStock(salesOrderFlow: true);
    final args = Get.arguments;
    if (args is Map && args['editSalesOrder'] == true) {
      // Cart and form already hydrated in openEditSalesOrderFlow.
    } else if (args is Map && args['freshSalesOrder'] == true) {
      if (!orders.hasSuspendedDraft.value) {
        sales.resetInstantSaleForm();
        sales.isPackageSale.value = false;
        sales.selectedPackageId.value = null;
        orders.resetCreateForm();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SalesOrderNotice.info('salesOrderDraftResuming'.tr);
        });
      }
    }
    _searchController.text = sales.instantSaleProductSearch.value;
    if (sales.products.isEmpty) {
      sales.getAllProducts();
    }
    sales.ensurePickerStoreSectionsLoaded();
    sales.ensurePickerPartnersLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orders.scheduleStockAvailabilityRefresh(sales.filteredProductsForPicker);
    });
  }

  @override
  void dispose() {
    sales.disablePickerReservedStock();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          sales.disablePickerReservedStock();
          if (orders.isEditingOrder) {
            orders.clearActiveEditSalesOrder();
            sales.resetInstantSaleForm();
          }
        }
      },
      child: Scaffold(
      appBar: CustomAppBar(
        title: orders.isEditingOrder ? 'salesOrderEdit' : 'instantSalePickProducts',
        action: false,
        actions: [
          const InstantSalePickerPartnerIcon(),
          _CartAppBarButton(
            onTap: () => showInstantSaleCartSheet(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'instantSaleSearchProductsAndPackages'.tr,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                  onChanged: sales.onInstantSaleProductSearchChanged,
                ),
              ),
              Expanded(
                child: Obx(() {
                  final _ = sales.productsListVersion.value;
                  final searchQuery = sales.instantSaleProductSearch.value;
                  final locationFilter = sales.pickerLocationSectionId.value;
                  final saving = sales.savingProductPrice.value;
                  final loading = sales.productsLoading.value;
                  final searchLoading = sales.instantSalePickerSearchLoading.value;

                  if (loading || searchLoading) {
                    return const InstantSaleProductPickerGridSkeleton();
                  }

                  final hasLocationFilter =
                      locationFilter != null && locationFilter.isNotEmpty;
                  // Orders: show products only (no offer packages), but keep same UI.
                  final packages = const <dynamic>[];
                  final products =
                      hasLocationFilter ? sales.filteredProductsForPicker : sales.filteredProductsForPicker;
                  orders.scheduleStockAvailabilityRefresh(products);
                  final total = products.length;

                  if (total == 0) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasLocationFilter
                                  ? 'noProductsInLocation'.tr
                                  : 'noData'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (hasLocationFilter) ...[
                              SizedBox(height: 12.h),
                              TextButton.icon(
                                onPressed: sales.clearPickerLocationFilter,
                                icon: const Icon(Icons.filter_alt_off_outlined),
                                label: Text('clearFilters'.tr),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final hGap = 6.w;
                          final vGap = 6.h;
                          final padH = 10.w;
                          final gridW = constraints.maxWidth - padH * 2;
                          final gridH = constraints.maxHeight;
                          final minCellH = 82.h;
                          final rows = ((gridH + vGap) / (minCellH + vGap))
                              .floor()
                              .clamp(_minRows, _maxRows);
                          final cellW =
                              (gridW - hGap * (_visibleColumns - 1)) /
                                  _visibleColumns;
                          final cellH = (gridH - vGap * (rows - 1)) / rows;
                          final aspectRatio = cellH / cellW;

                          return GridView.builder(
                            key: ValueKey(
                              'order_picker_grid_${searchQuery}_${sales.productsListVersion.value}',
                            ),
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: padH),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: rows,
                              mainAxisSpacing: hGap,
                              crossAxisSpacing: vGap,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: total + packages.length,
                            itemBuilder: (_, i) {
                              final product = products[i];
                              return GestureDetector(
                                onLongPress: () => showInstantSaleProductDetailSheet(
                                  context,
                                  product,
                                ),
                                child: InstantSaleProductCard(
                                  key: ValueKey('order_picker_${product.id}'),
                                  product: product,
                                  showOrderStock: true,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (saving)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: 0.65),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
          Positioned(
            right: 16.w,
            bottom: 12.h,
            child: const SalesLocationFilterFab(),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final _ = sales.cartRevision.value;
        sales.selectedPackageId.value;
        final selectionCount = sales.pickerSelectionCount;
        final canContinue = sales.cartDistinctCount > 0;

        return SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => showInstantSaleCartSheet(context),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.primaryColor,
                          size: 28.sp,
                        ),
                        if (selectionCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18.w,
                                minHeight: 18.w,
                              ),
                              child: Text(
                                '$selectionCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${'instantSaleCart'.tr} (${sales.cartDistinctCount})',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        '${sales.cartTotalPieces} ${'instantSalePieces'.tr}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 46.h,
                  child: OutlinedButton(
                    onPressed: canContinue ? orders.suspendOrderDraftFromPicker : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Icon(Icons.pause_circle_outline, size: 22.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: canContinue ? sales.openSalesOrderCheckout : null,
                    child: Text(
                      'instantSaleContinue'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ),
    );
  }

}

class _CartAppBarButton extends StatelessWidget {
  const _CartAppBarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    return Obx(() {
      final _ = controller.cartRevision.value;
      controller.selectedPackageId.value;
      final n = controller.pickerSelectionCount;
      final packageOnly = controller.hasSelectedPackage && n == 1;
      return IconButton(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.primaryColor,
              size: 26.sp,
            ),
            if (n > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: packageOnly ? const Color(0xFFE65100) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.w,
                  ),
                  child: Text(
                    '$n',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

