import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../../core/helpers/showtime.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../data/models/official_papers_models/papers_model.dart';
import '../../controllers/official_papers_controller.dart';
import '../../widgets/financial_image_cache.dart';
import '../../widgets/financial_operational_ui.dart';
import '../../widgets/official_papers_widgets/add_paper.dart';

class PaperDetailsScreen extends GetView<OfficialPapersController> {
  const PaperDetailsScreen({Key? key, required this.paper}) : super(key: key);
  final PaperModel paper;

  @override
  Widget build(BuildContext context) {
    final images = paper.img.where((item) => item.trim().isNotEmpty).toList();
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تفاصيل الورقة الرسمية',
        action: false,
        actions: [
          IconButton(
            tooltip: 'تعديل الورقة',
            onPressed: () {
              controller.isEdit = true;
              controller.getPaperData(paper: paper);
              Get.dialog(const AddPaper());
            },
            icon: const Icon(Icons.edit_document),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 40.h),
        children: [
          FinancialOperationalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                        color: AppColors.operationalSurface,
                        borderRadius: BorderRadius.circular(12.r)),
                    child: Icon(Icons.description_outlined,
                        color: AppColors.operationalPurple, size: 24.sp),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paper.paperName,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.operationalNavy)),
                        Text(showData(paper.createdAt),
                            style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.customGreyColor5)),
                      ],
                    ),
                  ),
                  FinancialMiniChip(
                      label: '${images.length}',
                      color: AppColors.operationalPurple,
                      icon: Icons.attach_file_rounded),
                ]),
                SizedBox(height: 13.h),
                const Text('الموقع الدقيق',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 7.h),
                _LocationStep(
                    number: '1',
                    label: 'الخزنة',
                    value: paper.treasuryName,
                    icon: Icons.account_balance_outlined),
                _connector(),
                _LocationStep(
                    number: '2',
                    label: 'صندوق الملفات',
                    value: paper.fileBoxName,
                    icon: Icons.inventory_2_outlined),
                _connector(),
                _LocationStep(
                    number: '3',
                    label: 'الملف',
                    value: paper.fileName,
                    icon: Icons.folder_outlined),
              ],
            ),
          ),
          if (paper.note.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            const FinancialGroupTitle(title: 'الملاحظات'),
            FinancialOperationalCard(
              child: Text(paper.note,
                  style: TextStyle(
                      height: 1.6,
                      fontSize: 12.sp,
                      color: AppColors.operationalNavy)),
            ),
          ],
          SizedBox(height: 10.h),
          FinancialGroupTitle(
              title: 'صور ومستندات الورقة', count: images.length),
          if (images.isEmpty)
            const FinancialOperationalCard(
                child: Text('لا توجد صور',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.customGreyColor5)))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.18),
              itemBuilder: (context, index) => InkWell(
                onTap: () => showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Dismiss',
                  pageBuilder: (_, __, ___) => FullScreenZoomImage(
                    imageUrl: images[index],
                    imageUrls: images,
                    initialIndex: index,
                    downloadFolderSegments: [
                      'Official Papers',
                      paper.fileBoxName,
                      paper.paperName
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    cacheManager: FinancialImageCache.instance,
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.operationalSurface),
                    errorWidget: (_, __, ___) => Container(
                        color: AppColors.operationalSurface,
                        child: const Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _connector() => Padding(
        padding: EdgeInsetsDirectional.only(start: 17.w),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
              width: 2.w,
              height: 12.h,
              color: AppColors.operationalPurple.withValues(alpha: .25)),
        ),
      );
}

class _LocationStep extends StatelessWidget {
  const _LocationStep(
      {required this.number,
      required this.label,
      required this.value,
      required this.icon});
  final String number;
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
            color: AppColors.operationalSurface,
            borderRadius: BorderRadius.circular(10.r)),
        child: Row(children: [
          CircleAvatar(
              radius: 10.r,
              backgroundColor: AppColors.operationalPurple,
              child: Text(number,
                  style: TextStyle(color: Colors.white, fontSize: 9.sp))),
          SizedBox(width: 7.w),
          Icon(icon, color: AppColors.operationalPurple, size: 19.sp),
          SizedBox(width: 7.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9.sp, color: AppColors.customGreyColor5)),
                Text(value.isEmpty ? 'غير محدد' : value,
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.operationalNavy)),
              ])),
        ]),
      );
}
