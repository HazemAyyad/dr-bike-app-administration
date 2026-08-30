import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/helpers/app_button.dart';
import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/custom_text_field.dart';
import '../../../../../../core/helpers/custom_upload_button.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../../../../../../core/widgets/skeleton_loading.dart';
import '../../../data/models/expenses_models/destruction_model.dart';
import '../../controllers/expenses_controller.dart';
import '../financial_image_cache.dart';
import '../financial_media_camera.dart';
import '../financial_operational_ui.dart';

class DestructionCard extends StatelessWidget {
  const DestructionCard({Key? key, required this.data}) : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    return FinancialOperationalCard(
      onTap: () => Get.to(() => DestructionDetailsScreen(data: data)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: CachedNetworkImage(
            cacheManager: FinancialImageCache.instance,
            imageUrl: data.image.isEmpty
                ? AssetsManager.noImageNet
                : data.image.first,
            width: 36.w,
            height: 36.w,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                SkeletonBlock(width: 36.w, height: 36.w, radius: 9),
            errorWidget: (_, __, ___) => Container(
              width: 36.w,
              height: 36.w,
              color: AppColors.operationalSurface,
              child: Icon(Icons.delete_sweep_outlined,
                  size: 18.sp, color: AppColors.operationalPurple),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.operationalNavy,
                ),
              ),
              SizedBox(height: 3.h),
              Text(showData(data.createdAt),
                  style: TextStyle(
                      fontSize: 9.5.sp, color: AppColors.customGreyColor5)),
            ],
          ),
        ),
        FinancialMiniChip(
          label: '${data.piecesNumber} قطعة',
          color: AppColors.customOrange3,
          icon: Icons.numbers,
        ),
        SizedBox(width: 5.w),
        FinancialMiniChip(
          label: '${NumberFormat('#,###.##').format(data.destructionValue)} ₪',
          color: AppColors.operationalPurple,
          icon: Icons.payments_outlined,
        ),
        SizedBox(width: 2.w),
        Icon(Icons.arrow_back_ios_new_rounded,
            size: 14.sp, color: AppColors.customGreyColor5),
      ]),
    );
  }
}

class DestructionDetailsScreen extends GetView<ExpensesController> {
  const DestructionDetailsScreen({Key? key, required this.data})
      : super(key: key);

  final DestructionModel data;

  @override
  Widget build(BuildContext context) {
    final media = data.image
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final quantity = double.tryParse(data.piecesNumber) ?? 0;
    final calculatedUnitCost = data.unitCost > 0
        ? data.unitCost
        : quantity > 0
            ? data.destructionValue / quantity
            : 0.0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل البضاعة المتلفة',
        action: false,
        actions: [
          IconButton(
            tooltip: 'تعديل السبب والمرفقات',
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          SizedBox(width: 7.w),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 36.h),
        children: [
          FinancialOperationalCard(
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      color: AppColors.customOrange3.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.delete_sweep_outlined,
                        color: AppColors.customOrange3, size: 24.sp),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.productName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.operationalNavy,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'عملية إتلاف #${data.destructionId} · ${showData(data.createdAt)}',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            color: AppColors.customGreyColor5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FinancialMiniChip(
                    label:
                        '${NumberFormat('#,###.##').format(data.destructionValue)} ₪',
                    color: AppColors.operationalPurple,
                    icon: Icons.payments_outlined,
                  ),
                ]),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(
                    child: _DestructionMetric(
                      label: 'الكمية المتلفة',
                      value: '${data.piecesNumber} قطعة',
                      icon: Icons.numbers_rounded,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _DestructionMetric(
                      label: 'تكلفة القطعة',
                      value:
                          '${NumberFormat('#,###.##').format(calculatedUnitCost)} ₪',
                      icon: Icons.price_change_outlined,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: _DestructionMetric(
                      label: 'رقم المنتج',
                      value: data.productId.isEmpty ? '-' : data.productId,
                      icon: Icons.qr_code_rounded,
                    ),
                  ),
                ]),
                if (data.costMethod.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FinancialMiniChip(
                      label: _costMethodLabel(data.costMethod),
                      color: AppColors.operationalNavy,
                      icon: Icons.layers_outlined,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          const FinancialGroupTitle(title: 'سبب الإتلاف'),
          FinancialOperationalCard(
            child: Text(
              data.destructionReason.trim().isEmpty
                  ? 'لم تتم إضافة سبب للإتلاف.'
                  : data.destructionReason,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.65,
                color: data.destructionReason.trim().isEmpty
                    ? AppColors.customGreyColor5
                    : AppColors.operationalNavy,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          FinancialGroupTitle(title: 'المرفقات', count: media.length),
          if (media.isEmpty)
            const FinancialOperationalCard(
              child: Text(
                'لا توجد مرفقات لهذه العملية.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.customGreyColor5),
              ),
            )
          else
            SizedBox(
              height: 116.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final item = media[index];
                  final video = _isVideo(item);
                  return InkWell(
                    onTap: () => _openMedia(context, media, index),
                    borderRadius: BorderRadius.circular(12.r),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: video
                          ? Container(
                              width: 116.w,
                              color: AppColors.operationalNavy,
                              child: const Icon(Icons.play_circle_fill_rounded,
                                  color: Colors.white, size: 42),
                            )
                          : CachedNetworkImage(
                              cacheManager: FinancialImageCache.instance,
                              imageUrl: item,
                              width: 116.w,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  width: 116.w,
                                  color: AppColors.operationalSurface),
                              errorWidget: (_, __, ___) => Container(
                                width: 116.w,
                                color: AppColors.operationalSurface,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.operationalSurface,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.operationalPurple),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  'المنتج والكمية وتكلفة المخزون مقفلة محاسبيًا بعد تسجيل الإتلاف.',
                  style: TextStyle(
                      fontSize: 9.5.sp, color: AppColors.customGreyColor5),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _costMethodLabel(String method) {
    switch (method) {
      case 'fifo':
        return 'التكلفة حسب FIFO';
      case 'specific_layer':
        return 'طبقة تكلفة محددة';
      case 'legacy_product_price_estimate':
        return 'تكلفة تقديرية قديمة';
      default:
        return 'طريقة التكلفة: $method';
    }
  }

  bool _isVideo(String url) {
    final value = url.toLowerCase().split('?').first;
    return value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.avi') ||
        value.endsWith('.wmv') ||
        value.endsWith('.mkv') ||
        value.endsWith('.webm');
  }

  void _openMedia(BuildContext context, List<String> media, int index) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: .65),
      pageBuilder: (_, __, ___) => FullScreenZoomImage(
        imageUrl: media[index],
        imageUrls: media,
        initialIndex: index,
        downloadFolderSegments: [
          'Expenses',
          'Destruction',
          data.productName,
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final reasonController =
        TextEditingController(text: data.destructionReason);
    controller.assetsFile.clear();
    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('تعديل تفاصيل الإتلاف',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.operationalNavy)),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: reasonController,
                label: 'damageReason',
                hintText: 'damageReason',
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 4,
                maxLines: 8,
              ),
              SizedBox(height: 10.h),
              MediaUploadButton(
                customCameraCapture: () => captureFinancialMedia(),
                onFilesChanged: (files) => controller.assetsFile = files,
                title: 'إضافة مرفقات جديدة',
              ),
              SizedBox(height: 14.h),
              AppButton(
                isLoading: controller.isLoading,
                text: 'save',
                onPressed: () => controller.editDestructionDetails(
                  context,
                  destructionId: data.destructionId.toString(),
                  reason: reasonController.text,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DestructionMetric extends StatelessWidget {
  const _DestructionMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.operationalSurface,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Column(children: [
          Icon(icon, size: 17.sp, color: AppColors.operationalPurple),
          SizedBox(height: 4.h),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 8.sp, color: AppColors.customGreyColor5)),
          SizedBox(height: 2.h),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900)),
        ]),
      );
}
