import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_floating_action_button.dart';
import '../../../../../core/helpers/person_avatar_helper.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../../../../../routes/app_routes.dart';
import '../../../notifications/presentation/controllers/admin_notification_badge_controller.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/actions_buttons.dart';
import '../widgets/admin_statistics_cards.dart';
import '../widgets/dashboard_design_tokens.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dark = ThemeService.isDark.value;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DashboardDesignTokens.backgroundFor(dark),
          body: controller.isDashboardPreparing.value
              ? const _AdminDashboardSkeleton()
              : RefreshIndicator(
                  onRefresh: controller.refreshDashboard,
                  color: DashboardDesignTokens.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverSafeArea(
                        bottom: false,
                        sliver: SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate.fixed([
                              SizedBox(height: 8.h),
                              _AdminDashboardHeader(
                                onCustomize: () =>
                                    _showCustomizeDashboardDialog(context),
                              ),
                              SizedBox(height: 18.h),
                              const BuildStatisticsCards(),
                              SizedBox(
                                height: DashboardDesignTokens.sectionSpacing.h,
                              ),
                              GetBuilder<AdminDashboardController>(
                                builder: (controller) {
                                  final buttons =
                                      controller.visibleDashboardButtons;
                                  final preferredQuickCount = controller
                                      .dashboardQuickAccessCount.value;
                                  final quickCount =
                                      buttons.length > preferredQuickCount
                                          ? preferredQuickCount
                                          : buttons.length;
                                  final quick =
                                      buttons.take(quickCount).toList()
                                        ..add({
                                          'id': 'add_shortcut',
                                          'title': 'إضافة اختصار',
                                          'route': '',
                                        });
                                  final allSectionSource = buttons;
                                  final remaining = controller
                                      .filterDashboardButtons(allSectionSource);
                                  final badges = controller
                                          .mainDashboardDataModel
                                          ?.dashboardBadges ??
                                      const <String, int>{};
                                  return Column(
                                    children: [
                                      BuildActionButtons(
                                        buttons: quick,
                                        badges: badges,
                                        onReorder:
                                            controller.reorderDashboardButton,
                                        sectionTitle: 'الوصول السريع',
                                        sectionIcon: Icons.bolt_rounded,
                                        dashboardStyle:
                                            DashboardButtonStyle.quickAccess,
                                        headerAction: TextButton(
                                          onPressed: () =>
                                              _showCustomizeDashboardDialog(
                                            context,
                                          ),
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            foregroundColor:
                                                DashboardDesignTokens.primary,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                            ),
                                          ),
                                          child: Text(
                                            'تخصيص الاختصارات',
                                            style: TextStyle(
                                              fontSize: 9.5.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        reorderMode: controller
                                            .isDashboardReorderMode.value,
                                        onReorderStarted:
                                            controller.startDashboardReorder,
                                        onReorderFinished:
                                            controller.finishDashboardReorder,
                                        onAddShortcut: () =>
                                            _showCustomizeDashboardDialog(
                                          context,
                                        ),
                                      ),
                                      if (allSectionSource.isNotEmpty ||
                                          controller
                                              .isDashboardSectionsSearchOpen
                                              .value) ...[
                                        SizedBox(
                                          height: DashboardDesignTokens
                                              .sectionSpacing.h,
                                        ),
                                        BuildActionButtons(
                                          buttons: remaining,
                                          badges: badges,
                                          onReorder:
                                              controller.reorderDashboardButton,
                                          sectionTitle: 'كل الأقسام',
                                          sectionIcon: Icons.grid_view_rounded,
                                          dashboardStyle:
                                              DashboardButtonStyle.allSections,
                                          headerAction:
                                              _DashboardSectionsSearchAction(
                                            expanded: controller
                                                .isDashboardSectionsSearchOpen
                                                .value,
                                            onOpen: controller
                                                .toggleDashboardSectionsSearch,
                                            onClose: controller
                                                .toggleDashboardSectionsSearch,
                                            onChanged: controller
                                                .setDashboardSectionsSearch,
                                          ),
                                          reorderMode: controller
                                              .isDashboardReorderMode.value,
                                          onReorderStarted:
                                              controller.startDashboardReorder,
                                          onReorderFinished:
                                              controller.finishDashboardReorder,
                                        ),
                                        if (remaining.isEmpty)
                                          _DashboardEmptySearch(
                                            dark: dark,
                                          ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              SizedBox(height: 108.h),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          floatingActionButton: controller.isDashboardPreparing.value
              ? const SizedBox.shrink()
              : CustomFloatingActionButton(
                  isAddMenuOpen: controller.isAddMenuOpen,
                  onTap: controller.toggleAddMenu,
                  opacityAnimation: controller.sizeAnimation,
                  sizeAnimation: controller.opacityAnimation,
                  addList: controller.visibleAdminAddList,
                  useGrid: true,
                  backgroundColor: DashboardDesignTokens.primary,
                  compact: true,
                  centered: true,
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      );
    });
  }

  void _showCustomizeDashboardDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520.w, maxHeight: 620.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'customizeDashboard'.tr,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: ThemeService.isDark.value
                                  ? AppColors.customGreyColor6
                                  : AppColors.secondaryColor,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                GetBuilder<AdminDashboardController>(
                  builder: (controller) => Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.operationalPurple.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'عدد أقسام الوصول السريع',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'اختر عدد البطاقات التي تظهر في الأعلى',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: AppColors.customGreyColor5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: controller
                                      .dashboardQuickAccessCount.value <=
                                  3
                              ? null
                              : () => controller.setDashboardQuickAccessCount(
                                    controller.dashboardQuickAccessCount.value -
                                        1,
                                  ),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Container(
                          constraints: BoxConstraints(minWidth: 34.w),
                          child: Text(
                            '${controller.dashboardQuickAccessCount.value}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.operationalPurple,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: controller
                                          .dashboardQuickAccessCount.value >=
                                      7 ||
                                  controller.dashboardQuickAccessCount.value >=
                                      controller.visibleDashboardButtons.length
                              ? null
                              : () => controller.setDashboardQuickAccessCount(
                                    controller.dashboardQuickAccessCount.value +
                                        1,
                                  ),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                GetBuilder<AdminDashboardController>(
                  builder: (controller) => SwitchListTile.adaptive(
                    value: controller.showDashboardAttentionSection.value,
                    onChanged: controller.isUiPreferencesSaving.value
                        ? null
                        : controller.setDashboardAttentionSectionVisible,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                    activeThumbColor: AppColors.primaryColor,
                    title: Text(
                      'أهم ما ينتظر المتابعة',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'إظهار القسم في الصفحة الرئيسية',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppColors.customGreyColor5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Flexible(
                  child: GetBuilder<AdminDashboardController>(
                    builder: (controller) => ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.buttons.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor
                            : AppColors.customGreyColor3,
                      ),
                      itemBuilder: (context, index) {
                        final button = controller.buttons[index];
                        final isVisible =
                            !controller.isDashboardButtonHidden(button);
                        return SwitchListTile.adaptive(
                          value: isVisible,
                          onChanged: controller.isUiPreferencesSaving.value
                              ? null
                              : (value) => controller.setDashboardButtonVisible(
                                    button,
                                    value,
                                  ),
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.primaryColor,
                          title: Text(
                            (button['title']?.toString() ?? '').tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          controller.resetDashboardButtonsVisibility(),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text('resetDashboardSections'.tr),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: Get.back,
                      child: Text('close'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardHeader extends GetView<AdminDashboardController> {
  const _AdminDashboardHeader({required this.onCustomize});

  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final name = controller.dashboardUserName.value.trim();
    final role = controller.dashboardUserRole.value.trim();
    return Row(
      children: [
        _DashboardAvatar(
          name: name,
          image: controller.dashboardUserImage.value,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً بك!',
                style: TextStyle(
                  color: DashboardDesignTokens.textSecondaryFor(dark),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  name.isEmpty ? 'welcome'.tr : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DashboardDesignTokens.textPrimaryFor(dark),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (role.isNotEmpty)
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DashboardDesignTokens.textSecondaryFor(dark),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        if (userType == 'admin') ...[
          Obx(() {
            final badgeController =
                Get.isRegistered<AdminNotificationBadgeController>()
                    ? Get.find<AdminNotificationBadgeController>()
                    : null;
            return _HeaderCircleAction(
              tooltip: 'notifications'.tr,
              icon: Icons.notifications_none_rounded,
              badge: badgeController?.unreadCount.value ?? 0,
              onTap: () async {
                await Get.toNamed(AppRoutes.NOTIFICATIONCENTER);
                badgeController?.refresh();
              },
            );
          }),
          SizedBox(width: 8.w),
          _HeaderCircleAction(
            tooltip: 'customizeDashboard'.tr,
            icon: Icons.tune_rounded,
            onTap: onCustomize,
          ),
          SizedBox(width: 8.w),
        ],
        _HeaderCircleAction(
          tooltip: dark ? 'الوضع النهاري' : 'الوضع الليلي',
          icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: () {
            final nextDark = !ThemeService.isDark.value;
            ThemeService.isDark.value = nextDark;
            ThemeService.instance.themeMode =
                nextDark ? ThemeMode.dark : ThemeMode.light;
          },
        ),
      ],
    );
  }
}

class _DashboardAvatar extends StatelessWidget {
  const _DashboardAvatar({required this.name, required this.image});

  final String name;
  final String image;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'DB';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts.last.characters.first : '';
    return '$first$second'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    final raw = image.trim();
    final resolved = PersonAvatarHelper.resolve(raw);
    final hasImage =
        raw.isNotEmpty && !PersonAvatarHelper.isPlaceholder(resolved);
    final fallback = Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: DashboardDesignTokens.primary,
          fontSize: 16.sp,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.PROFILESCREEN),
      customBorder: const CircleBorder(),
      child: Container(
        width: 51.r,
        height: 51.r,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DashboardDesignTokens.primary.withValues(
            alpha: dark ? .20 : .10,
          ),
          border: Border.all(
            color: DashboardDesignTokens.surfaceFor(dark),
            width: 2,
          ),
        ),
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  const _HeaderCircleAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: DashboardDesignTokens.surfaceFor(dark),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: tooltip,
              child: SizedBox(
                width: 42.r,
                height: 42.r,
                child: Icon(
                  icon,
                  color: const Color(0xFF3C557A),
                  size: 22.sp,
                ),
              ),
            ),
          ),
        ),
        if (badge > 0)
          PositionedDirectional(
            top: -5.h,
            end: -5.w,
            child: Container(
              constraints: BoxConstraints(minWidth: 21.r, minHeight: 19.r),
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: DashboardDesignTokens.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: DashboardDesignTokens.backgroundFor(dark),
                  width: 1.5,
                ),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardSectionsSearchAction extends StatefulWidget {
  const _DashboardSectionsSearchAction({
    required this.expanded,
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
  });

  final bool expanded;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  final ValueChanged<String> onChanged;

  @override
  State<_DashboardSectionsSearchAction> createState() =>
      _DashboardSectionsSearchActionState();
}

class _DashboardSectionsSearchActionState
    extends State<_DashboardSectionsSearchAction> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _DashboardSectionsSearchAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
    if (!widget.expanded && oldWidget.expanded) {
      _focusNode.unfocus();
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeService.isDark.value;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axis: Axis.horizontal,
        axisAlignment: -1,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: widget.expanded
          ? SizedBox(
              key: const ValueKey('dashboard-search-field'),
              width: 180.w,
              height: 42.h,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: DashboardDesignTokens.textPrimaryFor(dark),
                  fontSize: 10.5.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'بحث في الأقسام...',
                  hintStyle: TextStyle(
                    color: DashboardDesignTokens.textSecondaryFor(dark),
                    fontSize: 10.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 19.sp,
                    color: DashboardDesignTokens.primary,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'إغلاق البحث',
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                      widget.onClose();
                    },
                    icon: Icon(Icons.close_rounded, size: 18.sp),
                  ),
                  filled: true,
                  fillColor: DashboardDesignTokens.surfaceFor(dark),
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21.r),
                    borderSide: BorderSide(
                      color: DashboardDesignTokens.borderFor(dark),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21.r),
                    borderSide: const BorderSide(
                      color: DashboardDesignTokens.primary,
                    ),
                  ),
                ),
              ),
            )
          : Material(
              key: const ValueKey('dashboard-search-button'),
              color: DashboardDesignTokens.surfaceFor(dark),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onOpen,
                customBorder: const CircleBorder(),
                child: Tooltip(
                  message: 'البحث في الأقسام',
                  child: SizedBox(
                    width: 42.r,
                    height: 42.r,
                    child: Icon(
                      Icons.search_rounded,
                      color: DashboardDesignTokens.info,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DashboardEmptySearch extends StatelessWidget {
  const _DashboardEmptySearch({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 22.h),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: DashboardDesignTokens.textSecondaryFor(dark),
              size: 28.sp,
            ),
            SizedBox(height: 6.h),
            Text(
              'لا توجد أقسام مطابقة',
              style: TextStyle(
                color: DashboardDesignTokens.textSecondaryFor(dark),
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _AdminDashboardSkeleton extends StatelessWidget {
  const _AdminDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: double.infinity, height: 66.h, radius: 12),
          SizedBox(height: 14.h),
          SkeletonBlock(width: 118.w, height: 22.h, radius: 6),
          SizedBox(height: 8.h),
          SkeletonBlock(width: double.infinity, height: 82.h, radius: 12),
          SizedBox(height: 20.h),
          SkeletonBlock(width: 145.w, height: 24.h, radius: 6),
          SizedBox(height: 5.h),
          SkeletonBlock(width: 172.w, height: 11.h, radius: 5),
          SizedBox(height: 10.h),
          const _DashboardGridSkeleton(colorHint: Color(0xFFF28C28)),
          SizedBox(height: 22.h),
          SkeletonBlock(width: 112.w, height: 24.h, radius: 6),
          SizedBox(height: 5.h),
          SkeletonBlock(width: 155.w, height: 11.h, radius: 5),
          SizedBox(height: 10.h),
          const _DashboardGridSkeleton(),
        ],
      ),
    );
  }
}

class _DashboardGridSkeleton extends StatelessWidget {
  const _DashboardGridSkeleton({this.colorHint});

  final Color? colorHint;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.25.h,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 7.h,
      ),
      itemBuilder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          const SkeletonBlock(
              width: double.infinity, height: double.infinity, radius: 10),
          if (colorHint != null)
            Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                color: colorHint!.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
