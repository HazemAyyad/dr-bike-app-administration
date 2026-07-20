import 'package:doctorbike/core/helpers/app_button.dart';
import 'package:doctorbike/core/helpers/person_avatar_helper.dart';
import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/core/utils/assets_manger.dart';
import 'package:doctorbike/core/widgets/person_avatar_image.dart';
import 'package:doctorbike/features/admin/debts/data/models/debt_ledger_models.dart';
import 'package:doctorbike/features/admin/debts/data/repositories/debt_ledger_implement.dart';
import 'package:doctorbike/features/admin/debts/presentation/ledger/ledger_activity_section.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/full_screen_image_viewer.dart';
import '../../../../../core/helpers/open_apps.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/general_data_list_controller.dart';

class GlobalData extends GetView<GeneralDataListController> {
  const GlobalData({Key? key, required this.employee}) : super(key: key);

  final GeneralDataModel employee;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: () => _openEditor(),
        onLongPress: () {
          Get.dialog(
            AlertDialog(
              backgroundColor: ThemeService.isDark.value
                  ? AppColors.darkColor
                  : AppColors.whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      launchDialer(phoneNumber: employee.phone);
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 5.h),
                        const Icon(
                          Icons.phone_outlined,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'directContact'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blackColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      launchWhatsApp(phoneNumber: employee.phone);
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          AssetsManager.whatsapp,
                          height: 30.h,
                          width: 30.w,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'directContact'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blackColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  InkWell(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    onTap: () {
                      Get.back();
                      Get.dialog(
                        Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          backgroundColor: ThemeService.isDark.value
                              ? AppColors.darkColor
                              : AppColors.whiteColor,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'areYouSure'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Colors.red,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          isSafeArea: false,
                                          text: 'cancel'.tr,
                                          color: Colors.red,
                                          onPressed: () => Get.back(),
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: AppButton(
                                            isSafeArea: false,
                                            text: 'delete'.tr,
                                            color: Colors.transparent,
                                            textColor: Colors.red,
                                            borderColor: Colors.red,
                                            onPressed: () {
                                              controller.deletePerson(
                                                customerId: controller
                                                            .currentTab.value ==
                                                        1
                                                    ? employee.id.toString()
                                                    : employee.type ==
                                                            'customer'
                                                        ? employee.id.toString()
                                                        : '',
                                                sellerId: controller
                                                            .currentTab.value ==
                                                        0
                                                    ? employee.id.toString()
                                                    : employee.type == 'seller'
                                                        ? employee.id.toString()
                                                        : '',
                                              );
                                              Get.back();
                                            }),
                                      ),
                                    ],
                                  )
                                ]),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        SizedBox(width: 5.h),
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'delete'.tr,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Material(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: ThemeService.isDark.value
                    ? AppColors.customGreyColor
                    : Colors.grey.shade300,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8.r),
              onTap: _openEditor,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final avatar = _AvatarButton(
                      imageUrl: employee.idImage,
                      onTap: () => _showIdImage(context),
                    );
                    final identity = _IdentityBlock(
                      employee: employee,
                      isComplete: controller.currentTab.value != 2,
                    );
                    final phone = _InfoCell(
                      label: employee.phone.isEmpty ? '-' : employee.phone,
                    );
                    final job = _InfoCell(
                      label:
                          employee.jobTitle.isEmpty ? '-' : employee.jobTitle,
                    );
                    final actions = _RowActions(
                      onHistory: () => _showPersonHistory(context),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              avatar,
                              SizedBox(width: 10.w),
                              Expanded(child: identity),
                              actions,
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 4.h,
                            children: [phone, job],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        avatar,
                        SizedBox(width: 10.w),
                        Expanded(flex: 3, child: identity),
                        Expanded(flex: 2, child: phone),
                        SizedBox(width: 8.w),
                        Expanded(flex: 2, child: job),
                        SizedBox(width: 8.w),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditor() {
    controller.clearForm();
    controller.isEdit.value = true;
    controller.getPersonData(
      customerId: controller.currentTab.value == 1
          ? employee.id.toString()
          : employee.type == 'customer'
              ? employee.id.toString()
              : '',
      sellerId: controller.currentTab.value == 0
          ? employee.id.toString()
          : employee.type == 'seller'
              ? employee.id.toString()
              : '',
    );
    Get.toNamed(
      AppRoutes.ADDNEWCUSTOMERSCREEN,
      arguments: {
        'employeeType': employee.type,
        'employeeId': employee.id.toString(),
        'sellerId': employee.id.toString(),
      },
    );
  }

  void _showIdImage(BuildContext context) {
    if (PersonAvatarHelper.isPlaceholder(employee.idImage)) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(128),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return FullScreenZoomImage(
          imageUrl: employee.idImage!,
        );
      },
    );
  }

  bool get _isCustomer {
    if (controller.currentTab.value == 1) return true;
    if (controller.currentTab.value == 0) return false;
    return employee.type == 'customer';
  }

  Future<List<LedgerActivityEntry>> _loadHistory() async {
    AppDependencyRegistry.ensureDebtsLedger();
    final result = await Get.find<DebtLedgerImplement>().getPersonActivity(
      customerId: _isCustomer ? employee.id : null,
      sellerId: _isCustomer ? null : employee.id,
    );

    return result.fold(
      (failure) => throw Exception(failure.errMessage),
      (list) => list,
    );
  }

  void _showPersonHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersonHistorySheet(
        title: employee.name,
        loadHistory: _loadHistory,
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.imageUrl,
    required this.onTap,
  });

  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: PersonAvatarHelper.isPlaceholder(imageUrl) ? null : onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: PersonAvatarImage(
        imageUrl: imageUrl,
        height: 38.h,
        width: 38.w,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.employee,
    required this.isComplete,
  });

  final GeneralDataModel employee;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CompletionBadge(isComplete: isComplete),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                employee.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: ThemeService.isDark.value
                      ? AppColors.whiteColor
                      : AppColors.darkColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color =
        isComplete ? AppColors.primaryColor : AppColors.customGreyColor3;
    final label = isComplete ? 'كامل البيانات' : 'بيانات غير مكتملة';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: 17.w,
          height: 17.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 12.sp,
          ),
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 190.w),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: ThemeService.isDark.value
              ? AppColors.whiteColor
              : AppColors.customGreyColor5,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onHistory,
  });

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'ledgerActivityLog'.tr,
      child: Material(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onHistory,
          child: SizedBox(
            width: 32.w,
            height: 32.w,
            child: Icon(
              Icons.history_rounded,
              color: AppColors.primaryColor,
              size: 18.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonHistorySheet extends StatefulWidget {
  const _PersonHistorySheet({
    required this.title,
    required this.loadHistory,
  });

  final String title;
  final Future<List<LedgerActivityEntry>> Function() loadHistory;

  @override
  State<_PersonHistorySheet> createState() => _PersonHistorySheetState();
}

class _PersonHistorySheetState extends State<_PersonHistorySheet> {
  late Future<List<LedgerActivityEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadHistory();
  }

  void _reload() {
    setState(() {
      _future = widget.loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.85.sh),
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.customGreyColor4 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 8.h),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${'ledgerActivityLog'.tr} - ${widget.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            Flexible(
              child: FutureBuilder<List<LedgerActivityEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.sp),
                          ),
                          SizedBox(height: 12.h),
                          AppButton(
                            text: 'tryAgain'.tr,
                            onPressed: _reload,
                          ),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: LedgerActivitySection(
                      entries: snapshot.data ?? const [],
                      showTitle: false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
