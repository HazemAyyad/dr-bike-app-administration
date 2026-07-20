import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import 'costom_dialog_filter.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.surfaceTintColor,
    this.fromDateController,
    this.toDateController,
    this.employeeNameController,
    this.onPressedFilter,
    this.onPressedAdd,
    this.onPressedBack,
    this.label,
    this.action = true,
    this.dsibalBack = false,
    this.bottom,
  }) : super(key: key);

  final String title;
  final String? label;
  final TextEditingController? fromDateController;
  final TextEditingController? toDateController;
  final TextEditingController? employeeNameController;
  final void Function()? onPressedFilter;
  final VoidCallback? onPressedAdd;
  final VoidCallback? onPressedBack;
  final bool? action;
  final List<Widget>? actions;
  final bool dsibalBack;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final PreferredSizeWidget? bottom;

  static bool _backNavigationInProgress = false;

  static void _safeBack() {
    if (_backNavigationInProgress) return;
    _backNavigationInProgress = true;
    FocusManager.instance.primaryFocus?.unfocus();

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
      }
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        _backNavigationInProgress = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      bottom: bottom,
      title: Text(
        title.tr,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: ThemeService.isDark.value
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
            ),
      ),
      leading: dsibalBack
          ? const SizedBox.shrink()
          : IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ThemeService.isDark.value
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor,
              ),
              onPressed: onPressedBack ?? _safeBack,
            ),
      actions: actions ??
          [
            if (fromDateController != null ||
                toDateController != null ||
                employeeNameController != null)
              IconButton(
                highlightColor: Colors.transparent,
                icon: Icon(
                  Icons.calendar_today_outlined,
                  size: 22.sp,
                  color: ThemeService.isDark.value
                      ? AppColors.primaryColor
                      : AppColors.secondaryColor,
                ),
                onPressed: () {
                  showCustomDialog(
                    context,
                    fromDateController: fromDateController,
                    toDateController: toDateController,
                    employeeNameController: employeeNameController,
                    label: label ?? 'employeeName',
                    onPressed: onPressedFilter ?? () {},
                  );
                },
              ),
            action!
                ? IconButton(
                    highlightColor: Colors.transparent,
                    icon: Icon(
                      Icons.add_circle,
                      size: 32.sp,
                      color: ThemeService.isDark.value
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
                    onPressed: onPressedAdd,
                  )
                : const SizedBox(),
            SizedBox(width: 10.w)
          ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
