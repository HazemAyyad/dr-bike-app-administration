import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:doctorbike/core/helpers/app_button.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_text_field.dart';
import '../../../../../core/helpers/show_image_or_video.dart';
import '../../../../../core/helpers/showtime.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../../../whatsapp_center/presentation/views/whatsapp_camera_screen.dart';
import '../controllers/maintenance_controller.dart';
import '../widgets/maintenance_products_section.dart';
import '../widgets/next_back_button.dart';

class NewMaintenanceScreen extends StatelessWidget {
  const NewMaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceController>(
      builder: (controller) => Scaffold(
        appBar: CustomAppBar(
          title:
              controller.isEdit.value ? 'editMaintenance' : 'createMaintenance',
          action: false,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GetBuilder<MaintenanceController>(
            builder: (controller) {
              if (controller.isEditLoading.value) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 200.h),
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              return Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    if (controller.isEdit.value) ...[
                      _MaintenanceAutoSaveStatus(controller: controller),
                      SizedBox(height: 8.h),
                    ],
                    _MaintenanceStageTitle(controller: controller),
                    SizedBox(height: 12.h),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: CustomCheckBox(
                              title: 'seller'.tr,
                              value: RxBool(controller.selectedSellers.value),
                              onChanged: (val) {
                                controller.getAllCustomersAndSellers();
                                if (!controller.isEdit.value) {
                                  controller.selectedSellers.value = true;
                                  controller.partnerIdController.clear();
                                }
                                controller.scheduleAutoSave();
                              },
                            ),
                          ),
                          Expanded(
                            child: CustomCheckBox(
                              title: 'customer'.tr,
                              value: RxBool(!controller.selectedSellers.value),
                              onChanged: (val) {
                                controller.getAllCustomersAndSellers();
                                if (!controller.isEdit.value) {
                                  controller.selectedSellers.value = false;
                                  controller.partnerIdController.clear();
                                }
                                controller.scheduleAutoSave();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _MaintenancePartnerSearch(controller: controller),
                    SizedBox(height: 10.h),
                    _MaintenanceDeliveryDateTimeFields(controller: controller),
                    SizedBox(height: 10.h),
                    CustomTextField(
                      validator: (value) => null,
                      label: 'details',
                      hintText: 'detailsExample',
                      controller: controller.descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChanged: (value) {
                        controller.scheduleAutoSave();
                        controller.searchServiceSuggestions(value);
                      },
                    ),
                    _MaintenanceServiceSuggestions(controller: controller),
                    SizedBox(height: 12.h),
                    MaintenanceProductsSection(controller: controller),
                    SizedBox(height: 10.h),
                    _MaintenanceMediaPicker(controller: controller),
                    SizedBox(height: 20.h),
                    if (controller.isDelivered.value && controller.isEdit.value)
                      AppButton(
                        isLoading: controller.isLoading,
                        text: 'save',
                        onPressed: () {
                          controller.createMaintenance(
                            step: controller.selectedStep.value,
                            maintenanceId: controller.maintenanceId,
                            isSave: true,
                          );
                        },
                      ),
                    if (!controller.isDelivered.value)
                      NextBackButton(
                        isLoading: controller.isLoading,
                        endTitle: 'delivered',
                        totalSteps: controller.timeLineSteps.length.obs,
                        selectedStep: controller.selectedStep,
                        onPressedBack: controller.prevStep,
                        onPressedNext: controller.nextStep,
                      ),
                    if (!controller.isDelivered.value &&
                        !controller.isEdit.value &&
                        (controller.maintenanceId == null ||
                            controller.maintenanceId!.isEmpty)) ...[
                      SizedBox(height: 10.h),
                      AppButton(
                        isLoading: controller.isLoading,
                        text: 'save',
                        onPressed: () {
                          controller.createMaintenance(
                            step: controller.selectedStep.value,
                            maintenanceId: controller.maintenanceId,
                          );
                        },
                      ),
                    ],
                    SizedBox(height: 16.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenanceServiceSuggestions extends StatelessWidget {
  const _MaintenanceServiceSuggestions({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceController>(
      id: 'maintenanceServiceSuggestions',
      builder: (_) {
        final suggestions = controller.serviceSuggestions;
        if (suggestions.isEmpty ||
            controller.selectedStep.value >= 4 ||
            controller.isDelivered.value) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 6.h),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.operationalCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: suggestions
                .take(4)
                .map(
                  (service) => ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.home_repair_service_outlined,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    title: Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${service.price.toStringAsFixed(2)} شيكل',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    onTap: () =>
                        controller.addMaintenanceServiceToDetails(service),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _MaintenancePartnerSearch extends StatefulWidget {
  const _MaintenancePartnerSearch({required this.controller});

  final MaintenanceController controller;

  @override
  State<_MaintenancePartnerSearch> createState() =>
      _MaintenancePartnerSearchState();
}

class _MaintenancePartnerSearchState extends State<_MaintenancePartnerSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;
  bool? _lastSelectedSellers;

  MaintenanceController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) return;
      setState(() => _showResults = true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncSelectedText() {
    if (_focusNode.hasFocus || _showResults) return;
    final selected = _selectedPartner();
    final text = selected?.name ?? '';
    if (_searchController.text != text) {
      _searchController.text = text;
    }
  }

  dynamic _selectedPartner() {
    final list = controller.selectedSellers.value
        ? controller.allSellersList
        : controller.allCustomersList;
    return list.firstWhereOrNull(
      (item) => item.id.toString() == controller.partnerIdController.text,
    );
  }

  List<dynamic> _filteredPartners() {
    final list = controller.selectedSellers.value
        ? controller.allSellersList
        : controller.allCustomersList;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return list.take(8).toList();
    return list
        .where((item) {
          final haystack = '${item.name} ${item.phone}'.toLowerCase();
          return haystack.contains(query);
        })
        .take(12)
        .toList();
  }

  Future<void> _addPartner() async {
    if (controller.isEdit.value) return;
    await Get.toNamed(
      AppRoutes.ADDNEWCUSTOMERSCREEN,
      arguments: {
        'sellerId': '',
        'employeeId': '',
        'popOnceOnSuccess': true,
        'employeeType':
            controller.selectedSellers.value ? 'seller' : 'customer',
      },
    );
    controller.getAllCustomersAndSellers();
    if (!mounted) return;
    setState(() => _showResults = true);
    _focusNode.requestFocus();
  }

  void _selectPartner(dynamic item) {
    controller.partnerIdController.text = item.id.toString();
    _searchController.text = item.name;
    controller.scheduleAutoSave();
    _focusNode.unfocus();
    setState(() => _showResults = false);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_lastSelectedSellers != controller.selectedSellers.value) {
        _lastSelectedSellers = controller.selectedSellers.value;
        _searchController.clear();
        _showResults = false;
      }
      _syncSelectedText();
      final items = _filteredPartners();
      final enabled = !controller.isEdit.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'customerName'.tr,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.customGreyColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                '*',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.red,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  enabled: enabled,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.customGreyColor7,
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'customerNameExample'.tr,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (_) => controller.partnerIdController.text.isEmpty
                      ? 'customerName'.tr
                      : null,
                  onChanged: (_) {
                    controller.partnerIdController.clear();
                    setState(() => _showResults = true);
                  },
                ),
              ),
              SizedBox(width: 6.w),
              IconButton(
                tooltip: controller.selectedSellers.value
                    ? 'seller'.tr
                    : 'customer'.tr,
                onPressed: enabled ? _addPartner : null,
                icon: Icon(
                  Icons.add_circle_sharp,
                  color:
                      enabled ? AppColors.primaryColor : Colors.grey.shade400,
                  size: 30.sp,
                ),
              ),
            ],
          ),
          if (_showResults && enabled)
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: 210.h),
              margin: EdgeInsets.only(top: 6.h, left: 42.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.operationalCardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: items.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Text(
                        'noData'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return ListTile(
                          dense: true,
                          minLeadingWidth: 24.w,
                          leading: Icon(
                            controller.selectedSellers.value
                                ? Icons.storefront_outlined
                                : Icons.person_outline_rounded,
                            size: 20.sp,
                            color: AppColors.primaryColor,
                          ),
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: item.phone.toString().isEmpty
                              ? null
                              : Text(
                                  item.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.sp),
                                ),
                          onTap: () => _selectPartner(item),
                        );
                      },
                    ),
            ),
        ],
      );
    });
  }
}

class _MaintenanceAutoSaveStatus extends StatelessWidget {
  const _MaintenanceAutoSaveStatus({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceController>(
      id: 'maintenanceAutoSaveStatus',
      builder: (_) {
        final isSaving = controller.isAutoSaving.value;
        final hasError = controller.hasAutoSaveError.value;
        return Align(
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Row(
              key: ValueKey('$isSaving-$hasError'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSaving)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18.sp,
                    color:
                        hasError ? AppColors.redColor : AppColors.customGreen1,
                  ),
                SizedBox(width: 6.w),
                Text(
                  isSaving
                      ? 'saving'.tr
                      : hasError
                          ? 'error'.tr
                          : 'saved'.tr,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: hasError
                        ? AppColors.redColor
                        : AppColors.customGreyColor5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MaintenanceStageTitle extends StatelessWidget {
  const _MaintenanceStageTitle({required this.controller});

  final MaintenanceController controller;

  String _labelForStep(int step) {
    if (step == 1) return 'newMaintenance'.tr;
    if (step == 2) return 'inProgress'.tr;
    if (step == 3) return 'readyToDeliver'.tr;
    return 'delivered'.tr;
  }

  Color _colorForStep(int step) {
    if (step == 1) return AppColors.primaryColor;
    if (step == 2) return Colors.orange;
    if (step == 3) return AppColors.customGreen1;
    return AppColors.customGreen1;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final step = controller.selectedStep.value;
        final color = _colorForStep(step);
        return Row(
          children: [
            Container(
              width: 6.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _labelForStep(step),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MaintenanceDeliveryDateTimeFields extends StatelessWidget {
  const _MaintenanceDeliveryDateTimeFields({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final showSchedule = controller.showDeliverySchedule.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(10.r),
              child: InkWell(
                onTap: () => controller.toggleDeliverySchedule(!showSchedule),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.operationalCardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 19.sp,
                        color: showSchedule
                            ? AppColors.primaryColor
                            : AppColors.customGreyColor5,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'deliveryDate'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.operationalNavy,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: showSchedule,
                        activeThumbColor: AppColors.primaryColor,
                        activeTrackColor:
                            AppColors.primaryColor.withValues(alpha: 0.32),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: controller.toggleDeliverySchedule,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showSchedule) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(
                    child: _MaintenancePickerTile(
                      icon: Icons.calendar_today_outlined,
                      value: showData(controller.deliveryDate.value),
                      onTap: () => controller.pickDeliveryDate(context),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _MaintenancePickerTile(
                      icon: Icons.access_time_rounded,
                      value: _formatTime(controller.deliveryTime.value),
                      onTap: () => controller.pickDeliveryTime(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'morning'.tr : 'evening'.tr;
    return '${hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _MaintenancePickerTile extends StatelessWidget {
  const _MaintenancePickerTile({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.operationalCardBorder),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: AppColors.operationalPurple,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.operationalNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceMediaPicker extends StatelessWidget {
  const _MaintenanceMediaPicker({required this.controller});

  final MaintenanceController controller;

  Future<void> _capture() async {
    final result = await Get.to<WhatsAppCapture>(
      () => const WhatsAppCameraScreen(),
    );
    if (result == null) return;

    final file = File(result.path);
    if (!controller.selectedMedia.any((item) => item.path == file.path)) {
      controller.selectedMedia.add(file);
      controller.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.selectedMedia.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: _capture,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primaryColor,
                size: 28.sp,
              ),
              SizedBox(height: 6.h),
              Text(
                'uploadMedia'.tr,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 72.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.selectedMedia.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 6.w),
        itemBuilder: (_, index) {
          if (index == controller.selectedMedia.length) {
            return InkWell(
              borderRadius: BorderRadius.circular(6.r),
              onTap: _capture,
              child: Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.primaryColor,
                  size: 28.sp,
                ),
              ),
            );
          }

          final file = controller.selectedMedia[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: SizedBox(
                  width: 72.w,
                  height: 72.h,
                  child: ShowImageOrVideo(path: file.path),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: () {
                    controller.selectedMedia.removeAt(index);
                    controller.update();
                  },
                  child: Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
