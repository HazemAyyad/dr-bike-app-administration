import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/person_avatar_helper.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/person_avatar_image.dart';
import '../../../../../core/widgets/skeleton_loading.dart';
import '../../data/models/followup_modle.dart';
import '../controllers/follow_up_controller.dart';
import 'cancel_dialog.dart';
import 'contact_dialog.dart';

class FollowUpWidget extends StatelessWidget {
  const FollowUpWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FollowUpController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const _FollowUpSkeletonSliver();
        }

        if (controller.visibleFilteredCount == 0) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }

        final children = <Widget>[];

        if (controller.showActiveFollowUpSections) {
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'initialFollowUp'.tr,
              followups: controller.initialFollowupsFilterList,
            ),
          );
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'notify_customer'.tr,
              followups: controller.informFollowupsFilterList,
            ),
          );
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'completion_and_agreement'.tr,
              followups: controller.finishAndAgreementFollowupsFilterList,
            ),
          );
        }

        if (controller.showDeliveredFollowUpSection) {
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'deliveredFollowUps'.tr,
              followups: controller.archivedFollowupsFilterList,
              showArchiveStatus: true,
            ),
          );
        }

        if (controller.showCanceledFollowUpSection) {
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'canceledFollowUps'.tr,
              followups: controller.canceledFollowupsFilterList,
              showArchiveStatus: true,
            ),
          );
        }

        if (controller.showDeletedFollowUpSection) {
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'deletedFollowUps'.tr,
              followups: controller.deletedFollowupsFilterList,
              showArchiveStatus: true,
              readOnly: true,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildListDelegate(children),
        );
      },
    );
  }

  List<Widget> _buildSection({
    required BuildContext context,
    required FollowUpController controller,
    required String title,
    required List<FollowupModel> followups,
    bool showArchiveStatus = false,
    bool readOnly = false,
  }) {
    final children = <Widget>[
      _FollowUpSectionHeader(title: title, count: followups.length),
    ];

    if (followups.isEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 8.h),
          child: Text(
            'noData'.tr,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: ThemeService.isDark.value
                  ? AppColors.customGreyColor3
                  : AppColors.customGreyColor5,
            ),
          ),
        ),
      );
      children.add(SizedBox(height: 12.h));
      return children;
    }

    final grouped = _groupFollowupsByDate(followups);
    for (final key in grouped.keys.toList().reversed) {
      children.add(_FollowUpDateHeader(title: key));
      children.addAll(
        grouped[key]!.reversed.map(
          (followup) {
            return _FollowUpCard(
              followup: followup,
              showArchiveStatus: showArchiveStatus,
              readOnly: readOnly,
              onOpen: () => controller.getFollowUpDetails(
                followupId: followup.id.toString(),
              ),
              onContact: () => Get.dialog(
                ContactDialog(
                  phone: followup.customerPhone.isNotEmpty
                      ? followup.customerPhone
                      : followup.sellerPhone,
                ),
              ),
              onCancel: () => Get.dialog(
                CancelDialog(followupId: followup.id.toString()),
              ),
              onViewLog: () => _showActivityLogDialog(
                context,
                controller,
                followup.id.toString(),
              ),
              onDelete: () => _showDeleteDialog(
                context,
                controller,
                followup.id.toString(),
              ),
            );
          },
        ),
      );
    }

    children.add(SizedBox(height: 12.h));
    return children;
  }

  Map<String, List<FollowupModel>> _groupFollowupsByDate(
    List<FollowupModel> followups,
  ) {
    final grouped = <String, List<FollowupModel>>{};
    final sorted = followups.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final followup in sorted) {
      final dayName =
          DateFormat.EEEE(Get.locale!.languageCode).format(followup.createdAt);
      final dateKey =
          '$dayName ${followup.createdAt.year}-${followup.createdAt.month}-${followup.createdAt.day}';
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(followup);
    }

    return grouped;
  }
}

class _FollowUpDateHeader extends StatelessWidget {
  const _FollowUpDateHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(28.w, 6.h, 28.w, 5.h),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class _FollowUpSectionHeader extends StatelessWidget {
  const _FollowUpSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(28.w, 14.h, 28.w, 6.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.whiteColor : AppColors.secondaryColor,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.followup,
    required this.showArchiveStatus,
    required this.readOnly,
    required this.onOpen,
    required this.onContact,
    required this.onCancel,
    required this.onViewLog,
    required this.onDelete,
  });

  final FollowupModel followup;
  final bool showArchiveStatus;
  final bool readOnly;
  final VoidCallback onOpen;
  final VoidCallback onContact;
  final VoidCallback onCancel;
  final VoidCallback onViewLog;
  final VoidCallback onDelete;

  String get _personName => followup.customerName.isNotEmpty
      ? followup.customerName
      : followup.sellerName;

  String get _avatarUrl => followup.customerName.isNotEmpty
      ? followup.customerImg
      : followup.sellerImg;

  String get _personType =>
      followup.customerName.isNotEmpty ? 'customer'.tr : 'seller'.tr;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final titleColor =
        isDark ? AppColors.whiteColor : AppColors.operationalNavy;
    final subColor =
        isDark ? AppColors.customGreyColor3 : AppColors.customGreyColor5;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: readOnly ? null : onOpen,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.customGreyColor : AppColors.whiteColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.operationalNavy.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarButton(imageUrl: _avatarUrl),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _personName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: titleColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        _MiniChip(
                          label: _personType,
                          color: AppColors.operationalPurple,
                          icon: Icons.person_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                  if (followup.createdByName.isNotEmpty)
                    IconButton(
                      tooltip: 'createdBy'.tr,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showCreatorDialog(),
                      icon: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: AppColors.customGreen1.withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          size: 16.sp,
                          color: AppColors.customGreen1,
                        ),
                      ),
                    ),
                ],
              ),
              if (followup.productName.trim().isNotEmpty) ...[
                SizedBox(height: 7.h),
                _FollowUpDetailsPreview(
                  details: followup.productName.trim(),
                  color: subColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return _SwipeFollowUpCard(
      enabled: !readOnly,
      onCall: onContact,
      onOptions: () => _showFollowUpActions(context),
      child: card,
    );
  }

  void _showCreatorDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: ThemeService.isDark.value
            ? AppColors.darkColor
            : AppColors.whiteColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        title: Row(
          children: [
            const Icon(Icons.badge_outlined, color: AppColors.customGreen1),
            SizedBox(width: 8.w),
            Expanded(child: Text('createdBy'.tr)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              followup.createdByName,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6.h),
            Text(
              DateFormat('yyyy-MM-dd').format(followup.createdAt),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.customGreyColor5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('close'.tr)),
        ],
      ),
    );
  }

  void _showFollowUpActions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _personName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.operationalNavy,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                followup.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: ThemeService.isDark.value
                      ? AppColors.customGreyColor3
                      : AppColors.customGreyColor5,
                ),
              ),
              SizedBox(height: 10.h),
              _ActionTile(
                icon: Icons.open_in_new_rounded,
                label: 'details'.tr,
                onTap: () {
                  Get.back();
                  onOpen();
                },
              ),
              _ActionTile(
                icon: Icons.phone_outlined,
                label: 'directContact'.tr,
                onTap: () {
                  Get.back();
                  onContact();
                },
              ),
              _ActionTile(
                icon: Icons.history_rounded,
                label: 'viewActivityLog'.tr,
                onTap: () {
                  Get.back();
                  onViewLog();
                },
              ),
              if (!showArchiveStatus)
                _ActionTile(
                  icon: Icons.block_rounded,
                  label: 'cancelFollowUp'.tr,
                  color: AppColors.redColor,
                  onTap: () {
                    Get.back();
                    onCancel();
                  },
                ),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'delete'.tr,
                color: AppColors.redColor,
                onTap: () {
                  Get.back();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeFollowUpCard extends StatefulWidget {
  const _SwipeFollowUpCard({
    required this.child,
    required this.enabled,
    required this.onCall,
    required this.onOptions,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onCall;
  final VoidCallback onOptions;

  @override
  State<_SwipeFollowUpCard> createState() => _SwipeFollowUpCardState();
}

class _SwipeFollowUpCardState extends State<_SwipeFollowUpCard> {
  static const double _revealWidth = 146;
  static const double _dragResistance = .65;
  static const Duration _settleDuration = Duration(milliseconds: 320);
  double _offset = 0;

  @override
  void didUpdateWidget(covariant _SwipeFollowUpCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && _offset != 0) {
      _offset = 0;
    }
  }

  void _update(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _offset = (_offset + details.delta.dx * _dragResistance)
          .clamp(-_revealWidth, _revealWidth);
    });
  }

  void _finish(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen =
        _offset.abs() > _revealWidth * .34 || velocity.abs() > 500;
    setState(() {
      if (!shouldOpen) {
        _offset = 0;
      } else {
        final direction = velocity.abs() > 500 ? velocity.sign : _offset.sign;
        _offset = direction * _revealWidth;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          alignment:
              _offset >= 0 ? Alignment.centerLeft : Alignment.centerRight,
          children: [
            if (widget.enabled)
              Positioned(
                left: _offset >= 0 ? 0 : null,
                right: _offset < 0 ? 0 : null,
                child: Row(
                  children: [
                    _FollowUpSwipeAction(
                      icon: Icons.phone_outlined,
                      label: 'اتصال',
                      color: const Color(0xFF0F766E),
                      onTap: () {
                        setState(() => _offset = 0);
                        widget.onCall();
                      },
                    ),
                    SizedBox(width: 5.w),
                    _FollowUpSwipeAction(
                      icon: Icons.more_horiz_rounded,
                      label: 'الخيارات',
                      color: AppColors.primaryColor,
                      onTap: () {
                        setState(() => _offset = 0);
                        widget.onOptions();
                      },
                    ),
                  ],
                ),
              ),
            AnimatedContainer(
              duration: _settleDuration,
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: widget.enabled ? _update : null,
                onHorizontalDragEnd: widget.enabled ? _finish : null,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpSwipeAction extends StatelessWidget {
  const _FollowUpSwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(11.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.r),
        child: SizedBox(
          width: 66.w,
          height: 66.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20.sp),
              SizedBox(height: 3.h),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ??
        (ThemeService.isDark.value
            ? AppColors.whiteColor
            : AppColors.blackColor);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20.sp, color: itemColor),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: itemColor,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 145.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.sp, color: color),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpDetailsPreview extends StatelessWidget {
  const _FollowUpDetailsPreview({
    required this.details,
    required this.color,
  });

  final String details;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkColor.withValues(alpha: 0.35)
            : AppColors.customGreyColor7.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(
          color: AppColors.operationalCardBorder.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        details,
        style: TextStyle(
          fontSize: 11.sp,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

void _showActivityLogDialog(
  BuildContext context,
  FollowUpController controller,
  String followupId,
) async {
  Get.dialog(
    const Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  final logs = await controller.getFollowUpActivityLogs(followupId: followupId);
  if (Get.isDialogOpen == true) {
    Get.back();
  }

  Get.dialog(
    AlertDialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      title: Text(
        'followUpActivityLog'.tr,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: logs.isEmpty
            ? Text('noData'.tr)
            : ListView.separated(
                shrinkWrap: true,
                itemCount: logs.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final description = log['description']?.toString() ?? '';
                  final actorName = log['actor_name']?.toString() ?? '';
                  final createdAt = log['created_at']?.toString() ?? '';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 18.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          [
                            if (description.isNotEmpty) description,
                            if (actorName.isNotEmpty) actorName,
                            if (createdAt.isNotEmpty) createdAt,
                          ].join('\n'),
                          style: TextStyle(fontSize: 12.sp, height: 1.35),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('cancel'.tr),
        ),
      ],
    ),
  );
}

void _showDeleteDialog(
  BuildContext context,
  FollowUpController controller,
  String followupId,
) {
  Get.dialog(
    AlertDialog(
      backgroundColor: ThemeService.isDark.value
          ? AppColors.darkColor
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      title: Text(
        'areYouSure'.tr,
        style: TextStyle(
          color: AppColors.redColor,
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            controller.deleteFollowUp(followupId: followupId);
          },
          child: Text(
            'delete'.tr,
            style: const TextStyle(color: AppColors.redColor),
          ),
        ),
      ],
    ),
  );
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = PersonAvatarHelper.isPlaceholder(imageUrl);
    return GestureDetector(
      onTap: isPlaceholder
          ? null
          : () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                barrierColor: Colors.black.withAlpha(128),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return FullScreenZoomImage(imageUrl: imageUrl);
                },
              );
            },
      child: Container(
        width: 42.w,
        height: 42.w,
        padding: EdgeInsets.all(1.4.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isPlaceholder
                ? AppColors.primaryColor.withValues(alpha: 0.45)
                : AppColors.operationalCardBorder,
            width: 1.2.w,
          ),
        ),
        child: PersonAvatarImage(
          imageUrl: imageUrl,
          height: 39.h,
          width: 39.w,
          fit: BoxFit.cover,
          circular: true,
        ),
      ),
    );
  }
}

class _FollowUpSkeletonSliver extends StatelessWidget {
  const _FollowUpSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 28.w, vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SkeletonCircle(size: 40.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.62 : 0.78,
                      child: SkeletonBlock(
                        width: double.infinity,
                        height: 11.h,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    SkeletonBlock(width: double.infinity, height: 9.h),
                    SizedBox(height: 5.h),
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.42 : 0.52,
                      child: SkeletonBlock(
                        width: double.infinity,
                        height: 8.h,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              SkeletonBlock(width: 32.w, height: 32.h, radius: 16),
            ],
          ),
        );
      },
    );
  }
}
