import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/product_priority_image.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/desktop_layout.dart';
import '../../../../sales/presentation/widgets/new_instant_sale/instant_sale_product_picker_skeleton.dart';
import '../../../../sales/presentation/widgets/new_instant_sale/instant_sale_qty_stepper.dart';
import '../../controllers/return_purchases_controller.dart';

class PurchaseReturnProductPickerScreen extends StatefulWidget {
  const PurchaseReturnProductPickerScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseReturnProductPickerScreen> createState() =>
      _PurchaseReturnProductPickerScreenState();
}

class _PurchaseReturnProductPickerScreenState
    extends State<PurchaseReturnProductPickerScreen> {
  final controller = Get.find<ReturnPurchasesController>();
  final searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadDirectOptions(force: true);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_ReturnProductGroup> get groups {
    final grouped = <int, List<PurchaseReturnDraftLine>>{};
    for (final line in controller.directItems) {
      grouped.putIfAbsent(line.productId, () => []).add(line);
    }
    final normalized = query.trim().toLowerCase();
    return grouped.values
        .map((lines) => _ReturnProductGroup(lines))
        .where((group) => normalized.isEmpty || group.matches(normalized))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'اختيار منتجات الراجع',
        action: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث باسم المنتج أو رقمه',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: GetBuilder<ReturnPurchasesController>(
              builder: (_) {
                if (controller.directOptionsLoading.value &&
                    controller.directItems.isEmpty) {
                  return const InstantSaleProductPickerGridSkeleton();
                }
                if (controller.directOptionsError.value.isNotEmpty &&
                    controller.directItems.isEmpty) {
                  return _PickerError(
                    message: controller.directOptionsError.value,
                    onRetry: () => controller.loadDirectOptions(force: true),
                  );
                }
                final visible = groups;
                if (visible.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات مطابقة'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final hGap = 6.w;
                    final vGap = 6.h;
                    final horizontalPadding = 10.w;
                    final desktop = DesktopLayout.isDesktop(context);
                    if (!desktop) {
                      final tileWidth = ((constraints.maxWidth -
                                  horizontalPadding * 2 -
                                  hGap * 3) /
                              4)
                          .clamp(68.0, 96.0)
                          .toDouble();
                      return GridView.builder(
                        key: ValueKey('return_picker_grid_$query'),
                        scrollDirection: Axis.horizontal,
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: hGap,
                          crossAxisSpacing: vGap,
                          mainAxisExtent: tileWidth,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (_, index) => _ReturnProductCard(
                          group: visible[index],
                          controller: controller,
                          onChanged: () => setState(() {}),
                        ),
                      );
                    }
                    final columns = DesktopLayout.gridColumnsForWidth(
                      constraints.maxWidth - horizontalPadding * 2,
                      minTileWidth: 190,
                      min: 4,
                      max: 8,
                      gap: hGap,
                    );
                    return GridView.builder(
                      key: ValueKey('return_picker_grid_$query'),
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: hGap,
                        crossAxisSpacing: vGap,
                        childAspectRatio: .76,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (_, index) => _ReturnProductCard(
                        group: visible[index],
                        controller: controller,
                        onChanged: () => setState(() {}),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: GetBuilder<ReturnPurchasesController>(
        builder: (_) {
          final selected = controller.selectedDirectItems;
          final total =
              selected.fold<double>(0, (sum, line) => sum + line.total);
          return SafeArea(
            child: Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.shopping_cart_outlined,
                        color: AppColors.primaryColor, size: 28.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('الراجع (${selected.length})',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13.sp)),
                        Text(
                            '${total.toStringAsFixed(2)} ${controller.directCurrency.value}',
                            style: TextStyle(
                                fontSize: 12.sp, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: selected.isEmpty ? null : () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(110.w, 46.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: const Text('متابعة'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReturnProductGroup {
  const _ReturnProductGroup(this.lines);

  final List<PurchaseReturnDraftLine> lines;

  PurchaseReturnDraftLine get primary => lines.first;
  double get selectedQuantity =>
      lines.fold(0, (total, line) => total + line.quantity);
  double get available =>
      lines.fold(0, (total, line) => total + line.available);
  bool get hasVariants => lines.length > 1 || primary.variant.isNotEmpty;
  List<String> get imageUrls => lines
      .expand((line) => line.allImageUrlsInPriority)
      .where((url) => url.trim().isNotEmpty)
      .toSet()
      .toList(growable: false);

  bool matches(String query) =>
      primary.productName.toLowerCase().contains(query) ||
      primary.productNameEnglish.toLowerCase().contains(query) ||
      primary.productCode.toLowerCase().contains(query) ||
      primary.productId.toString().contains(query) ||
      lines.any((line) => line.variant.toLowerCase().contains(query));
}

class _ReturnProductCard extends StatelessWidget {
  const _ReturnProductCard({
    required this.group,
    required this.controller,
    required this.onChanged,
  });

  final _ReturnProductGroup group;
  final ReturnPurchasesController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isDesktop(context);
    final selected = group.selectedQuantity;
    final simpleLine = group.lines.length == 1 ? group.primary : null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected > 0 ? AppColors.primaryColor : Colors.grey.shade300,
            width: selected > 0 ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: InkWell(
                onTap: () => _openSelection(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    group.imageUrls.isEmpty
                        ? _ImagePlaceholder(iconSize: 24.sp)
                        : ProductPriorityImage(
                            imageUrls: group.imageUrls,
                            fit: BoxFit.cover,
                            placeholder: _ImagePlaceholder(iconSize: 24.sp),
                            missingPlaceholder:
                                _ImagePlaceholder(iconSize: 24.sp),
                          ),
                    Positioned(
                      bottom: 3.h,
                      right: 3.w,
                      child: _ReturnStockBadge(
                        quantity: _quantity(group.available),
                      ),
                    ),
                    if (selected > 0)
                      Positioned(
                        top: 4.h,
                        left: 4.w,
                        child: _Badge(
                          text: _quantity(selected),
                          color: AppColors.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 3.h),
                child: Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openSelection(context),
                        child: Center(
                          child: Text(
                            group.primary.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: desktop ? 11.sp : 8.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.05),
                          ),
                        ),
                      ),
                    ),
                    if (simpleLine != null)
                      InstantSaleQtyStepper(
                        compact: true,
                        quantity: simpleLine.quantity.round(),
                        canDecrement: simpleLine.quantity > 0,
                        canIncrement:
                            simpleLine.quantity < simpleLine.available,
                        onDecrement: () => _change(simpleLine, -1),
                        onIncrement: () => _change(simpleLine, 1),
                        onQuantityTap: () => _promptQuantity(
                          context,
                          simpleLine,
                        ),
                      )
                    else
                      SizedBox(
                        height: 22.h,
                        child: TextButton(
                          onPressed: () => _openSelection(context),
                          child: Text(
                              desktop ? 'اختيار المقاس واللون' : 'اختيار',
                              style: TextStyle(
                                  fontSize: desktop ? 9.sp : 7.sp,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _change(PurchaseReturnDraftLine line, double delta) {
    controller.changeDirectQuantity(line, line.quantity + delta);
    onChanged();
  }

  Future<void> _openSelection(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(group.primary.productName,
                    style: TextStyle(
                        fontSize: 17.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 12.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: group.lines.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final line = group.lines[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line.variant.isEmpty
                                    ? 'المنتج'
                                    : line.variant),
                                Text(
                                  'المتاح ${_quantity(line.available)} · ${line.effectiveUnitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          InstantSaleQtyStepper(
                            quantity: line.quantity.round(),
                            canDecrement: line.quantity > 0,
                            canIncrement: line.quantity < line.available,
                            onDecrement: () {
                              _change(line, -1);
                              setSheetState(() {});
                            },
                            onIncrement: () {
                              _change(line, 1);
                              setSheetState(() {});
                            },
                            onQuantityTap: () async {
                              await _promptQuantity(context, line);
                              setSheetState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size.fromHeight(48.h),
                  ),
                  child: const Text('تم'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    onChanged();
  }

  Future<void> _promptQuantity(
    BuildContext context,
    PurchaseReturnDraftLine line,
  ) async {
    if (line.available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد كمية متاحة من هذا المنتج في المخزون'),
        ),
      );
      return;
    }
    final input = TextEditingController(text: _quantity(line.quantity));
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحديد الكمية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المتاح ${_quantity(line.available)}'),
            SizedBox(height: 10.h),
            TextField(
              controller: input,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                final parsed = double.tryParse(input.text.trim());
                if (parsed != null) Navigator.pop(dialogContext, parsed);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(input.text.trim());
              if (parsed != null) Navigator.pop(dialogContext, parsed);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    input.dispose();
    if (value == null) return;
    controller.changeDirectQuantity(line, value);
    onChanged();
  }
}

class _PickerError extends StatelessWidget {
  const _PickerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.red),
              SizedBox(height: 10.h),
              Text(message, textAlign: TextAlign.center),
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.grey.shade100,
        child: Icon(Icons.inventory_2_outlined,
            size: iconSize, color: Colors.grey.shade400),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color ?? Colors.black.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(text,
            style: TextStyle(
                color: Colors.white,
                fontSize: 8.sp,
                fontWeight: FontWeight.w700)),
      );
}

class _ReturnStockBadge extends StatelessWidget {
  const _ReturnStockBadge({required this.quantity});

  final String quantity;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: quantity == '0'
              ? Colors.red.shade700
              : Colors.black.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white, size: 8.sp),
            SizedBox(width: 2.w),
            Text(quantity == '0' ? 'غير متوفر' : quantity,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5.sp,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
