import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../stock/data/models/offer_package_model.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
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
  bool _maintenanceFlow = false;
  bool _adjustmentFlow = false;

  static const int _maxRows = 4;
  static const int _minRows = 2;
  static const int _visibleColumns = 4;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final maintenanceFlow = args is Map && args['maintenanceFlow'] == true;
    final adjustmentFlow =
        Get.currentRoute == AppRoutes.ADJUSTMENTSALEPRODUCTPICKER ||
            (args is Map && args['saleKind'] == kInstantSaleKindAdjustment);
    _maintenanceFlow = maintenanceFlow;
    _adjustmentFlow = adjustmentFlow;
    controller.setInstantSaleAdjustmentMode(adjustmentFlow);

    if (maintenanceFlow) {
      controller.setMaintenancePickerFlow(true);
    } else {
      controller.enablePickerReservedStock();
    }

    if (!maintenanceFlow && args is Map && args['freshInstantSale'] == true) {
      controller.resetInstantSaleForm();
      controller.isPackageSale.value = false;
      controller.setInstantSaleAdjustmentMode(adjustmentFlow);
    }
    _searchController.text = controller.instantSaleProductSearch.value;
    if (controller.products.isEmpty) {
      controller.getAllProducts();
    }
    if (!adjustmentFlow) {
      controller.loadOfferPackagesForSale();
    }
    controller.ensurePickerStoreSectionsLoaded();
    controller.ensurePickerPartnersLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<SalesOrdersController>() ||
          Get.isPrepared<SalesOrdersController>()) {
        Get.find<SalesOrdersController>().scheduleStockAvailabilityRefresh(
          controller.filteredProductsForPicker,
        );
      }
      if (mounted &&
          !_maintenanceFlow &&
          controller.activeSuspendedSaleId.value == null &&
          controller.activeEditInstantSaleId.value == null) {
        await controller.promptRestoreLocalInstantSaleDraft(context);
      }
    });
  }

  @override
  void dispose() {
    controller.disablePickerReservedStockAfterFrame();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: _adjustmentFlow
              ? 'adjustmentSalePickProducts'
              : 'instantSalePickProducts',
          action: false,
          onPressedBack: _handleBackPressed,
          actions: [
            const InstantSalePickerPartnerIcon(),
            IconButton(
              tooltip: 'instantSalePasteProductList'.tr,
              onPressed: _openPasteProductListDialog,
              icon: const Icon(Icons.content_paste_search_outlined),
            ),
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
                  child: Row(
                    children: [
                      Expanded(
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
                          onChanged:
                              controller.onInstantSaleProductSearchChanged,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      SizedBox(
                        height: 48.h,
                        width: 48.h,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: _openPasteProductListDialog,
                          child: Icon(
                            Icons.content_paste_search_outlined,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  if (!controller.hasPastedProductRequests) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 44.h,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          final allSelected =
                              controller.isShowingAllPastedProductRequests;
                          final pickedCount =
                              controller.pastedProductSelections.length;
                          return ChoiceChip(
                            selected: allSelected,
                            avatar: allSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF6B5DD3),
                                    size: 18,
                                  )
                                : null,
                            label: Text(
                              '${'all'.tr} ($pickedCount/${controller.pastedProductRequests.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onSelected: (_) async {
                              await controller
                                  .showAllPastedProductSuggestions();
                              _searchController.clear();
                            },
                          );
                        }
                        final lineIndex = index - 1;
                        final request =
                            controller.pastedProductRequests[lineIndex];
                        final selected =
                            controller.activePastedProductRequestIndex.value ==
                                lineIndex;
                        final picked =
                            controller.pastedRequestHasSelection(lineIndex);
                        final pickedProductName = controller
                            .pastedRequestSelectedProductName(lineIndex);
                        return ChoiceChip(
                          selected: selected,
                          avatar: selected || picked
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF15803D),
                                  size: 18,
                                )
                              : null,
                          label: Text(
                            pickedProductName == null
                                ? '${request.searchText} × ${request.quantity}'
                                : '${request.searchText} × ${request.quantity} - $pickedProductName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onSelected: (_) async {
                            await controller
                                .selectPastedProductRequest(lineIndex);
                            _searchController.text = request.searchText;
                          },
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(width: 6.w),
                      itemCount: controller.pastedProductRequests.length + 1,
                    ),
                  );
                }),
                Obx(() {
                  if (!controller.hasPastedProductRequests) {
                    return const SizedBox.shrink();
                  }
                  final request = controller.activePastedProductRequest;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            request == null
                                ? '${'instantSaleActivePastedLine'.tr}: ${'all'.tr}'
                                : '${'instantSaleActivePastedLine'.tr}: ${request.rawLine}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            controller.clearPastedProductRequests();
                            _searchController.clear();
                            controller.onInstantSaleProductSearchChanged('');
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: Text('clear'.tr),
                        ),
                      ],
                    ),
                  );
                }),
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
                    final searchQuery =
                        controller.instantSaleProductSearch.value;
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

                    final hasLocationFilter =
                        locationFilter != null && locationFilter.isNotEmpty;
                    final packages = hasLocationFilter ||
                            controller.maintenancePickerFlow.value ||
                            _adjustmentFlow
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
                                  onPressed:
                                      controller.clearPickerLocationFilter,
                                  icon:
                                      const Icon(Icons.filter_alt_off_outlined),
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
                                  showOrderStock: !_adjustmentFlow,
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
                                  ? (controller.selectedOfferPackage?.name ??
                                      '')
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
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    if (_maintenanceFlow) {
      Get.back();
      return;
    }
    final canLeave = await controller.confirmLeaveInstantSaleFlow(context);
    if (!mounted || !canLeave) return;
    Get.back();
  }

  Future<void> _openPasteProductListDialog() async {
    final textController = TextEditingController();
    Timer? previewDebounce;
    var previewLoading = false;
    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> runPreview(String value) async {
            final text = value.trim();
            if (text.isEmpty) return;
            setDialogState(() => previewLoading = true);
            await controller.previewPastedProductList(text);
            if (ctx.mounted) {
              setDialogState(() => previewLoading = false);
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'instantSalePasteProductList'.tr,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SizedBox(
              width: 620.w,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: textController,
                      minLines: 5,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: Color(0xFF111827)),
                      onChanged: (value) {
                        previewDebounce?.cancel();
                        previewDebounce = Timer(
                          const Duration(milliseconds: 450),
                          () => runPreview(value),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'instantSalePasteProductListHint'.tr,
                        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.4,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (previewLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    Obx(() {
                      if (!controller.hasPastedProductRequests) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: List.generate(
                          controller.pastedProductRequests.length,
                          (index) {
                            final line =
                                controller.pastedProductRequests[index];
                            final picked =
                                controller.pastedRequestHasSelection(index);
                            return Container(
                              margin: EdgeInsets.only(top: 8.h),
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: picked
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      if (picked)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF15803D),
                                          size: 18,
                                        ),
                                      if (picked) SizedBox(width: 6.w),
                                      Expanded(
                                        child: Text(
                                          '${line.rawLine}  × ${line.quantity}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: const Color(0xFF111827),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  if (line.suggestions.isEmpty)
                                    Text(
                                      'noData'.tr,
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 6.w,
                                      runSpacing: 6.h,
                                      children: line.suggestions.map((s) {
                                        final selectedProduct =
                                            controller.pastedProductSelections[
                                                    index] ==
                                                s.product.id;
                                        return ActionChip(
                                          backgroundColor: selectedProduct
                                              ? const Color(0xFFEAF7EE)
                                              : const Color(0xFFF8FAFC),
                                          side: BorderSide(
                                            color: selectedProduct
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFFD1D5DB),
                                          ),
                                          avatar: Icon(
                                            selectedProduct
                                                ? Icons.check_circle
                                                : Icons.inventory_2_outlined,
                                            size: 16,
                                            color: selectedProduct
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF374151),
                                          ),
                                          label: Text(
                                            s.product.nameAr,
                                            style: const TextStyle(
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          onPressed: () async {
                                            await controller
                                                .addProductFromPastedSuggestionAt(
                                              index,
                                              s.product,
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                ),
                child: Text('cancel'.tr),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, textController.text),
                icon: const Icon(Icons.search),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFF9CA3AF)),
                ),
                label: Text('instantSaleSuggestProducts'.tr),
              ),
            ],
          );
        },
      ),
    );
    previewDebounce?.cancel();
    if (pasted == null || pasted.trim().isEmpty) return;
    if (!controller.hasPastedProductRequests) {
      await controller.applyPastedProductList(pasted);
    }
    final request = controller.activePastedProductRequest;
    if (request != null) {
      _searchController.text = request.searchText;
    }
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
