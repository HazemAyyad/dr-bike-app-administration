import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({
    Key? key,
    required this.isAddMenuOpen,
    required this.onTap,
    required this.sizeAnimation,
    required this.opacityAnimation,
    required this.addList,
    this.customWidget,
  }) : super(key: key);

  final RxBool isAddMenuOpen;
  final void Function()? onTap;
  final Animation<double> sizeAnimation;
  final Animation<double> opacityAnimation;
  final List<Map<String, String>> addList;
  final Widget? customWidget;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Get.locale!.languageCode == 'ar'
          ? Alignment.bottomLeft
          : Alignment.bottomRight,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Get.locale!.languageCode == 'ar'
              ? Alignment.bottomLeft
              : Alignment.bottomRight,
          children: [
            Obx(() {
              if (!isAddMenuOpen.value) return SizedBox.shrink();
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

            Positioned(
              bottom: 50.h,
              left: Get.locale!.languageCode == 'ar' ? 0.w : 150.w,
              right: Get.locale!.languageCode == 'ar' ? 150.w : 0.w,
              child: SizeTransition(
                sizeFactor: sizeAnimation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: sizeAnimation,
                  child: Container(
                    width: 250.w,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'add'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...addList.map(
                          (e) => BuildAddMenuItem(
                            title: e['title']!,
                            iconAsset: e['icon']!,
                            route: e['route']!,
                            onTap: () => onTap!(),
                          ),
                        ),
                        customWidget ?? const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // زر الإضافة
            SizedBox(
              height: 55.h,
              width: 55.w,
              child: FloatingActionButton(
                onPressed: onTap,
                backgroundColor: AppColors.secondaryColor,
                elevation: 2.0,
                shape: CircleBorder(),
                child: Obx(
                  () => AnimatedRotation(
                    turns: isAddMenuOpen.value ? -0.125 : 0, // 0.125 = 45 درجة
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.add,
                      key: ValueKey(isAddMenuOpen.value),
                      color: AppColors.whiteColor,
                      size: 42.sp,
                    ),
                  ),
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
    required this.title,
    required this.iconAsset,
    required this.route,
    required this.onTap,
  }) : super(key: key);

  final String title;
  final String iconAsset;
  final String route;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: WidgetStatePropertyAll(Colors.transparent),
      onTap: () {
        if (route.isNotEmpty) {
          Get.toNamed(
            route,
            arguments: {
              'isNewCheck': title == 'newCheck',
              'isPenaltyTitle': title,
            },
          );
        } else {
          onTap?.call();
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Image.asset(iconAsset, height: 24.h, width: 24.w)),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                title.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Get.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16.sp,
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
