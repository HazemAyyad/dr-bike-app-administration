import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/show_net_image.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';

class ProudactDetailsWidget extends StatelessWidget {
  const ProudactDetailsWidget({
    Key? key,
    required this.product,
    required this.cost,
    required this.quantity,
    required this.image,
    this.subtotal,
    this.dense = false,
  }) : super(key: key);

  final String image;
  final String product;
  final String cost;
  final String quantity;
  final String? subtotal;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final resolved = ShowNetImage.getThumbnailPhoto(image);
    final original = ShowNetImage.getPhoto(image);
    final missing =
        resolved == AssetsManager.noImageNet || image.isEmpty || image == 'no image';

    final lineTotal = subtotal ??
        ((double.tryParse(cost) ?? 0) * (double.tryParse(quantity) ?? 0))
            .toString();

    return Container(
      margin: dense
          ? EdgeInsets.only(bottom: 4.h)
          : EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.customGreyColor6,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          _ProductThumb(
            resolved: resolved,
            original: original,
            missing: missing,
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: Text(
              product,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              quantity,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.sp,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              cost,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.sp,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              lineTotal,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.resolved,
    required this.original,
    required this.missing,
  });

  final String resolved;
  final String original;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    if (missing) {
      return Image.asset(
        AssetsManager.stockImage,
        height: 48.h,
        width: 48.w,
        fit: BoxFit.cover,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5.r),
      child: GestureDetector(
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            barrierColor: Colors.black.withAlpha(128),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) {
              return FullScreenZoomImage(imageUrl: original);
            },
          );
        },
        child: CachedNetworkImage(
          height: 48.h,
          width: 48.w,
          fit: BoxFit.cover,
          cacheManager: CacheManager(
            Config(
              'imagesCache',
              stalePeriod: const Duration(days: 7),
              maxNrOfCacheObjects: 100,
            ),
          ),
          imageUrl: resolved,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            height: 48.h,
            width: 48.w,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => CachedNetworkImage(
            imageUrl: original,
            height: 48.h,
            width: 48.w,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Image.asset(
              AssetsManager.stockImage,
              height: 48.h,
              width: 48.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
