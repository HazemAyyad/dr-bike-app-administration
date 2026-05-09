import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../controllers/employee_section_controller.dart';

/// يحمّل السجل مرة واحدة عند الفتح (لا يعيد بناء [Future] مع كل إعادة بناء كـ Stateless).
class QrHistoryScreen extends StatefulWidget {
  const QrHistoryScreen({Key? key}) : super(key: key);

  @override
  State<QrHistoryScreen> createState() => _QrHistoryScreenState();
}

class _QrHistoryScreenState extends State<QrHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<EmployeeSectionController>().loadQrHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeSectionController>();

    return Scaffold(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      appBar: AppBar(
        title: Text('barcodeHistory'.tr),
      ),
      body: Obx(() {
        if (controller.isQrHistoryLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = controller.employeeService.qrHistory;
        if (items.isEmpty) {
          return Center(
            child: Text(
              'noData'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final it = items[index];
            return InkWell(
              onTap: it.qrImageUrl == null
                  ? null
                  : () => Get.to(
                        () => FullScreenZoomImage(imageUrl: it.qrImageUrl!),
                      ),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ThemeService.isDark.value
                      ? AppColors.darkColor.withValues(alpha: 0.6)
                      : AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72.w,
                      height: 72.w,
                      child: it.qrImageUrl == null
                          ? Container(
                              color: Colors.white,
                              child: const Icon(Icons.qr_code_2),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                it.qrImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white,
                                  child: const Icon(Icons.qr_code_2),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.codeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            it.createdAt?.toLocal().toString() ?? '—',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (it.qrImageUrl != null) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.open_in_full,
                        size: 18.sp,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
