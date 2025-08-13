import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/assets_manger.dart';
import '../../../../../routes/app_routes.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = Get.arguments;
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        actions: [
          TextButton.icon(
            icon: Icon(
              Icons.edit_calendar_outlined,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              size: 25.sp,
            ),
            onPressed: () {
              Get.toNamed(
                AppRoutes.CREATETASKSCREEN,
                arguments: 'createNewEmployeeTask',
              );
            },
            label: Text(
              'edit'.tr,
              style: theme.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(height: 10.h),
            // Text(
            //   " 1 مارس الى 3 مارس",
            //   style:theme.copyWith(
            //         fontSize: 15.sp,
            //         fontWeight: FontWeight.w700,
            //         color: ThemeService.isDark.value
            //             ? AppColors.customGreyColor6
            //             : AppColors.customGreyColor4,
            //       ),
            // ),
            SupTextAndDis(
                title: 'taskName'.tr, discription: 'ترتيب رفوف المحل'),
            title == 'employeeTaskDetails'
                ? SupTextAndDis(
                    title: 'employeeName'.tr, discription: 'شادي محمد')
                : const SizedBox.shrink(),
            title == 'employeeTaskDetails'
                ? SupTextAndDis(title: 'numberOfPoints'.tr, discription: '20')
                : const SizedBox.shrink(),

            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'adminImage'.tr,
                      //   style: theme.copyWith(
                      //     fontSize: 14.sp,
                      //     fontWeight: FontWeight.w700,
                      //     color: ThemeService.isDark.value
                      //         ? AppColors.customGreyColor6
                      //         : AppColors.customGreyColor4,
                      //   ),
                      // ),
                      // SizedBox(height: 5.h),
                      Image.asset(
                        AssetsManger.rectangle,
                        height: 132.h,
                        width: 183.w,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'employeeImage'.tr,
                      //   style: theme.copyWith(
                      //     fontSize: 14.sp,
                      //     fontWeight: FontWeight.w700,
                      //     color: ThemeService.isDark.value
                      //         ? AppColors.customGreyColor6
                      //         : AppColors.customGreyColor4,
                      //   ),
                      // ),
                      SizedBox(height: 5.h),
                      Image.asset(
                        AssetsManger.rectangle,
                        height: 132.h,
                        width: 183.w,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SupTextAndDis(
              title: 'taskDescription',
              discription:
                  'مهمة ترتيب رفوف المحل تشمل عدة خطوات أساسية لضمان تنظيم المنتجات بشكل جيد، بحيث يكون الوصول إليها سهلاً للعملاء، كما تساهم في تحسين مظهر المحل وزيادة المبيعات. إليك وصف للمهمة:\nالتخطيط:\nفحص المنتجات المتوفرة وتحديد كيفية توزيعها بناءً على النوع أو الفئة (مثلاً: قسم الألبان، قسم العصائر، قسم المعلبات).\nالتأكد من وضع المنتجات الأكثر طلبًا في أماكن مرئية وسهلة الوصول.\nتخصيص مساحات لكل منتج أو فئة من المنتجات وفقًا لحجمها.\nتنظيف الرفوف: قبل ترتيب المنتجات، يجب تنظيف الرفوف جيدًا لإزالة الغبار أو أي أوساخ قد تكون تراكمت عليها.\nتنظيم المنتجات:\nوضع المنتجات على الرفوف بطريقة منظمة، مع التأكد من أن كل منتج يظهر بوضوح.\nترتيب المنتجات بشكل منتظم، مع التأكد من أن أسعارها بارزة وواضحة.\nوضع المنتجات الجديدة أو التي تحتاج إلى الترويج في الأماكن المميزة.\nالتأكد من المخزون:\nفحص مستوى المخزون للتأكد من أن جميع المنتجات المطلوبة موجودة.\nفي حال كانت هناك منتجات نفدت، يجب استبدالها أو وضع إشعار ينبه العملاء إلى أنها غير متوفرة حاليًا.....',
            ),
            SupTextAndDis(title: 'taskRepeat'.tr, discription: 'يوميا'),
            SupTextAndDis(
                title: 'taskRepeatDate'.tr, discription: 'من الأحد الى الخميس'),
            SupTextAndDis(
              title: 'subTaskName'.tr,
              discription: 'ترتيب رفوف المحل الاخرة',
            ),
            SupTextAndDis(
              title: 'subTaskDescription'.tr,
              discription: 'ترتيب رفوف المحل الاخر شاملة...',
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }
}

class SupTextAndDis extends StatelessWidget {
  const SupTextAndDis({
    Key? key,
    required this.title,
    required this.discription,
  }) : super(key: key);

  final String title;
  final String discription;

  @override
  Widget build(BuildContext context) {
    final TextStyle theme = Theme.of(context).textTheme.bodyMedium!;
    return Column(
      children: [
        SizedBox(height: 10.h),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "${title.tr}: ",
                style: theme.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor4,
                ),
              ),
              TextSpan(
                text: discription,
                style: theme.copyWith(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w400,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.customGreyColor4,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
