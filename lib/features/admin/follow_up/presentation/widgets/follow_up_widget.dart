import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
              followups:
                  controller.initialFollowupsFilterList.reversed.toList(),
            ),
          );
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'notify_customer'.tr,
              followups: controller.informFollowupsFilterList.reversed.toList(),
            ),
          );
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'completion_and_agreement'.tr,
              followups: controller
                  .finishAndAgreementFollowupsFilterList.reversed
                  .toList(),
            ),
          );
        }

        if (controller.showDeliveredFollowUpSection) {
          children.addAll(
            _buildSection(
              context: context,
              controller: controller,
              title: 'deliveredFollowUps'.tr,
              followups:
                  controller.archivedFollowupsFilterList.reversed.toList(),
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
              followups:
                  controller.canceledFollowupsFilterList.reversed.toList(),
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
              followups:
                  controller.deletedFollowupsFilterList.reversed.toList(),
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
    return [
      _FollowUpSectionHeader(title: title, count: followups.length),
      if (followups.isEmpty)
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
        )
      else
        ...followups.map(
          (followup) => _FollowUpCard(
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
          ),
        ),
      SizedBox(height: 12.h),
    ];
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: readOnly ? null : onOpen,
        onLongPress: readOnly ? null : () => _showFollowUpActions(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.h),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarButton(imageUrl: _avatarUrl),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _personName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            _StatusPill(
                              showArchiveStatus: showArchiveStatus,
                              status: followup.followupStatus,
                              isCanceled: followup.isCanceled,
                              isDeleted: followup.isDeleted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (followup.productName.trim().isNotEmpty) ...[
                SizedBox(height: 7.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkColor.withValues(alpha: 0.45)
                        : AppColors.customGreyColor7.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.operationalCardBorder
                          .withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    followup.productName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              Row(
                children: [
                  _MiniChip(
                    label: _personType,
                    color: AppColors.operationalPurple,
                    icon: Icons.person_outline_rounded,
                  ),
                  SizedBox(width: 4.w),
                  _MiniChip(
                    label: showData(followup.createdAt),
                    color: AppColors.customGreyColor5,
                    icon: Icons.event_note_outlined,
                  ),
                  if (followup.createdByName.isNotEmpty) ...[
                    SizedBox(width: 4.w),
                    Expanded(
                      child: _MiniChip(
                        label: '${'createdBy'.tr}: ${followup.createdByName}',
                        color: AppColors.customGreen1,
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: PersonAvatarHelper.isPlaceholder(imageUrl)
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
      child: PersonAvatarImage(
        imageUrl: imageUrl,
        height: 40.h,
        width: 40.w,
        fit: BoxFit.cover,
        circular: true,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.showArchiveStatus,
    required this.status,
    required this.isCanceled,
    required this.isDeleted,
  });

  final bool showArchiveStatus;
  final String status;
  final bool isCanceled;
  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == 'delivered';
    final isRejected = status == 'rejected';
    final activeLabel = status == 'initial'
        ? 'initialFollowUp'.tr
        : status == 'inform'
            ? 'notify_customer'.tr
            : status == 'agreement'
                ? 'completion_and_agreement'.tr
                : 'currentFollowUps'.tr;
    final label = showArchiveStatus
        ? isDeleted
            ? 'deletedFollowUps'.tr
            : isCanceled
                ? 'canceledFollowUps'.tr
                : isDelivered
                    ? 'sale_completed'.tr
                    : isRejected
                        ? 'sale_rejected'.tr
                        : 'canceledFollowUps'.tr
        : activeLabel;
    final color = showArchiveStatus
        ? isDelivered
            ? AppColors.customGreen1
            : AppColors.redColor
        : AppColors.primaryColor;

    return Container(
      constraints: BoxConstraints(maxWidth: 86.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: color,
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
