import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../models/instant_sale_cart_line.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/product_image_viewer.dart';
import '../../utils/sales_amount_format.dart';

Future<void> showInstantSaleAddProductModal(
  BuildContext context, {
  InstantSaleCartLine? editLine,
  int? editIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _AddProductSheet(editLine: editLine, editIndex: editIndex),
  );
}

class _AddProductSheet extends StatefulWidget {
  final InstantSaleCartLine? editLine;
  final int? editIndex;

  const _AddProductSheet({this.editLine, this.editIndex});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final SalesController controller = Get.find<SalesController>();
  final _formKey = GlobalKey<FormState>();

  ProductModel? _selected;
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _isProject = false.obs;
  final _projectId = RxnString();
  final _lineTotal = 0.0.obs;

  bool get _isEdit => widget.editLine != null;

  @override
  void initState() {
    super.initState();
    if (widget.editLine != null) {
      final line = widget.editLine!;
      _selected = controller.products.firstWhereOrNull(
        (p) => p.id == line.productId,
      );
      _qtyController.text = line.quantityController.text;
      _priceController.text = line.priceController.text;
      _isProject.value = line.isProjectSale.value;
      _projectId.value = line.projectId.value;
    }
    _qtyController.addListener(_recalc);
    _priceController.addListener(_recalc);
    _recalc();
  }

  void _recalc() {
    final qty = SalesAmountFormat.parse(_qtyController.text);
    final price = SalesAmountFormat.parse(_priceController.text);
    _lineTotal.value = qty * price;
  }

  void _onProductSelected(ProductModel? product) {
    setState(() {
      _selected = product;
      if (product != null && product.unitPrice > 0) {
        _priceController.text =
            product.unitPrice == product.unitPrice.roundToDouble()
                ? product.unitPrice.toInt().toString()
                : product.unitPrice.toStringAsFixed(2);
      }
    });
    _recalc();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.92.sh),
          margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor4 : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEdit
                              ? 'instantSaleEditProduct'.tr
                              : 'instantSaleAddProduct'.tr,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade300),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownSearch<ProductModel>(
                          selectedItem: _selected,
                          items: (filter, _) {
                            if (filter.trim().isEmpty) {
                              return controller.products;
                            }
                            final q = filter.trim().toLowerCase();
                            return controller.products
                                .where((p) =>
                                    p.nameAr.toLowerCase().contains(q) ||
                                    p.id.contains(q))
                                .toList();
                          },
                          itemAsString: (p) =>
                              '${p.nameAr} (${'stock'.tr}: ${p.stock})',
                          compareFn: (a, b) => a.id == b.id,
                          onChanged: _onProductSelected,
                          validator: (v) =>
                              v == null ? 'instantSaleSelectProduct'.tr : null,
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'instantSaleSelectProduct'.tr,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.customGreyColor
                                  : AppColors.whiteColor2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11.r),
                              ),
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            itemBuilder: (ctx, item, isDisabled, isSelected) {
                              return _ProductPickerTile(product: item);
                            },
                          ),
                        ),
                        if (_selected != null) ...[
                          SizedBox(height: 14.h),
                          _SelectedProductPreview(product: _selected!),
                        ],
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                isRequired: true,
                                label: 'quantity',
                                hintText: '1',
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                isRequired: true,
                                label: 'price',
                                hintText: '0',
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Obx(
                          () => Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'total'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                Text(
                                  SalesAmountFormat.display(_lineTotal.value),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: CustomCheckBox(
                                  title: 'instantSale'.tr,
                                  value: RxBool(!_isProject.value),
                                  onChanged: (_) {
                                    _isProject.value = false;
                                    _projectId.value = null;
                                  },
                                ),
                              ),
                              Expanded(
                                child: CustomCheckBox(
                                  title: 'saleForProject'.tr,
                                  value: _isProject,
                                  onChanged: (_) => _isProject.value = true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(() {
                          if (!_isProject.value || _selected == null) {
                            return const SizedBox.shrink();
                          }
                          final projectIds = _selected!.projects
                              .map((id) => id.toString())
                              .toList();
                          return Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: DropdownButtonFormField<String>(
                              value: _projectId.value,
                              decoration: InputDecoration(
                                labelText: 'projectName'.tr,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                              ),
                              items: controller.ongoingProjects
                                  .where((proj) =>
                                      projectIds.contains(proj.id.toString()))
                                  .map(
                                    (proj) => DropdownMenuItem(
                                      value: proj.id.toString(),
                                      child: Text(proj.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => _projectId.value = v,
                              validator: (v) => _isProject.value && v == null
                                  ? 'projectName'.tr
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        _isEdit ? 'save'.tr : 'add'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selected == null) {
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty < 1) {
      Get.snackbar('error'.tr, 'quantity'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final stock = int.tryParse(_selected!.stock) ?? 0;
    final ok = await controller.confirmInstantSaleNegativeStockIfNeeded(
      context: context,
      productName: _selected!.nameAr,
      stock: stock,
      requestedQty: qty,
    );
    if (!mounted) return;
    if (!ok) {
      return;
    }

    final line = InstantSaleCartLine.fromProduct(
      _selected!,
      quantity: _qtyController.text.trim(),
      unitPrice: _priceController.text.trim(),
      projectSale: _isProject.value,
      projectId: _projectId.value,
    );

    if (_isEdit && widget.editIndex != null) {
      controller.updateCartLine(widget.editIndex!, line);
    } else {
      controller.addCartLine(line);
    }

    Navigator.pop(context);
  }
}

class _ProductPickerTile extends StatelessWidget {
  final ProductModel product;

  const _ProductPickerTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _ProductThumb(
        context: context,
        imageUrl: product.imageUrl,
        size: 44,
      ),
      title: Text(
        product.nameAr,
        softWrap: true,
      ),
      subtitle: Text(
        '${'stock'.tr}: ${product.stock} · ${SalesAmountFormat.display(product.unitPrice)}',
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }
}

class _SelectedProductPreview extends StatelessWidget {
  final ProductModel product;

  const _SelectedProductPreview({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProductThumb(
          context: context,
          imageUrl: product.imageUrl,
          size: 72,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.nameAr,
                softWrap: true,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.sp,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${'stock'.tr}: ${product.stock}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
              ),
              Text(
                '${'price'.tr}: ${SalesAmountFormat.display(product.unitPrice)}',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final BuildContext context;
  final String imageUrl;
  final double size;

  const _ProductThumb({
    required this.context,
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ShowNetImage.getThumbnailPhoto(imageUrl);
    final hasImage = resolved.isNotEmpty && imageUrl != 'no image';

    return GestureDetector(
      onTap: hasImage ? () => openProductImageViewer(context, imageUrl) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: size.w,
          height: size.w,
          color: Colors.grey.shade200,
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: resolved,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.inventory_2_outlined,
                    size: size * 0.45,
                    color: Colors.grey,
                  ),
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  size: size * 0.45,
                  color: Colors.grey,
                ),
        ),
      ),
    );
  }
}
