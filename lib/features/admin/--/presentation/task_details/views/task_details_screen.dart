import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../../core/services/theme_service.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../../../core/utils/assets_manger.dart';
import '../controllers/task_details_controller.dart';

class TaskDetailsScreen extends GetView<TaskDetailsController> {
  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = Get.arguments;

    return Scaffold(
      appBar: customAppBar(context, title: title, action: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Text(
              " 1 مارس الى 3 مارس",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor4,
                  ),
            ),
            supTextAndDis(context, 'taskName'.tr, 'ترتيب رفوف المحل'),
            title == 'employeeTaskDetails'
                ? supTextAndDis(context, 'employeeName'.tr, 'شادي محمد')
                : const SizedBox.shrink(),
            supTextAndDis(context, 'numberOfPoints'.tr, '20'),
            SizedBox(height: 10.h),
            title == 'employeeTaskDetails'
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'adminImage'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor4,
                                    ),
                              ),
                              SizedBox(height: 5.h),
                              Image.asset(
                                AssetsManger.rectangle,
                                height: 132.h,
                                width: 183.w,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'employeeImage'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: ThemeService.isDark.value
                                          ? AppColors.customGreyColor6
                                          : AppColors.customGreyColor4,
                                    ),
                              ),
                              SizedBox(height: 5.h),
                              Image.asset(
                                AssetsManger.rectangle,
                                height: 132.h,
                                width: 183.w,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                    ],
                  )
                : const SizedBox.shrink(),
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "${'taskDescription'.tr}: ",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor4,
                        ),
                  ),
                  TextSpan(
                    text:
                        'مهمة ترتيب رفوف المحل تشمل عدة خطوات أساسية لضمان تنظيم المنتجات بشكل جيد، بحيث يكون الوصول إليها سهلاً للعملاء، كما تساهم في تحسين مظهر المحل وزيادة المبيعات. إليك وصف للمهمة:\nالتخطيط:\nفحص المنتجات المتوفرة وتحديد كيفية توزيعها بناءً على النوع أو الفئة (مثلاً: قسم الألبان، قسم العصائر، قسم المعلبات).\nالتأكد من وضع المنتجات الأكثر طلبًا في أماكن مرئية وسهلة الوصول.\nتخصيص مساحات لكل منتج أو فئة من المنتجات وفقًا لحجمها.\nتنظيف الرفوف: قبل ترتيب المنتجات، يجب تنظيف الرفوف جيدًا لإزالة الغبار أو أي أوساخ قد تكون تراكمت عليها.\nتنظيم المنتجات:\nوضع المنتجات على الرفوف بطريقة منظمة، مع التأكد من أن كل منتج يظهر بوضوح.\nترتيب المنتجات بشكل منتظم، مع التأكد من أن أسعارها بارزة وواضحة.\nوضع المنتجات الجديدة أو التي تحتاج إلى الترويج في الأماكن المميزة.\nالتأكد من المخزون:\nفحص مستوى المخزون للتأكد من أن جميع المنتجات المطلوبة موجودة.\nفي حال كانت هناك منتجات نفدت، يجب استبدالها أو وضع إشعار ينبه العملاء إلى أنها غير متوفرة حاليًا.....',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: ThemeService.isDark.value
                              ? AppColors.customGreyColor6
                              : AppColors.customGreyColor4,
                        ),
                  )
                ],
              ),
            ),
            supTextAndDis(context, 'taskName'.tr, 'يوميا'),
            supTextAndDis(context, 'taskRepeatDate'.tr, 'من الأحد الى الخميس'),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget supTextAndDis(BuildContext context, title, discription) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        Row(
          children: [
            Text(
              "${'$title'.tr}: ",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor4,
                  ),
            ),
            Text(
              discription,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor6
                        : AppColors.customGreyColor4,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
