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

  List<FollowupModel> _activeList(FollowUpController controller) {
    if (controller.currentTab.value == 0) {
      return controller.initialFollowupsFilterList.reversed.toList();
    }
    if (controller.currentTab.value == 1) {
      return controller.informFollowupsFilterList.reversed.toList();
    }
    if (controller.currentTab.value == 2) {
      return controller.finishAndAgreementFollowupsFilterList.reversed.toList();
    }
    return controller.archivedFollowupsFilterList.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FollowUpController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const _FollowUpSkeletonSliver();
        }

        final followups = _activeList(controller);
        if (followups.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: ShowNoData()),
          );
        }

        return SliverList.builder(
          itemCount: followups.length,
          itemBuilder: (context, index) {
            return _FollowUpCard(
              followup: followups[index],
              showArchiveStatus: controller.currentTab.value == 3,
              onOpen: () => controller.getFollowUpDetails(
                followupId: followups[index].id.toString(),
              ),
              onCancel: () => Get.dialog(
                CancelDialog(followupId: followups[index].id.toString()),
              ),
              onViewLog: () => _showActivityLogDialog(
                context,
                controller,
                followups[index].id.toString(),
              ),
              onDelete: () => _showDeleteDialog(
                context,
                controller,
                followups[index].id.toString(),
              ),
            );
          },
        );
      },
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.followup,
    required this.showArchiveStatus,
    required this.onOpen,
    required this.onCancel,
    required this.onViewLog,
    required this.onDelete,
  });

  final FollowupModel followup;
  final bool showArchiveStatus;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final VoidCallback onViewLog;
  final VoidCallback onDelete;

  String get _personName => followup.customerName.isNotEmpty
      ? followup.customerName
      : followup.sellerName;

  String get _personPhone => followup.customerPhone.isNotEmpty
      ? followup.customerPhone
      : followup.sellerPhone;

  String get _avatarUrl => followup.customerName.isNotEmpty
      ? followup.customerImg
      : followup.sellerImg;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    final titleColor = isDark ? AppColors.whiteColor : AppColors.secondaryColor;
    final subColor =
        isDark ? AppColors.customGreyColor3 : AppColors.customGreyColor5;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 28.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor : AppColors.whiteColor2,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    followup.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: subColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          showData(followup.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ),
                      if (showArchiveStatus) ...[
                        SizedBox(width: 6.w),
                        _StatusPill(
                          showArchiveStatus: showArchiveStatus,
                          status: followup.followupStatus,
                        ),
                      ],
                    ],
                  ),
                  if (followup.createdByName.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      '${'createdBy'.tr}: ${followup.createdByName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 6.w),
            _FollowUpMenuButton(
              showCancel: !showArchiveStatus,
              onOpen: onOpen,
              onContact: () => Get.dialog(
                ContactDialog(phone: _personPhone),
              ),
              onCancel: onCancel,
              onViewLog: onViewLog,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpMenuButton extends StatelessWidget {
  const _FollowUpMenuButton({
    required this.showCancel,
    required this.onOpen,
    required this.onContact,
    required this.onCancel,
    required this.onViewLog,
    required this.onDelete,
  });

  final bool showCancel;
  final VoidCallback onOpen;
  final VoidCallback onContact;
  final VoidCallback onCancel;
  final VoidCallback onViewLog;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32.w,
      height: 32.h,
      child: PopupMenuButton<String>(
        tooltip: 'options'.tr,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert_rounded,
          color: ThemeService.isDark.value
              ? AppColors.whiteColor
              : AppColors.secondaryColor,
          size: 22.sp,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        onSelected: (value) {
          if (value == 'open') onOpen();
          if (value == 'contact') onContact();
          if (value == 'log') onViewLog();
          if (value == 'cancel') onCancel();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'open',
            child:
                _MenuItem(icon: Icons.open_in_new_rounded, label: 'details'.tr),
          ),
          PopupMenuItem(
            value: 'contact',
            child: _MenuItem(
              icon: Icons.phone_outlined,
              label: 'directContact'.tr,
            ),
          ),
          PopupMenuItem(
            value: 'log',
            child: _MenuItem(
              icon: Icons.history_rounded,
              label: 'viewActivityLog'.tr,
            ),
          ),
          if (showCancel)
            PopupMenuItem(
              value: 'cancel',
              child: _MenuItem(
                icon: Icons.block_rounded,
                label: 'cancelFollowUp'.tr,
                color: AppColors.redColor,
              ),
            ),
          PopupMenuItem(
            value: 'delete',
            child: _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'delete'.tr,
              color: AppColors.redColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ??
        (ThemeService.isDark.value
            ? AppColors.whiteColor
            : AppColors.blackColor);
    return SizedBox(
      width: 190.w,
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: itemColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: itemColor,
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
  });

  final bool showArchiveStatus;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == 'delivered';
    final activeLabel = status == 'initial'
        ? 'initialFollowUp'.tr
        : status == 'inform'
            ? 'notify_customer'.tr
            : status == 'agreement'
                ? 'completion_and_agreement'.tr
                : 'currentFollowUps'.tr;
    final label = showArchiveStatus
        ? isDelivered
            ? 'sale_completed'.tr
            : 'sale_rejected'.tr
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
