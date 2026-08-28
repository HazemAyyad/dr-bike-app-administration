import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../data/models/assets_models/assets_data_model.dart';
import '../../controllers/assets_controller.dart';
import '../financial_operational_ui.dart';
import '../financial_image_cache.dart';
import '../official_papers_widgets/cancel_file_dialog.dart';

class AssetsCard extends GetView<AssetsController> {
  const AssetsCard({Key? key, required this.asset}) : super(key: key);
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final original = double.tryParse(asset.originalPrice) ?? 0;
    final book = double.tryParse(asset.depreciationPrice) ?? 0;
    final progress =
        original <= 0 ? 0.0 : ((original - book) / original).clamp(0.0, 1.0);
    final depreciatedThisMonth = asset.depreciatedThisMonth;
    return FinancialOperationalCard(
      backgroundColor: depreciatedThisMonth
          ? AppColors.customGreen1.withValues(alpha: .055)
          : null,
      borderColor: depreciatedThisMonth
          ? AppColors.customGreen1.withValues(alpha: .5)
          : null,
      onTap: () {
        controller.isEditing.value = false;
        controller.getAssetsDetials(assetId: asset.assetId.toString());
        Get.toNamed(AppRoutes.ASSETDETAILSSCREEN);
      },
      onLongPress: () => Get.dialog(CancelFileDialog(
          fileName: asset.name, assetId: asset.assetId.toString())),
      child: Column(children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: CachedNetworkImage(
              cacheManager: FinancialImageCache.instance,
              imageUrl: asset.image,
              width: 36.w,
              height: 36.w,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  SkeletonBlock(width: 36.w, height: 36.w, radius: 10),
              errorWidget: (_, __, ___) => Container(
                  width: 36.w,
                  height: 36.w,
                  color: AppColors.operationalSurface,
                  child: Icon(Icons.inventory_2_outlined,
                      color: AppColors.operationalPurple, size: 20.sp)),
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.operationalNavy)),
                SizedBox(height: 3.h),
                Text(showData(asset.createdAt),
                    style: TextStyle(
                        fontSize: 10.sp, color: AppColors.customGreyColor5)),
                if (depreciatedThisMonth) ...[
                  SizedBox(height: 3.h),
                  FinancialMiniChip(
                    label: asset.depreciationPeriod.isEmpty
                        ? 'تم إهلاك هذا الشهر'
                        : 'تم إهلاك ${asset.depreciationPeriod}',
                    color: AppColors.customGreen1,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ])),
          FinancialMiniChip(
              label: '${NumberFormat('#,###').format(book)} ₪',
              color: AppColors.operationalPurple,
              icon: Icons.account_balance_wallet_outlined),
        ]),
        SizedBox(height: 5.h),
        Row(children: [
          FinancialMiniChip(
              label: 'الأصل ${NumberFormat('#,###').format(original)} ₪',
              color: AppColors.operationalNavy),
          SizedBox(width: 5.w),
          FinancialMiniChip(
              label: '${asset.depreciationRate}%',
              color: progress >= 1
                  ? AppColors.customGreen1
                  : AppColors.customOrange3,
              icon: Icons.trending_down),
          const Spacer(),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.operationalPurple)),
        ]),
        SizedBox(height: 4.h),
        ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 3.h,
                backgroundColor: AppColors.operationalSurface,
                color: depreciatedThisMonth
                    ? AppColors.customGreen1
                    : AppColors.operationalPurple)),
      ]),
    );
  }
}
