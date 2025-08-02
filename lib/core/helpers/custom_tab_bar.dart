import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class AppTabs extends StatelessWidget {
  const AppTabs({
    Key? key,
    required this.tabs,
    required this.currentTab,
    required this.changeTab,
    this.width,
  }) : super(key: key);

  final List<String> tabs;
  final RxInt currentTab;
  final Function(int index) changeTab;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: width != null ? null : EdgeInsets.symmetric(horizontal: 5.w),
        padding: width != null ? null : EdgeInsets.symmetric(horizontal: 5.w),
        height: 48.h,
        width: width,
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor
              : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(31.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...tabs.map(
              (e) => CustomTabBar(
                label: e,
                index: tabs.indexOf(e),
                currentTab: currentTab,
                onTap: () => changeTab(tabs.indexOf(e)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    required this.index,
    required this.currentTab,
    required this.label,
    required this.onTap,
    this.fontSize,
    Key? key,
  }) : super(key: key);
  final int index;
  final RxInt currentTab;
  final String label;
  final VoidCallback onTap;
  final double? fontSize;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: onTap,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey<int>(currentTab.value),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: currentTab.value == index
                  ? ThemeService.isDark.value
                      ? AppColors.graywhiteColor
                      : AppColors.whiteColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(31.r),
              boxShadow: [
                currentTab.value == index
                    ? BoxShadow(
                        color: AppColors.customGreyColor.withAlpha(51),
                        blurRadius: 3,
                        offset: const Offset(0, 0),
                      )
                    : const BoxShadow(
                        color: Colors.transparent,
                        blurRadius: 0,
                        offset: Offset(0, 0),
                      ),
              ],
            ),
            child: Text(
              label.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: fontSize ?? 17.sp,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.isDark.value
                        ? Colors.white
                        : AppColors.secondaryColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
