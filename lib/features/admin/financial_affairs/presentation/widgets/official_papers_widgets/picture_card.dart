import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../data/models/official_papers_models/pictures_model.dart';

class PictureCard extends StatelessWidget {
  const PictureCard({Key? key, required this.data}) : super(key: key);

  final PictureModel data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.r),
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(5.r),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9.r),
              child: CachedNetworkImage(
                imageUrl: data.file,
                fit: BoxFit.cover,
                // height: 75.h,
                // width: 70.w,
                errorWidget: (context, url, error) =>
                    Image.network(AssetsManager.noImageNet),
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Flexible(
            child: Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    // color: ThemeService.isDark.value
                    //     ? AppColors.whiteColor
                    //     : AppColors.blackColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              data.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppColors.graywhiteColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
