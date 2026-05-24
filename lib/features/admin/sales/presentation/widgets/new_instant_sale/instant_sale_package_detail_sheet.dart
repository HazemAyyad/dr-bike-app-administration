import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/show_net_image.dart';
import '../../../../../../core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/stock/data/models/offer_package_model.dart';
import '../../utils/sales_amount_format.dart';

Future<void> showInstantSalePackageDetailSheet(
  BuildContext context,
  OfferPackageModel package,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PackageDetailSheet(package: package),
  );
}

class _PackageDetailSheet extends StatelessWidget {
  const _PackageDetailSheet({required this.package});

  final OfferPackageModel package;

  @override
  Widget build(BuildContext context) {
    final url = ShowNetImage.getThumbnailPhoto(package.image);
    final hasImage = url.isNotEmpty && package.image != 'no image';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        constraints: BoxConstraints(maxHeight: 0.75.sh),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: const Color(0xFFE65100),
                  size: 22.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'saleOfferPackage'.tr,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (hasImage) SizedBox(height: 10.h),
            Text(
              package.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            _row(
              'unitPackagePrice'.tr,
              SalesAmountFormat.displayShekel(package.price),
            ),
            _row('maxPackagesToSell'.tr, '${package.maxSellableQuantity}'),
            SizedBox(height: 10.h),
            Text(
              'items'.tr,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 6.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: package.items.length,
                separatorBuilder: (_, __) => Divider(height: 1.h),
                itemBuilder: (_, i) {
                  final item = package.items[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Text(
                      '${item.productName} × ${item.quantity}',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
