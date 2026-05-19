import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../controllers/sales_controller.dart';
import '../../utils/product_image_viewer.dart';
import '../../utils/sales_amount_format.dart';
import 'instant_sale_add_product_modal.dart';

class InstantSaleCartTable extends GetView<SalesController> {
  const InstantSaleCartTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.cartLines.isEmpty) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            'instantSaleCartEmpty'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
          ),
        );
      }

      final isDark = ThemeService.isDark.value;
      final headerBg = isDark
          ? AppColors.customGreyColor
          : const Color(0xFFEEF4FF);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _headerCell('item', 5, alignStart: true),
                _headerCell('quantity', 2),
                _headerCell('price', 2),
                _headerCell('total', 2),
                SizedBox(width: 32.w),
              ],
            ),
          ),
          ...List.generate(controller.cartLines.length, (index) {
            final line = controller.cartLines[index];
            return Obx(
              () => Material(
                color: isDark ? AppColors.customGreyColor4 : Colors.white,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _thumb(context, line.imageUrl),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                line.productName,
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _numericCell(line.quantityController.text),
                      ),
                      Expanded(
                        flex: 2,
                        child: _numericCell(line.priceController.text),
                      ),
                      Expanded(
                        flex: 2,
                        child: _numericCell(
                          SalesAmountFormat.display(line.lineTotal.value),
                          highlight: true,
                        ),
                      ),
                      _lineMenu(
                        context: context,
                        onEdit: () => showInstantSaleAddProductModal(
                          context,
                          editLine: line,
                          editIndex: index,
                        ),
                        onDelete: () => controller.removeCartLine(index),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _headerCell(String key, int flex, {bool alignStart = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        key.tr,
        textAlign: alignStart ? TextAlign.start : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _numericCell(String text, {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h, left: 1.w, right: 1.w),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.primaryColor : null,
          ),
        ),
      ),
    );
  }

  Widget _lineMenu({
    required BuildContext context,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return SizedBox(
      width: 32.w,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 18.sp,
        splashRadius: 18.r,
        constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
        icon: Icon(Icons.more_vert, size: 18.sp, color: Colors.grey.shade700),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Text(
            'edit'.tr,
            style: TextStyle(fontSize: 13.sp, color: Colors.black87),
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            'delete'.tr,
            style: TextStyle(fontSize: 13.sp, color: Colors.red),
          ),
        ),
      ],
      ),
    );
  }

  Widget _thumb(BuildContext context, String imageUrl) {
    final url = ShowNetImage.getThumbnailPhoto(imageUrl);
    final ok = url.isNotEmpty && imageUrl != 'no image';

    return GestureDetector(
      onTap: () => openProductImageViewer(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          width: 32.w,
          height: 32.w,
          color: Colors.grey.shade200,
          child: ok
              ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
              : Icon(
                  Icons.inventory_2_outlined,
                  size: 18.sp,
                  color: Colors.grey,
                ),
        ),
      ),
    );
  }
}
