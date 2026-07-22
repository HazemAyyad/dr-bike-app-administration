import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    Key? key,
    required this.isAddMenuOpen,
    required this.onTap,
    required this.sizeAnimation,
    required this.opacityAnimation,
    this.addList,
    this.customWidget,
    this.useGrid = false,
  }) : super(key: key);

  final RxBool isAddMenuOpen;
  final void Function()? onTap;
  final Animation<double> sizeAnimation;
  final Animation<double> opacityAnimation;
  final List<Map<String, String>>? addList;
  final Widget? customWidget;
  final bool useGrid;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Obx(() {
              if (!isAddMenuOpen.value) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: onTap,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              );
            }),

            Obx(() {
              if (!isAddMenuOpen.value) return const SizedBox.shrink();
              return Positioned(
                bottom: 50.h,
                left: 50.w,
                right: 50.w,
                child: Container(
                  // width: 250.w,
                  // height: 211.h,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: ThemeService.isDark.value
                        ? AppColors.customGreyColor
                        : AppColors.whiteColor2,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * .68,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'add'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (addList?.isNotEmpty ?? false)
                        Flexible(
                          child: useGrid
                              ? GridView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8.h,
                                    crossAxisSpacing: 8.w,
                                    childAspectRatio: 2.15,
                                  ),
                                  itemCount: addList!.length,
                                  itemBuilder: (_, index) => BuildAddMenuItem(
                                    item: addList![index],
                                    compactCard: true,
                                    onTap: () => onTap!(),
                                  ),
                                )
                              : ListView(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  children: addList!
                                      .map(
                                        (e) => BuildAddMenuItem(
                                          item: e,
                                          onTap: () => onTap!(),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      customWidget ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            }),

            // زر الإضافة
            Positioned(
              right: Get.locale!.languageCode == 'ar' ? 30.w : 0.w,
              child: FloatingActionButton(
                onPressed: onTap,
                backgroundColor: AppColors.secondaryColor,
                elevation: 2.0,
                shape: const CircleBorder(),
                child: Icon(
                  Icons.add,
                  color: AppColors.whiteColor,
                  size: 42.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// بناء عنصر قائمة إضافة واحد
class BuildAddMenuItem extends StatelessWidget {
  const BuildAddMenuItem({
    Key? key,
    this.item,
    this.title,
    this.iconAsset,
    this.route,
    this.compactCard = false,
    required this.onTap,
  }) : super(key: key);

  final Map<String, String>? item;
  final String? title;
  final String? iconAsset;
  final String? route;
  final void Function()? onTap;
  final bool compactCard;

  String get _title => item?['title'] ?? title ?? '';
  String get _iconAsset => item?['icon'] ?? iconAsset ?? '';
  String get _route => item?['route'] ?? route ?? '';

  IconData get _materialIcon {
    switch (item?['materialIcon']) {
      case 'employee':
        return Icons.person_add_alt_1_rounded;
      case 'expense':
        return Icons.payments_outlined;
      case 'customer':
        return Icons.group_add_outlined;
      case 'employee_task':
        return Icons.assignment_ind_outlined;
      case 'private_task':
        return Icons.task_alt_rounded;
      case 'sales_invoice':
        return Icons.receipt_long_outlined;
      case 'profit':
        return Icons.trending_up_rounded;
      case 'maintenance':
        return Icons.build_circle_outlined;
      case 'follow_up':
        return Icons.follow_the_signs_outlined;
      case 'product':
        return Icons.add_box_outlined;
      default:
        return Icons.add_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: () {
        if (_route.isNotEmpty) {
          final args = <String, dynamic>{
            'isNewCheck': _title == 'newCheck',
            'isPenaltyTitle': _title,
            'title': item?['flowTitle'] ?? _title,
          };
          if (item?['freshInstantSale'] == 'true') {
            args['freshInstantSale'] = true;
          }
          if (item?['saleKind'] != null) {
            args['saleKind'] = item!['saleKind'];
          }
          if (item?['freshSalesOrder'] == 'true') {
            args['freshSalesOrder'] = true;
          }
          if (item?['createProduct'] == 'true') {
            args['createProduct'] = true;
          }
          if (_route == AppRoutes.CREATETASKSCREEN) {
            args['fromHomeWidget'] = true;
          }
          Get.toNamed(_route, arguments: args);
        }
        //  else {
        onTap?.call();
        // }
      },
      child: Container(
        margin: compactCard ? EdgeInsets.zero : null,
        padding: compactCard
            ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h)
            : EdgeInsets.symmetric(vertical: 8.h),
        decoration: compactCard
            ? BoxDecoration(
                color: ThemeService.isDark.value
                    ? AppColors.darkColor.withValues(alpha: .65)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: .14),
                ),
              )
            : null,
        child: Row(
          mainAxisAlignment:
              compactCard ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              width: compactCard ? 30.w : 26.w,
              height: compactCard ? 30.w : 26.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: item?['materialIcon'] != null
                  ? Icon(
                      _materialIcon,
                      size: compactCard ? 18.sp : 17.sp,
                      color: AppColors.primaryColor,
                    )
                  : Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Image.asset(_iconAsset),
                    ),
            ),
            SizedBox(width: 7.w),
            Expanded(
              child: Text(
                _title.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Get.isDarkMode ? Colors.white : Colors.black,
                      fontSize: compactCard ? 11.sp : 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
class AddFloatingActionButton extends StatelessWidget {
  const AddFloatingActionButton({Key? key, required this.onPressed})
      : super(key: key);

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55.h,
      width: 55.w,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.secondaryColor,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: Icon(
          Icons.add,
          color: AppColors.whiteColor,
          size: 42.sp,
        ),
      ),
    );
  }
}
