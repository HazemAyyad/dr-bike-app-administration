import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../stock/data/models/offer_package_model.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/sales_controller.dart';
import '../../../sales_orders/presentation/controllers/sales_orders_controller.dart';
import '../widgets/new_instant_sale/instant_sale_cart_sheet.dart';
import '../widgets/new_instant_sale/instant_sale_package_card.dart';
import '../widgets/sales_location_filter_fab.dart';
import '../widgets/new_instant_sale/instant_sale_picker_partner_bar.dart';
import '../widgets/new_instant_sale/instant_sale_product_card.dart';
import '../widgets/new_instant_sale/instant_sale_product_picker_skeleton.dart';

/// شاشة اختيار المنتجات (سلة) قبل إتمام البيع الفوري.
class InstantSaleProductPickerScreen extends StatefulWidget {
  const InstantSaleProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<InstantSaleProductPickerScreen> createState() =>
      _InstantSaleProductPickerScreenState();
}

class _InstantSaleProductPickerScreenState
    extends State<InstantSaleProductPickerScreen> {
  SalesController get controller => Get.find<SalesController>();
  final _searchController = TextEditingController();

  static const int _maxRows = 4;
  static const int _minRows = 2;
  static const int _visibleColumns = 4;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final maintenanceFlow =
        args is Map && args['maintenanceFlow'] == true;

    if (maintenanceFlow) {
      controller.setMaintenancePickerFlow(true);
    } else {
      controller.enablePickerReservedStock();
    }

    if (!maintenanceFlow &&
        args is Map &&
        args['freshInstantSale'] == true) {
      controller.resetInstantSaleForm();
      controller.isPackageSale.value = false;
    }
    _searchController.text = controller.instantSaleProductSearch.value;
    if (controller.products.isEmpty) {
      controller.getAllProducts();
    }
    controller.loadOfferPackagesForSale();
    controller.ensurePickerStoreSectionsLoaded();
    controller.ensurePickerPartnersLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<SalesOrdersController>() ||
          Get.isPrepared<SalesOrdersController>()) {
        Get.find<SalesOrdersController>().scheduleStockAvailabilityRefresh(
          controller.filteredProductsForPicker,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.disablePickerReservedStock();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'instantSalePickProducts',
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
                  onChanged: controller.onInstantSaleProductSearchChanged,
                ),
              ),
              Obx(() {
                final suspendedRef = controller.activeSuspendedReferenceCode;
                if (suspendedRef != null) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${'suspendedInvoiceResuming'.tr}: $suspendedRef',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                final editRef = controller.activeEditInstantSaleReference;
                if (editRef != null) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${'instantSaleEditing'.tr}: #$editRef',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Expanded(
                child: Obx(() {
                  final _ = controller.productsListVersion.value;
                  final searchQuery = controller.instantSaleProductSearch.value;
                  final locationFilter =
                      controller.pickerLocationSectionId.value;
                  final saving = controller.savingProductPrice.value;
                  final loading = controller.productsLoading.value;
                  final searchLoading =
                      controller.instantSalePickerSearchLoading.value;

                  if (loading) {
                    return const InstantSaleProductPickerGridSkeleton();
                  }

                  if (searchLoading) {
                    return const InstantSaleProductPickerGridSkeleton();
                  }

                  final hasLocationFilter = locationFilter != null &&
                      locationFilter.isNotEmpty;
                  final packages = hasLocationFilter ||
                          controller.maintenancePickerFlow.value
                      ? <OfferPackageModel>[]
                      : controller.filteredPackagesForPicker;
                  final products = controller.filteredProductsForPicker;
                  if (Get.isRegistered<SalesOrdersController>()) {
                    Get.find<SalesOrdersController>()
                        .scheduleStockAvailabilityRefresh(products);
                  }
                  final total = packages.length + products.length;

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
                                onPressed: controller.clearPickerLocationFilter,
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
                              'picker_grid_${searchQuery}_${controller.productsListVersion.value}',
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
                            itemCount: total,
                            itemBuilder: (_, i) {
                              if (i < packages.length) {
                                final pkg = packages[i];
                                return InstantSalePackageCard(
                                  key: ValueKey('picker_pkg_${pkg.id}'),
                                  package: pkg,
                                );
                              }
                              final product = products[i - packages.length];
                              return InstantSaleProductCard(
                                key: ValueKey('picker_${product.id}'),
                                product: product,
                                showOrderStock: true,
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
        final count = controller.cartTotalPieces;
        final lines = controller.cartDistinctCount;
        final packageSelected = controller.hasSelectedPackage;
        final selectionCount = controller.pickerSelectionCount;
        final canContinue = controller.canContinueFromPicker;
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
                              decoration: BoxDecoration(
                                color: packageSelected
                                    ? const Color(0xFFE65100)
                                    : Colors.red,
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
                        packageSelected && lines > 0
                            ? 'instantSalePackageAndProducts'.tr
                            : packageSelected
                                ? 'saleOfferPackage'.tr
                                : '${'instantSaleCart'.tr} ($lines)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        packageSelected && lines > 0
                            ? '${controller.selectedOfferPackage?.name ?? ''} + $count ${'instantSalePieces'.tr}'
                            : packageSelected
                                ? (controller.selectedOfferPackage?.name ?? '')
                                : '$count ${'instantSalePieces'.tr}',
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
                if (!controller.isEditingInstantSale &&
                    !controller.maintenancePickerFlow.value) ...[
                  SizedBox(
                    height: 46.h,
                    child: OutlinedButton(
                      onPressed: canContinue
                          ? () => controller.suspendInstantSale(
                                context,
                                currentStep: 'product_picker',
                              )
                          : null,
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
                ],
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
                    onPressed: canContinue
                        ? () {
                            if (controller.maintenancePickerFlow.value) {
                              controller.confirmMaintenancePickerAndPop();
                            } else {
                              controller.openInstantSaleCheckout();
                            }
                          }
                        : null,
                    child: Text(
                      controller.maintenancePickerFlow.value
                          ? 'confirm'.tr
                          : 'instantSaleContinue'.tr,
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
                    color: packageOnly
                        ? const Color(0xFFE65100)
                        : Colors.red,
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
