import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/instant_sales_model.dart';
import '../../data/models/invoice_model.dart';
import '../controllers/sales_controller.dart';
import '../utils/instant_sale_display.dart';
import '../utils/product_image_viewer.dart';
import '../utils/sales_amount_format.dart';
import 'instant_sale_audit_info.dart';

void showInstantSaleLinesModal(BuildContext context, InstantSalesModel sale) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _InstantSaleLinesSheet(sale: sale),
  );
}

class _InstantSaleLinesSheet extends StatefulWidget {
  final InstantSalesModel sale;

  const _InstantSaleLinesSheet({required this.sale});

  @override
  State<_InstantSaleLinesSheet> createState() => _InstantSaleLinesSheetState();
}

class _InstantSaleLinesSheetState extends State<_InstantSaleLinesSheet> {
  InvoiceModel? _invoice;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final controller = Get.find<SalesController>();
      final invoice = await controller.invoiceModelUsecase.call(
        invoiceId: widget.sale.id.toString(),
      );
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'failed'.tr;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final sale = widget.sale;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor4 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'instantSaleInvoice'.tr} ${sale.invoiceNumber}',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${sale.partnerTypeDisplay} · ${sale.partnerName}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
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
            Divider(height: 1, color: Colors.grey.shade300),
            InstantSaleAuditInfo(sale: sale),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadInvoice,
                      child: Text('tryAgain'.tr),
                    ),
                  ],
                ),
              )
            else
              Flexible(child: _buildLinesList(_invoice!, sale)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                  Text(
                    SalesAmountFormat.display(
                      SalesAmountFormat.parse(sale.totalCost),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesList(InvoiceModel invoice, InstantSalesModel sale) {
    final rows = <Widget>[];

    rows.add(_LineRow(
      context: context,
      imageUrl: invoice.productImage,
      name: invoice.displayProductTitle,
      quantity: invoice.quantity,
      unitPrice: invoice.cost,
      badge: invoice.isPackageSale ? 'saleTypeOfferPackage'.tr : null,
    ));

    for (final sub in invoice.subProducts) {
      rows.add(Divider(height: 1, color: Colors.grey.shade200));
      rows.add(_LineRow(
        context: context,
        imageUrl: sub.productImage,
        name: sub.productName,
        quantity: sub.quantity,
        unitPrice: sub.cost,
        isPackageComponent: invoice.isPackageSale,
      ));
    }

    if (rows.isEmpty && !invoice.isPackageSale) {
      for (final line in sale.lineItems) {
        rows.add(_LineRow(
          context: context,
          imageUrl: '',
          name: line.name,
          quantity: line.quantity,
          unitPrice: line.unitCost,
          badge: line.isPackageHeader ? 'saleTypeOfferPackage'.tr : null,
        ));
      }
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: rows,
    );
  }
}

class _LineRow extends StatelessWidget {
  final BuildContext context;
  final String imageUrl;
  final String name;
  final String quantity;
  final String unitPrice;
  final String? badge;
  final bool isPackageComponent;

  const _LineRow({
    required this.context,
    required this.imageUrl,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.badge,
    this.isPackageComponent = false,
  });

  @override
  Widget build(BuildContext context) {
    final qty = SalesAmountFormat.parse(quantity);
    final unit = SalesAmountFormat.parse(unitPrice);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImageThumb(context: context, imageUrl: imageUrl),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ),
                if (isPackageComponent)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      'saleTypeOfferPackage'.tr,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                Text(
                  name,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '${'quantity'.tr}: ${SalesAmountFormat.display(qty)} · '
                  '${'price'.tr}: ${SalesAmountFormat.display(unit)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageThumb extends StatelessWidget {
  final BuildContext context;
  final String imageUrl;

  const _ProductImageThumb({
    required this.context,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ShowNetImage.getThumbnailPhoto(imageUrl);
    final original = ShowNetImage.getPhoto(imageUrl);
    final hasImage = resolved.isNotEmpty &&
        imageUrl.trim().isNotEmpty &&
        imageUrl != 'no image';

    return GestureDetector(
      onTap: hasImage ? () => openProductImageViewer(context, imageUrl) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 64.w,
          height: 64.w,
          color: Colors.grey.shade200,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: resolved,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) {
                        if (original != resolved && original.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: original,
                            fit: BoxFit.cover,
                          );
                        }
                        return Icon(
                          Icons.inventory_2_outlined,
                          size: 28.sp,
                          color: Colors.grey,
                        );
                      },
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.zoom_in,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  size: 28.sp,
                  color: Colors.grey,
                ),
        ),
      ),
    );
  }
}
