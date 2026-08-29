import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../admin_dashbord/presentation/widgets/stat_card.dart';
import '../../controllers/assets_controller.dart';
import '../../controllers/finacial_service.dart';

class AssetsData extends StatelessWidget {
  const AssetsData({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 24.w),
        child: GetBuilder<AssetsController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.r),
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          show: true,
                          title: 'totalAssets',
                          imageicon: AssetsManager.cashIcon,
                          value: NumberFormat('#,###').format(
                            double.parse(FinacialService()
                                .assets
                                .value!
                                .totalAssetsOriginalPrices),
                          ),
                          subtitle: '',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: StatCard(
                          show: true,
                          title: 'averageConsumptionRatio',
                          imageicon: AssetsManager.percentageIcon2,
                          value:
                              '${FinacialService().assets.value!.averageDepreciationRate.toStringAsFixed(5)}%',
                          subtitle: '',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AssetsConsumption extends StatefulWidget {
  const AssetsConsumption({Key? key}) : super(key: key);

  @override
  State<AssetsConsumption> createState() => _AssetsConsumptionState();
}

class _AssetsConsumptionState extends State<AssetsConsumption> {
  AssetsController get controller => Get.find<AssetsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.loadDepreciationPreview(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 28.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      backgroundColor: ThemeService.isDark.value
          ? AppColors.blackColor
          : AppColors.whiteColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620.w, maxHeight: 720.h),
        child: Obx(() {
          if (controller.isLoadingDepreciationPreview.value) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final preview = controller.depreciationPreview.value;
          if (preview == null) {
            return Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded,
                    size: 42, color: Colors.redAccent),
                SizedBox(height: 12.h),
                const Text('تعذر تحميل معاينة الإهلاك'),
                TextButton(
                  onPressed: controller.loadDepreciationPreview,
                  child: const Text('إعادة المحاولة'),
                ),
              ]),
            );
          }
          final summary = preview.summary;
          return Column(children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
              ),
              child: Row(children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.auto_graph_rounded, color: Colors.white),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('معاينة إهلاك الأصول',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('الفترة ${preview.period} • راجع القيم قبل التنفيذ',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(onPressed: Get.back, icon: const Icon(Icons.close)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(children: [
                _PreviewMetric(
                    label: 'سيتم إهلاكها', value: '${summary.eligibleCount}'),
                SizedBox(width: 7.w),
                _PreviewMetric(
                    label: 'تم تجاوزها', value: '${summary.skippedCount}'),
                SizedBox(width: 7.w),
                _PreviewMetric(
                    label: 'قيمة الإهلاك',
                    value: NumberFormat('#,##0.00')
                        .format(summary.depreciationAmount),
                    highlighted: true),
              ]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(11.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: .25)),
                ),
                child: Text(
                  'إجمالي القيمة: ${NumberFormat('#,##0.00').format(summary.valueBefore)}  ←  ${NumberFormat('#,##0.00').format(summary.valueAfter)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: preview.assets.isEmpty
                  ? const Center(
                      child: Text('لا توجد أصول مستحقة للإهلاك هذا الشهر'))
                  : ListView.separated(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      itemCount: preview.assets.length,
                      separatorBuilder: (_, __) => SizedBox(height: 7.h),
                      itemBuilder: (_, index) {
                        final asset = preview.assets[index];
                        return Container(
                          padding: EdgeInsets.all(11.r),
                          decoration: BoxDecoration(
                            color: ThemeService.isDark.value
                                ? AppColors.customGreyColor
                                : AppColors.whiteColor2,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.primaryColor.withValues(alpha: .12),
                              child: const Icon(Icons.precision_manufacturing,
                                  color: AppColors.primaryColor),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(asset.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    '${NumberFormat('#,##0.00').format(asset.valueBefore)} ← ${NumberFormat('#,##0.00').format(asset.valueAfter)}',
                                  ),
                                ],
                              ),
                            ),
                            Column(children: [
                              Text('${asset.depreciationRate}%'),
                              Text(
                                '-${NumberFormat('#,##0.00').format(asset.depreciationAmount)}',
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ]),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 5.h, 14.w, 14.h),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: Get.back,
                    child: const Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: Obx(() => ElevatedButton.icon(
                        onPressed: summary.eligibleCount == 0 ||
                                controller.isLoadingDepreciate.value
                            ? null
                            : controller.depreciateAssets,
                        icon: controller.isLoadingDepreciate.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('تنفيذ إهلاك الشهر'),
                      )),
                ),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.primaryColor.withValues(alpha: .12)
                : ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : AppColors.whiteColor2,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Column(children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highlighted ? AppColors.primaryColor : null)),
            SizedBox(height: 3.h),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}
