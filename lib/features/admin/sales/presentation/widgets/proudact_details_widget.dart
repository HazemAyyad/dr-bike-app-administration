import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';

class ProudactDetailsWidget extends StatelessWidget {
  const ProudactDetailsWidget({
    Key? key,
    required this.product,
    required this.cost,
    required this.quantity,
    required this.image,
  }) : super(key: key);

  final String image;
  final String product;
  final String cost;
  final String quantity;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 5.h),
      height: 40.h,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.customGreyColor6,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: Row(
              children: [
                ClipRRect(
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
                          return FullScreenZoomImage(imageUrl: image);
                        },
                      );
                    },
                    child: CachedNetworkImage(
                      imageUrl: image,
                      height: 30.h,
                      width: 30.w,
                      fit: BoxFit.fill,
                      fadeInDuration: const Duration(milliseconds: 200),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
                SizedBox(width: 5.w),
                Flexible(
                  child: SizedBox(
                    width: 150.w,
                    child: Text(
                      product,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 12.sp,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50.w,
            child: Text(
              quantity,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                  ),
            ),
          ),
          SizedBox(
            width: 70.w,
            child: Text(
              cost,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 12.sp,
                  ),
            ),
          ),
          SizedBox(
            width: 50.w,
            child: Text(
              (int.parse(cost) * int.parse(quantity)).toString(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
