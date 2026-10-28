import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/helpers/admin_ui_colors.dart';
import '../../../../../../core/helpers/product_priority_image.dart';
import '../../../../sales/data/models/product_model.dart';
import '../../../../sales/data/models/product_variant_model.dart';
import '../../controllers/bills_controller.dart';
import 'purchase_variant_create_dialog.dart';

import '../../../../../../core/helpers/app_failure_notice.dart';

Future<List<PurchaseVariantSelection>?> showPurchaseVariantPickerSheet({
  required BuildContext context,
  required ProductModel product,
  required List<PurchaseCartItemModel> initialItems,
  required CreatePurchaseVariant onCreate,
}) {
  return showModalBottomSheet<List<PurchaseVariantSelection>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PurchaseVariantPickerSheet(
      product: product,
      initialItems: initialItems,
      onCreate: onCreate,
    ),
  );
}

class _VariantDraft {
  _VariantDraft({
    required this.size,
    required this.variant,
    required double defaultPrice,
    PurchaseCartItemModel? initial,
  })  : selected = initial != null,
        quantityController = TextEditingController(
          text: initial?.quantityController.text ?? '1',
        ),
        priceController = TextEditingController(
          text: initial?.priceController.text ??
              (defaultPrice > 0 ? defaultPrice.toStringAsFixed(2) : ''),
        );

  final ProductSizeVariant size;
  final ProductColorVariant variant;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  bool selected;

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }
}

class _PurchaseVariantPickerSheet extends StatefulWidget {
  const _PurchaseVariantPickerSheet({
    required this.product,
    required this.initialItems,
    required this.onCreate,
  });

  final ProductModel product;
  final List<PurchaseCartItemModel> initialItems;
  final CreatePurchaseVariant onCreate;

  @override
  State<_PurchaseVariantPickerSheet> createState() =>
      _PurchaseVariantPickerSheetState();
}

class _PurchaseVariantPickerSheetState
    extends State<_PurchaseVariantPickerSheet> {
  final _scrollController = ScrollController();
  late final List<_VariantDraft> drafts = [
    for (final size in widget.product.sizes)
      for (final variant in size.colorSizes)
        _VariantDraft(
          size: size,
          variant: variant,
          defaultPrice: widget.product.purchaseCost,
          initial: _initialFor(variant.id),
        ),
  ];

  PurchaseCartItemModel? _initialFor(String variantId) {
    for (final item in widget.initialItems) {
      if (item.sizeColorId == variantId) return item;
    }
    return null;
  }

  Future<void> _addVariant() async {
    final option = await showDialog<PurchaseVariantOption>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PurchaseVariantCreateDialog(
        sizes: {
          ...widget.product.sizes.map((size) => size.size),
          ...drafts.map((draft) => draft.size.size),
        }.toList(),
        defaultRetailPrice: widget.product.unitPrice,
        onCreate: widget.onCreate,
      ),
    );
    if (!mounted || option == null) return;
    var added = false;
    setState(() {
      final existing =
          drafts.where((draft) => draft.variant.id == option.variant.id);
      if (existing.isNotEmpty) {
        existing.first.selected = true;
      } else {
        added = true;
        PurchaseCartItemModel? initial;
        if (drafts.isEmpty) {
          for (final item in widget.initialItems) {
            if (item.sizeColorId == null) {
              initial = item;
              break;
            }
          }
        }
        drafts.add(_VariantDraft(
          size: option.size,
          variant: option.variant,
          defaultPrice: widget.product.purchaseCost,
          initial: initial,
        )..selected = true);
      }
    });
    if (added) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final selected = drafts.where((draft) => draft.selected).toList();
    for (final draft in selected) {
      final quantity = num.tryParse(draft.quantityController.text.trim()) ?? 0;
      final price = num.tryParse(draft.priceController.text.trim()) ?? -1;
      if (quantity <= 0 || price < 0) {
        AppFailureNotice.show(
          context: context,
          title: 'خطأ',
          message: 'تأكد من الكمية وسعر الشراء',
        );
        return;
      }
    }
    Navigator.pop(
      context,
      selected
          .map(
            (draft) => PurchaseVariantSelection(
              size: draft.size,
              variant: draft.variant,
              quantity: num.parse(draft.quantityController.text.trim()),
              unitPriceText: draft.priceController.text.trim(),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.82.sh),
        margin: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
        decoration: BoxDecoration(
          color: AdminUiColors.cardBackground(context),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 6.w, 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر الأحجام والألوان',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          widget.product.nameAr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: OutlinedButton.icon(
                onPressed: _addVariant,
                icon: const Icon(Icons.add),
                label: const Text('إضافة لون أو حجم'),
              ),
            ),
            Expanded(
              child: drafts.isEmpty
                  ? const Center(child: Text('لا توجد أحجام أو ألوان'))
                  : ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      itemCount: drafts.length,
                      separatorBuilder: (_, __) => SizedBox(height: 6.h),
                      itemBuilder: (_, index) => _variantRow(drafts[index]),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, 46.h),
                ),
                child: Text(
                  'تأكيد الاختيار (${drafts.where((e) => e.selected).length})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _variantRow(_VariantDraft draft) {
    final variantImage = draft.variant.imageUrl.trim();
    final hasVariantImage = variantImage.isNotEmpty &&
        variantImage.toLowerCase() != 'no image' &&
        variantImage.toLowerCase() != 'no img';
    final imageUrls = <String>[
      if (hasVariantImage) variantImage,
      ...widget.product.allImageUrlsInPriority,
    ];
    return InkWell(
      onTap: () => setState(() => draft.selected = !draft.selected),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: draft.selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : AdminUiColors.subtleOverlay(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: draft.selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 58.w,
                height: 58.w,
                child: imageUrls.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFF3F4F6),
                        child: Icon(Icons.palette_outlined),
                      )
                    : ProductPriorityImage(
                        imageUrls: imageUrls,
                        fit: BoxFit.cover,
                        placeholder: const ColoredBox(
                          color: Color(0xFFF3F4F6),
                        ),
                        missingPlaceholder: const ColoredBox(
                          color: Color(0xFFF3F4F6),
                          child: Icon(Icons.palette_outlined),
                        ),
                      ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${draft.size.size} / ${draft.variant.colorAr}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: draft.selected,
                        onChanged: (value) =>
                            setState(() => draft.selected = value ?? false),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          draft.quantityController,
                          'الكمية',
                          () => setState(() => draft.selected = true),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _numberField(
                          draft.priceController,
                          'سعر الشراء',
                          () => setState(() => draft.selected = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    VoidCallback onChanged,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9.r)),
      ),
    );
  }
}
