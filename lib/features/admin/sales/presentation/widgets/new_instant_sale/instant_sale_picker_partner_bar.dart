import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../../core/utils/app_colors.dart';
import '../../../../checks/data/models/check_model.dart';
import '../../controllers/sales_controller.dart';

/// App bar icon — opens partner selection sheet.
class InstantSalePickerPartnerIcon extends StatelessWidget {
  const InstantSalePickerPartnerIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();

    return Obx(() {
      final hasPartner = controller.hasPickerPartner;
      final isCustomer = controller.pickerPartnerIsCustomer.value;

      return IconButton(
        tooltip: 'instantSaleSelectPartner'.tr,
        onPressed: () => showInstantSalePickerPartnerSheet(context),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              hasPartner ? Icons.person : Icons.person_outline,
              color: AppColors.primaryColor,
              size: 26.sp,
            ),
            if (hasPartner)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? AppColors.primaryColor
                        : const Color(0xFFE65100),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

Future<void> showInstantSalePickerPartnerSheet(BuildContext context) async {
  final controller = Get.find<SalesController>();
  await controller.ensurePickerPartnersLoaded();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _PickerPartnerSheet(),
  );
}

class _PickerPartnerSheet extends StatelessWidget {
  const _PickerPartnerSheet();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Obx(() {
            final isCustomer = controller.pickerPartnerIsCustomer.value;
            final items = isCustomer
                ? controller.pickerCustomersList
                : controller.pickerSellersList;
            final selected = controller.pickerSelectedPartner.value;
            final hasPartner = controller.hasPickerPartner;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'instantSaleSelectPartner'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'instantSalePickerPartnerHint'.tr,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _PartnerChip(
                        label: 'customer'.tr,
                        selected: isCustomer,
                        onTap: () =>
                            controller.setPickerPartnerTab(isCustomer: true),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _PartnerChip(
                        label: 'seller'.tr,
                        selected: !isCustomer,
                        onTap: () =>
                            controller.setPickerPartnerTab(isCustomer: false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                CustomDropdownFieldWithSearch(
                  tital: isCustomer ? 'customer'.tr : 'seller'.tr,
                  hint: isCustomer
                      ? 'customerNameExample'.tr
                      : 'sellerName1'.tr,
                  isRequired: false,
                  items: items,
                  value: selected,
                  onChanged: (value) => controller.onPickerPartnerSelected(
                    value is SellerModel ? value : null,
                  ),
                  validator: (_) => null,
                  itemAsString: (item) => item.name,
                  compareFn: (a, b) => a.id == b.id,
                ),
                if (selected != null) ...[
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      selected.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 14.h),
                Row(
                  children: [
                    if (hasPartner)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await controller.clearPickerPartner();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text('clear'.tr),
                        ),
                      ),
                    if (hasPartner) SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('confirm'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryColor.withValues(alpha: 0.12)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primaryColor : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
