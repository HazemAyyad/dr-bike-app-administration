import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/desktop_layout.dart';

class AppTabs extends StatefulWidget {
  const AppTabs({
    Key? key,
    required this.tabs,
    required this.currentTab,
    required this.changeTab,
    this.width,
    this.height,
    this.horizontalPadding,
    this.tabHorizontalPadding,
    this.tabVerticalPadding,
    this.tabHorizontalMargin,
    this.fontSize,
    this.translateLabels = true,
    this.fitToWidthUpToCount,
    this.tabCounts,
  }) : super(key: key);

  final List<String> tabs;
  final List<int>? tabCounts;
  final RxInt currentTab;
  final Function(int index) changeTab;
  final double? width;
  final double? height;
  final double? horizontalPadding;
  final double? tabHorizontalPadding;
  final double? tabVerticalPadding;
  final double? tabHorizontalMargin;
  final double? fontSize;
  final bool translateLabels;
  final int? fitToWidthUpToCount;

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTabs(double direction) {
    if (!_scrollController.hasClients) return;
    final next = (_scrollController.offset + (direction * 220))
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = DesktopLayout.isDesktop(context);
    final shouldFitToWidth = widget.fitToWidthUpToCount != null &&
        widget.tabs.length <= widget.fitToWidthUpToCount!;
    final tabContainer = Container(
      margin: widget.width != null
          ? null
          : EdgeInsets.symmetric(horizontal: widget.horizontalPadding ?? 10.w),
      padding:
          widget.width != null ? null : EdgeInsets.symmetric(horizontal: 2.w),
      height: widget.height ?? 48.h,
      width: shouldFitToWidth ? double.infinity : widget.width,
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor2,
        borderRadius: BorderRadius.circular(31.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < widget.tabs.length; i++)
            shouldFitToWidth ? Expanded(child: _buildTab(i)) : _buildTab(i),
        ],
      ),
    );
    final tabs = shouldFitToWidth
        ? tabContainer
        : SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: tabContainer,
          );

    if (shouldFitToWidth) {
      return Center(child: tabs);
    }

    return Center(
      child: desktop
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TabScrollButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _scrollTabs(-1),
                ),
                Flexible(child: tabs),
                _TabScrollButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _scrollTabs(1),
                ),
              ],
            )
          : tabs,
    );
  }

  Widget _buildTab(int index) {
    return CustomTabBar(
      label: widget.tabs[index],
      index: index,
      currentTab: widget.currentTab,
      onTap: () => widget.changeTab(index),
      translateLabel: widget.translateLabels,
      horizontalPadding: widget.tabHorizontalPadding,
      verticalPadding: widget.tabVerticalPadding,
      horizontalMargin: widget.tabHorizontalMargin,
      fontSize: widget.fontSize,
      count: widget.tabCounts != null && index < widget.tabCounts!.length
          ? widget.tabCounts![index]
          : null,
    );
  }
}

class _TabScrollButton extends StatelessWidget {
  const _TabScrollButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'scroll'.tr,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ThemeService.isDark.value
                ? AppColors.customGreyColor
                : AppColors.whiteColor2,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: ThemeService.isDark.value
                ? Colors.white
                : AppColors.secondaryColor,
          ),
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
    this.horizontalPadding,
    this.verticalPadding,
    this.horizontalMargin,
    this.translateLabel = true,
    this.count,
    Key? key,
  }) : super(key: key);
  final int index;
  final RxInt currentTab;
  final String label;
  final int? count;
  final VoidCallback onTap;
  final double? fontSize;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? horizontalMargin;
  final bool translateLabel;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 5.w),
          key: ValueKey<int>(currentTab.value),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding ?? 10.h,
            horizontal: horizontalPadding ?? 20.w,
          ),
          decoration: BoxDecoration(
            color: currentTab.value == index
                ? ThemeService.isDark.value
                    ? AppColors.customGreyColor5
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final labelText = Text(
                translateLabel ? label.tr : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: fontSize ?? 17.sp,
                      fontWeight: FontWeight.w400,
                      color: ThemeService.isDark.value
                          ? Colors.white
                          : AppColors.secondaryColor,
                    ),
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  constraints.hasBoundedWidth
                      ? Flexible(child: labelText)
                      : labelText,
                  if (count != null) ...[
                    SizedBox(width: 5.w),
                    Container(
                      constraints: BoxConstraints(minWidth: 20.w),
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: currentTab.value == index
                            ? AppColors.primaryColor
                            : AppColors.customGreyColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        count.toString(),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: currentTab.value == index
                                  ? Colors.white
                                  : AppColors.secondaryColor,
                            ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
