import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/initial_bindings.dart';
import '../../../../../core/services/desktop_window_service.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/desktop_layout.dart';
import '../../../../../routes/app_routes.dart';
import 'dashboard_design_tokens.dart';
import 'dashboard_section_header.dart';

enum DashboardButtonStyle { legacy, quickAccess, allSections }

class BuildActionButtons extends StatelessWidget {
  const BuildActionButtons({
    Key? key,
    required this.buttons,
    this.employeePermissions,
    this.badges = const {},
    this.onReorder,
    this.employeePurpleStyle = false,
    this.sectionTitle,
    this.accentColor,
    this.backgroundColor,
    this.reorderMode = false,
    this.onReorderStarted,
    this.onReorderFinished,
    this.onAddShortcut,
    this.headerAction,
    this.sectionLead,
    this.dashboardStyle = DashboardButtonStyle.legacy,
    this.sectionIcon,
  }) : super(key: key);

  final List<Map<String, dynamic>> buttons;
  final List<int>? employeePermissions;
  final Map<String, int> badges;
  final Future<void> Function(String draggedKey, String targetKey)? onReorder;
  final bool employeePurpleStyle;
  final String? sectionTitle;
  final Color? accentColor;
  final Color? backgroundColor;
  final bool reorderMode;
  final VoidCallback? onReorderStarted;
  final VoidCallback? onReorderFinished;
  final VoidCallback? onAddShortcut;
  final Widget? headerAction;
  final Widget? sectionLead;
  final DashboardButtonStyle dashboardStyle;
  final IconData? sectionIcon;

  String _buttonKey(Map<String, dynamic> button) {
    final route = button['route']?.toString() ?? '';
    return route.isNotEmpty ? route : button['id']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final filteredButtons = userType == 'admin'
        ? buttons
        : buttons
            .where((x) => _canShowButton(x, employeePermissions ?? const []))
            .toList();

    return Column(
      children: [
        if (dashboardStyle != DashboardButtonStyle.legacy)
          DashboardSectionHeader(
            title: sectionTitle ?? 'الأقسام المتاحة',
            icon: sectionIcon ?? Icons.grid_view_rounded,
            action: headerAction,
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle ??
                      (employeePurpleStyle
                          ? 'الأقسام المتاحة'
                          : 'permissions'.tr),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: ThemeService.isDark.value
                            ? AppColors.customGreyColor6
                            : AppColors.secondaryColor,
                      ),
                ),
              ),
              if (headerAction != null) headerAction!,
            ],
          ),
        if (sectionLead != null) ...[
          SizedBox(height: 3.h),
          sectionLead!,
        ],
        SizedBox(
            height: dashboardStyle == DashboardButtonStyle.legacy ? 5.h : 10.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 320 ? 4 : 3;
            final spacing = DashboardDesignTokens.cardSpacing.w;
            final tileWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
            final tileHeight = DesktopLayout.isDesktop(context)
                ? 84.0
                : dashboardStyle == DashboardButtonStyle.quickAccess
                    ? (tileWidth * 1.08).clamp(78.0, 94.0)
                    : dashboardStyle == DashboardButtonStyle.allSections
                        ? (tileWidth * 1.02).clamp(75.0, 90.0)
                        : 78.h;
            return Wrap(
              spacing: spacing,
              runSpacing: dashboardStyle == DashboardButtonStyle.legacy
                  ? 7.h
                  : DashboardDesignTokens.cardSpacing.h,
              children: List<Widget>.generate(filteredButtons.length, (index) {
                final button = filteredButtons[index];
                final isAddShortcut = button['id'] == 'add_shortcut';
                final buttonKey = _buttonKey(button);
                const legacyAccents = [
                  Color(0xFFE9445B),
                  Color(0xFF16A464),
                  Color(0xFF6750E8),
                  Color(0xFFF28C28),
                  Color(0xFF1677F2),
                  Color(0xFF52617A),
                ];
                final tileAccent = accentColor ??
                    (dashboardStyle == DashboardButtonStyle.legacy
                        ? legacyAccents[index % legacyAccents.length]
                        : _dashboardAccent(
                            button['title']?.toString() ?? '',
                          ));
                final badgeDescriptors = (button['badgeDescriptors'] as List?)
                        ?.whereType<Map>()
                        .map((item) => _ActionBadge.fromMap(item, badges))
                        .where((item) => item.count > 0)
                        .toList(growable: false) ??
                    const <_ActionBadge>[];

                final tile = _buildActionButton(
                  button['title'],
                  button['route'],
                  badges[button['badgeKey']?.toString() ?? ''] ?? 0,
                  badgeDescriptors,
                  employeePurpleStyle: employeePurpleStyle,
                  accentColor: tileAccent,
                  backgroundColor:
                      backgroundColor ?? tileAccent.withValues(alpha: .075),
                  onTapOverride: isAddShortcut ? onAddShortcut : null,
                  dashboardStyle: dashboardStyle,
                );
                final animatedTile = _ReorderWiggle(
                  enabled: reorderMode,
                  reverse: index.isOdd,
                  child: tile,
                );
                if (onReorder == null || buttonKey.isEmpty || isAddShortcut) {
                  return SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: animatedTile,
                  );
                }
                return SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (details) =>
                        details.data != buttonKey,
                    onAcceptWithDetails: (details) =>
                        onReorder!(details.data, buttonKey),
                    builder: (context, candidates, rejected) =>
                        LongPressDraggable<String>(
                      data: buttonKey,
                      delay: const Duration(milliseconds: 350),
                      onDragStarted: onReorderStarted,
                      onDragEnd: (_) => onReorderFinished?.call(),
                      onDraggableCanceled: (_, __) => onReorderFinished?.call(),
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: tileWidth,
                          height: tileHeight,
                          child: Opacity(opacity: .92, child: tile),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: .25, child: tile),
                      child: AnimatedScale(
                        scale: candidates.isEmpty ? 1 : .94,
                        duration: const Duration(milliseconds: 120),
                        child: animatedTile,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  bool _canShowButton(Map<String, dynamic> button, List<int> permissions) {
    final route = button['route'];
    if (route == AppRoutes.ONLINESTOREDASHBOARD) {
      return canViewOnlineStore;
    }
    if (route == AppRoutes.GENERALSETTINGSSCREEN) {
      return canManageStockInventorySettings;
    }
    if (route == AppRoutes.STOCKSCREEN) {
      return canAccessStockScreen;
    }
    if (route == AppRoutes.CHECKSSCREEN) {
      return canAccessChecks;
    }
    if (route == AppRoutes.FINANCIALAFFAIRSSCREEN) {
      return canAccessFinancialAffairs;
    }
    if (route == AppRoutes.MYEMPLOYEESUGGESTIONSSCREEN) {
      return true;
    }
    if (route == AppRoutes.TECHNICALSUPPORT) {
      return true;
    }
    if (route == AppRoutes.STORESUPPORT) {
      return userType == 'admin' ||
          employeePermissionNames.contains(onlineStoreSupportPermissionName);
    }
    if (route == AppRoutes.NOTES) {
      return true;
    }

    final id = int.tryParse(button['id']?.toString() ?? '');
    return id != null && permissions.contains(id);
  }
}

class _ReorderWiggle extends StatefulWidget {
  const _ReorderWiggle({
    required this.enabled,
    required this.reverse,
    required this.child,
  });

  final bool enabled;
  final bool reverse;
  final Widget child;

  @override
  State<_ReorderWiggle> createState() => _ReorderWiggleState();
}

class _ReorderWiggleState extends State<_ReorderWiggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 115),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ReorderWiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = .5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (!widget.enabled) return child!;
        final direction = widget.reverse ? -1.0 : 1.0;
        return Transform.rotate(
          angle: (_controller.value - .5) * .022 * direction,
          child: child,
        );
      },
    );
  }
}

class _ActionBadge {
  const _ActionBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  factory _ActionBadge.fromMap(Map item, Map<String, int> badges) {
    final key = item['key']?.toString() ?? '';
    final colorName = item['color']?.toString() ?? '';

    return _ActionBadge(
      label: item['label']?.toString() ?? '',
      count: badges[key] ?? 0,
      color:
          colorName == 'yellow' ? AppColors.customOrange3 : AppColors.redColor,
    );
  }
}

// بناء زر وظيفة واحد
Widget _buildActionButton(
  String title,
  String route,
  int badge,
  List<_ActionBadge> badgeDescriptors, {
  bool employeePurpleStyle = false,
  Color? accentColor,
  Color? backgroundColor,
  VoidCallback? onTapOverride,
  DashboardButtonStyle dashboardStyle = DashboardButtonStyle.legacy,
}) {
  final effectiveAccent = accentColor ?? AppColors.operationalPurple;
  final isDashboard = dashboardStyle != DashboardButtonStyle.legacy;
  final isAddShortcut = title == 'إضافة اختصار';
  final dark = ThemeService.isDark.value;
  String desktopWindowTitle() {
    final count = badge > 0
        ? badge
        : badgeDescriptors.fold<int>(
            0,
            (sum, item) => sum + item.count,
          );
    final translatedTitle = title.tr;
    return count > 0 ? '$translatedTitle ($count)' : translatedTitle;
  }

  void openCurrent() {
    if (onTapOverride != null) {
      onTapOverride();
    } else if (route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  final card = Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: isDashboard
          ? DashboardDesignTokens.surfaceFor(dark)
          : employeePurpleStyle
              ? (dark
                  ? AppColors.customGreyColor
                  : backgroundColor ?? Colors.white)
              : AppColors.primaryColor,
      borderRadius: BorderRadius.circular(
        isDashboard ? DashboardDesignTokens.cardRadius.r : 10.r,
      ),
      border: isDashboard
          ? (isAddShortcut
              ? null
              : Border.all(color: DashboardDesignTokens.borderFor(dark)))
          : employeePurpleStyle
              ? Border.all(color: effectiveAccent.withValues(alpha: .28))
              : null,
      boxShadow: isDashboard && !isAddShortcut
          ? DashboardDesignTokens.shadowFor(
              dark,
              quiet: dashboardStyle == DashboardButtonStyle.allSections,
            )
          : employeePurpleStyle
              ? [
                  BoxShadow(
                    color: effectiveAccent.withValues(alpha: .06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
    ),
    child: Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDashboard) ...[
                Container(
                  width: dashboardStyle == DashboardButtonStyle.quickAccess
                      ? 36.r
                      : 32.r,
                  height: dashboardStyle == DashboardButtonStyle.quickAccess
                      ? 36.r
                      : 32.r,
                  decoration: BoxDecoration(
                    color: isAddShortcut
                        ? Colors.transparent
                        : effectiveAccent.withValues(alpha: dark ? .17 : .09),
                    borderRadius: BorderRadius.circular(
                      DashboardDesignTokens.iconRadius.r,
                    ),
                  ),
                  child: Icon(
                    _actionIcon(title),
                    color: isAddShortcut
                        ? DashboardDesignTokens.textSecondaryFor(dark)
                        : effectiveAccent,
                    size: dashboardStyle == DashboardButtonStyle.quickAccess
                        ? 22.sp
                        : 19.sp,
                  ),
                ),
                SizedBox(height: 6.h),
              ] else if (employeePurpleStyle) ...[
                Icon(
                  _actionIcon(title),
                  color: effectiveAccent,
                  size: 20.sp,
                ),
                SizedBox(height: 3.h),
              ],
              Flexible(
                child: Text(
                  title.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                        color: isDashboard
                            ? (isAddShortcut
                                ? DashboardDesignTokens.textSecondaryFor(dark)
                                : DashboardDesignTokens.textPrimaryFor(dark))
                            : employeePurpleStyle
                                ? (dark
                                    ? Colors.white
                                    : AppColors.operationalNavy)
                                : Colors.white,
                        fontSize: isDashboard
                            ? dashboardStyle == DashboardButtonStyle.quickAccess
                                ? 10.5.sp
                                : 9.5.sp
                            : employeePurpleStyle
                                ? 10.sp
                                : 12.sp,
                        fontWeight:
                            isAddShortcut ? FontWeight.w600 : FontWeight.w700,
                        height: 1.15,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (DesktopWindowService.isSupported && route.isNotEmpty)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Tooltip(
              message: 'openInNewWindow'.tr,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => DesktopWindowService.openRoute(
                  route: route,
                  title: desktopWindowTitle(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: isDashboard || employeePurpleStyle
                        ? effectiveAccent
                        : Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  return GestureDetector(
    onTap: openCurrent,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        if (isAddShortcut && isDashboard)
          CustomPaint(
            foregroundPainter: _DashedRRectPainter(
              color: DashboardDesignTokens.textSecondaryFor(dark)
                  .withValues(alpha: .32),
              radius: DashboardDesignTokens.cardRadius.r,
            ),
            child: card,
          )
        else
          card,
        if (badgeDescriptors.isNotEmpty)
          PositionedDirectional(
            top: -8.h,
            end: -6.w,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showBadgeDetails(title, badgeDescriptors),
              child: _buildBadgeDetailsButton(badgeDescriptors),
            ),
          ),
        if (badge > 0)
          PositionedDirectional(
            top: -7.h,
            end: -7.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.w),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

IconData _actionIcon(String title) {
  switch (title) {
    case 'إضافة اختصار':
      return Icons.add_rounded;
    case 'employeeTasks':
      return Icons.assignment_ind_outlined;
    case 'employeeDepartment':
      return Icons.badge_outlined;
    case 'maintenance':
      return Icons.build_outlined;
    case 'sales':
      return Icons.shopping_bag_outlined;
    case 'stock':
      return Icons.inventory_2_outlined;
    case 'privateTasks':
      return Icons.task_alt_rounded;
    case 'followUpDepartment':
      return Icons.pending_actions_outlined;
    case 'technicalSupport':
    case 'دعم الموظفين':
      return Icons.support_agent_rounded;
    case 'دعم المتجر':
      return Icons.storefront_outlined;
    case 'suggestionBox':
      return Icons.lightbulb_outline_rounded;
    case 'مركز التواصل الاجتماعي':
      return Icons.forum_outlined;
    case 'الملاحظات':
      return Icons.chat_bubble_outline_rounded;
    case 'projectManagement':
      return Icons.account_tree_outlined;
    case 'targetSetting':
      return Icons.track_changes_rounded;
    case 'debts':
      return Icons.account_balance_wallet_outlined;
    case 'generalData':
      return Icons.dataset_outlined;
    case 'boxes':
      return Icons.point_of_sale_outlined;
    case 'purchasesandReturns':
      return Icons.shopping_cart_checkout_rounded;
    case 'financialMatters':
      return Icons.account_balance_outlined;
    case 'التقارير':
      return Icons.analytics_outlined;
    case 'dailyBoxes':
      return Icons.today_outlined;
    case 'productManagement':
      return Icons.inventory_outlined;
    case 'generalSettings':
      return Icons.settings_outlined;
    case 'employeeReminders':
      return Icons.notifications_active_outlined;
    case 'smartHome':
      return Icons.home_outlined;
    case 'checksandCommitments':
      return Icons.receipt_long_outlined;
    default:
      return Icons.apps_rounded;
  }
}

Color _dashboardAccent(String title) {
  switch (title) {
    case 'sales':
      return DashboardDesignTokens.info;
    case 'boxes':
    case 'dailyBoxes':
      return DashboardDesignTokens.warning;
    case 'التقارير':
      return DashboardDesignTokens.reports;
    case 'debts':
    case 'employeeTasks':
    case 'followUpDepartment':
      return DashboardDesignTokens.danger;
    case 'stock':
    case 'generalData':
    case 'productManagement':
      return DashboardDesignTokens.success;
    case 'maintenance':
    case 'checksandCommitments':
    case 'targetSetting':
      return DashboardDesignTokens.primary;
    case 'purchasesandReturns':
    case 'employeeReminders':
      return DashboardDesignTokens.info;
    case 'projectManagement':
    case 'privateTasks':
      return DashboardDesignTokens.warning;
    default:
      return const Color(0xFF526785);
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(.8),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 6, metric.length)),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

Widget _buildBadgeDetailsButton(List<_ActionBadge> badges) {
  final total = badges.fold<int>(0, (sum, item) => sum + item.count);

  return Container(
    height: 22.h,
    padding: EdgeInsets.symmetric(horizontal: 7.w),
    constraints: BoxConstraints(minWidth: 28.w),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white, width: 1.4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: Text(
        total > 99 ? '+99' : '+$total',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    ),
  );
}

void _showBadgeDetails(String title, List<_ActionBadge> badges) {
  Get.dialog(
    Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.tr,
              textAlign: TextAlign.center,
              style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryColor,
                  ),
            ),
            SizedBox(height: 12.h),
            ...badges.map(_buildBadgeDetailsRow),
            SizedBox(height: 8.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: Get.back,
                child: Text(
                  'close'.tr,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildBadgeDetailsRow(_ActionBadge badge) {
  final textColor = badge.color == AppColors.customOrange3
      ? AppColors.secondaryColor
      : Colors.white;

  return Padding(
    padding: EdgeInsets.only(bottom: 7.h),
    child: Row(
      children: [
        Container(
          constraints: BoxConstraints(minWidth: 42.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: badge.color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge.count > 99 ? '99+' : '${badge.count}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            badge.label,
            style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor6
                      : AppColors.secondaryColor,
                ),
          ),
        ),
      ],
    ),
  );
}
