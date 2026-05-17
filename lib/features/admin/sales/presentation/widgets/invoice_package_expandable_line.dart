import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/invoice_model.dart';
import 'proudact_details_widget.dart';

/// Invoice line for offer-package sales: collapsible header + component products.
class InvoicePackageExpandableLine extends StatefulWidget {
  const InvoicePackageExpandableLine({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  final InvoiceModel invoice;

  @override
  State<InvoicePackageExpandableLine> createState() =>
      _InvoicePackageExpandableLineState();
}

class _InvoicePackageExpandableLineState
    extends State<InvoicePackageExpandableLine> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final accent = ThemeService.isDark.value
        ? AppColors.primaryColor
        : AppColors.secondaryColor;
    final cardBg = ThemeService.isDark.value
        ? AppColors.customGreyColor
        : AppColors.whiteColor2;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 4.w, 8.h),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: accent,
                    size: 26.sp,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'saleTypeOfferPackage'.tr,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          invoice.displayProductTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                  ),
                        ),
                        if (!_expanded && invoice.subProducts.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              'packageContentsCount'.trParams({
                                'count': '${invoice.subProducts.length}',
                              }),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.customGreyColor2,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52.w,
                    child: Text(
                      invoice.quantity,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 52.w,
                    child: Text(
                      invoice.cost,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12.sp,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 56.w,
                    child: Text(
                      invoice.subtotal,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: accent.withValues(alpha: 0.2)),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 4.h),
              child: Text(
                'packageContents'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
              ),
            ),
            ...invoice.subProducts.map(
              (sub) => Padding(
                padding: EdgeInsets.only(left: 8.w, right: 4.w, bottom: 6.h),
                child: ProudactDetailsWidget(
                  dense: true,
                  image: sub.productImage,
                  cost: sub.cost,
                  product: sub.productName,
                  quantity: sub.quantity,
                  subtotal: sub.subtotal,
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ],
      ),
    );
  }
}
