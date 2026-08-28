import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../routes/app_routes.dart';
import '../../controllers/assets_controller.dart';
import '../../widgets/financial_image_cache.dart';
import '../../widgets/financial_operational_ui.dart';
import '../../widgets/financial_skeletons.dart';

class AssetDetailsScreen extends GetView<AssetsController> {
  const AssetDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل الأصل',
        action: false,
        actions: [
          IconButton(
            tooltip: 'تعديل الأصل',
            onPressed: () {
              controller.isEditing.value = true;
              controller.editAsset();
              Get.toNamed(AppRoutes.ADDNEWASSETSCREEN);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: GetBuilder<AssetsController>(builder: (_) {
        if (controller.isLoadingDepreciate.value ||
            controller.assetDetails.value == null) {
          return const SingleChildScrollView(child: FinancialFormSkeleton());
        }
        final asset = controller.assetDetails.value!;
        final price = double.tryParse(asset.price) ?? 0;
        final rate = double.tryParse(asset.depreciationRate) ?? 0;
        final months = int.tryParse(asset.monthsNumber.split('.').first) ?? 0;
        final depreciated = asset.logs.fold<double>(
            0, (sum, log) => sum + (double.tryParse(log.total) ?? 0));
        final currentValue = (price - depreciated).clamp(0, price);
        final sortedLogs = asset.logs.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final currentPeriod = DateFormat('yyyy-MM').format(DateTime.now());
        final depreciatedThisMonth = asset.depreciatedThisMonth ||
            asset.logs.any((log) =>
                log.depreciationPeriod == currentPeriod ||
                (log.createdAt.year == DateTime.now().year &&
                    log.createdAt.month == DateTime.now().month));
        return ListView(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 40.h),
          children: [
            FinancialOperationalCard(
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      color: AppColors.operationalSurface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        color: AppColors.operationalPurple, size: 24.sp),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(asset.name,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.operationalNavy)),
                        SizedBox(height: 3.h),
                        Text(
                            'أضيف ${DateFormat('yyyy-MM-dd').format(asset.createdAt)}',
                            style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.customGreyColor5)),
                      ],
                    ),
                  ),
                  FinancialMiniChip(
                    label: '${NumberFormat('#,###.##').format(currentValue)} ₪',
                    color: AppColors.operationalPurple,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ]),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(
                      child: _AssetMetric(
                          label: 'القيمة الأصلية',
                          value:
                              '${NumberFormat('#,###.##').format(price)} ₪')),
                  SizedBox(width: 7.w),
                  Expanded(
                      child:
                          _AssetMetric(label: 'نسبة الإهلاك', value: '$rate%')),
                  SizedBox(width: 7.w),
                  Expanded(
                      child: _AssetMetric(
                          label: 'مدة الإهلاك', value: '$months شهر')),
                ]),
                SizedBox(height: 11.h),
                if (depreciatedThisMonth) ...[
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 9.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.customGreen1.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.customGreen1.withValues(alpha: .35),
                      ),
                    ),
                    child: Row(children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.customGreen1),
                      SizedBox(width: 7.w),
                      Expanded(
                        child: Text(
                          'تم تنفيذ إهلاك هذا الأصل للفترة $currentPeriod',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.customGreen1,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => FilledButton.icon(
                        onPressed:
                            controller.isLoading.value || depreciatedThisMonth
                                ? null
                                : () => controller
                                    .destructionOneAssets(asset.id.toString()),
                        icon: controller.isLoading.value
                            ? SizedBox(
                                width: 17.w,
                                height: 17.w,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Icon(depreciatedThisMonth
                                ? Icons.check_circle_rounded
                                : Icons.trending_down_rounded),
                        label: Text(depreciatedThisMonth
                            ? 'تم الإهلاك لهذا الشهر'
                            : 'تنفيذ إهلاك هذا الشهر يدويًا'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.operationalPurple,
                          disabledBackgroundColor: depreciatedThisMonth
                              ? AppColors.customGreen1
                              : null,
                          disabledForegroundColor:
                              depreciatedThisMonth ? Colors.white : null,
                        ),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    'يسمح النظام بعملية واحدة فقط لكل أصل في الشهر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 9.sp, color: AppColors.customGreyColor5),
                  ),
                ),
              ]),
            ),
            if ((asset.notes ?? '').trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              const FinancialGroupTitle(title: 'ملاحظات الأصل'),
              FinancialOperationalCard(
                child: Text(asset.notes!,
                    style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.6,
                        color: AppColors.operationalNavy)),
              ),
            ],
            SizedBox(height: 10.h),
            FinancialGroupTitle(title: 'صور الأصل', count: asset.media.length),
            if (asset.media.isNotEmpty)
              SizedBox(
                height: 105.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: asset.media.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) => InkWell(
                    onTap: () => showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: 'Dismiss',
                      pageBuilder: (_, __, ___) => FullScreenZoomImage(
                        imageUrl: asset.media[index],
                        imageUrls: asset.media,
                        downloadFolderSegments: ['Assets', asset.name],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11.r),
                      child: CachedNetworkImage(
                        cacheManager: FinancialImageCache.instance,
                        imageUrl: asset.media[index],
                        width: 105.w,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 105.w, color: AppColors.operationalSurface),
                        errorWidget: (_, __, ___) => Container(
                            width: 105.w,
                            color: AppColors.operationalSurface,
                            child: const Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                ),
              )
            else
              const FinancialOperationalCard(
                  child: Text('لا توجد صور',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.customGreyColor5))),
            SizedBox(height: 10.h),
            FinancialGroupTitle(title: 'سجل الإهلاك', count: asset.logs.length),
            if (asset.logs.isEmpty)
              const FinancialOperationalCard(
                  child: Text('لم يتم تسجيل إهلاك لهذا الأصل بعد',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.customGreyColor5)))
            else
              ...sortedLogs.map((log) => FinancialOperationalCard(
                    child: Row(children: [
                      Icon(Icons.history_rounded,
                          color: AppColors.operationalPurple, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(log.type.isEmpty ? 'إهلاك شهري' : log.type,
                                style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.operationalNavy)),
                            Text(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(log.createdAt),
                                style: TextStyle(
                                    fontSize: 9.sp,
                                    color: AppColors.customGreyColor5)),
                          ])),
                      FinancialMiniChip(
                          label: '${log.total} ₪',
                          color: AppColors.operationalPurple),
                    ]),
                  )),
          ],
        );
      }),
    );
  }
}

class _AssetMetric extends StatelessWidget {
  const _AssetMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
        decoration: BoxDecoration(
            color: AppColors.operationalSurface,
            borderRadius: BorderRadius.circular(9.r)),
        child: Column(children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 8.sp, color: AppColors.customGreyColor5)),
          SizedBox(height: 3.h),
          Text(value,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.operationalNavy)),
        ]),
      );
}
