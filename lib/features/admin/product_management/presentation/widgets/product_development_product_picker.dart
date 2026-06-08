import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/product_priority_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../sales/data/models/product_model.dart';
import '../../../sales/presentation/utils/product_image_viewer.dart';

class ProductDevelopmentProductPicker extends StatelessWidget {
  const ProductDevelopmentProductPicker({
    Key? key,
    required this.products,
    required this.selectedProduct,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel> onChanged;
  final FormFieldValidator<ProductModel>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'productName'.tr,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor6
                    : AppColors.customGreyColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
              ),
        ),
        SizedBox(height: 10.h),
        DropdownSearch<ProductModel>(
          selectedItem: selectedProduct,
          items: (filter, _) {
            if (filter.trim().isEmpty) {
              return products;
            }
            final query = filter.trim().toLowerCase();
            return products
                .where(
                  (product) =>
                      product.nameAr.toLowerCase().contains(query) ||
                      product.id.contains(query),
                )
                .toList();
          },
          itemAsString: (product) => product.nameAr,
          compareFn: (a, b) => a.id == b.id,
          validator: validator,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              filled: true,
              fillColor: ThemeService.isDark.value
                  ? AppColors.customGreyColor
                  : AppColors.whiteColor2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              labelText: 'itemExample'.tr,
              labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor2
                        : AppColors.customGreyColor6,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          dropdownBuilder: (context, selectedItem) {
            if (selectedItem == null) {
              return Text(
                'itemExample'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.customGreyColor6,
                      fontSize: 16.sp,
                    ),
              );
            }
            return _ProductPickerRow(product: selectedItem, compact: true);
          },
          popupProps: PopupProps.menu(
            showSearchBox: true,
            constraints: BoxConstraints(maxHeight: 0.55.sh),
            itemBuilder: (context, item, isDisabled, isSelected) {
              return _ProductPickerRow(
                product: item,
                compact: false,
                isSelected: isSelected,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductPickerRow extends StatelessWidget {
  const _ProductPickerRow({
    required this.product,
    required this.compact,
    this.isSelected = false,
  });

  final ProductModel product;
  final bool compact;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final thumbSize = compact ? 34.0 : 44.0;

    return Container(
      color: isSelected
          ? AppColors.primaryColor.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 12.w,
        vertical: compact ? 0 : 6.h,
      ),
      child: Row(
        children: [
          _ProductThumb(
            imageUrls: product.allImageUrlsInPriority,
            size: thumbSize,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nameAr,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 15.sp : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: ThemeService.isDark.value
                        ? AppColors.whiteColor
                        : AppColors.secondaryColor,
                  ),
                ),
                if (!compact) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '${'stock'.tr}: ${product.stock}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.customGreyColor5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.imageUrls,
    required this.size,
  });

  final List<String> imageUrls;
  final double size;

  @override
  Widget build(BuildContext context) {
    final previewUrl = imageUrls.isNotEmpty ? imageUrls.first : '';

    return GestureDetector(
      onTap: previewUrl.isNotEmpty
          ? () => openProductImageViewer(context, previewUrl)
          : null,
      child: ProductPriorityImage(
        imageUrls: imageUrls,
        width: size.w,
        height: size.w,
        borderRadius: BorderRadius.circular(6.r),
        placeholder: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        missingPlaceholder: Image.asset(
          AssetsManager.stockImage,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
