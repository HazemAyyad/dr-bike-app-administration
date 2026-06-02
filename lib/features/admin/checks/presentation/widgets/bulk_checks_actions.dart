import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_button.dart';
import '../../../../../core/helpers/custom_chechbox.dart';
import '../../../../../core/helpers/custom_dropdown_field.dart';
import '../../../../../core/utils/app_colors.dart';
import '../controllers/checks_controller.dart';

class BulkChecksActionsDialog extends GetView<ChecksController> {
  const BulkChecksActionsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = controller.currentTab.value == 0
        ? controller.isInComing
            ? controller.incomingChecksDidNotActOnIt
            : controller.outgoingChecksDidNotActOnIt
        : controller.currentTab.value == 1
            ? controller.isInComing
                ? controller.incomingChecksActedOnIt
                : controller.outgoingChecksActedOnIt
            : controller.archive;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'bulkChecksActions'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${'selectedChecks'.tr}: ${controller.selectedBulkCheckIds.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 12.h),
            ...actions.map(
              (action) => ListTile(
                dense: true,
                title: Text(action.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.back();
                  _openAction(context, action);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAction(BuildContext context, String action) {
    if (action == 'endorseTheCheck') {
      Get.dialog(const BulkCashToPersonDialog());
      return;
    }
    if (action == 'cashTheCheck') {
      Get.dialog(const BulkCashToBoxDialog());
      return;
    }
    if (action == 'returnedCheck') {
      Get.dialog(
        BulkCheckConfirmDialog(
          actionTitle: 'returnedCheck',
          actionColor: Colors.orange,
          onConfirm: () => controller.bulkReturnCheck(isCancel: false),
        ),
      );
      return;
    }
    if (action == 'voidTheCheck') {
      Get.dialog(
        BulkCheckConfirmDialog(
          actionTitle: 'voidTheCheck',
          actionColor: Colors.red,
          onConfirm: () => controller.bulkReturnCheck(isCancel: true),
        ),
      );
      return;
    }
    if (action == 'deleteCheck') {
      Get.dialog(
        BulkCheckConfirmDialog(
          actionTitle: 'deleteCheck',
          actionColor: Colors.red,
          onConfirm: controller.bulkDeleteCheck,
        ),
      );
    }
  }
}

class BulkCheckConfirmDialog extends GetView<ChecksController> {
  const BulkCheckConfirmDialog({
    Key? key,
    required this.actionTitle,
    required this.onConfirm,
    this.actionColor,
  }) : super(key: key);

  final String actionTitle;
  final Future<void> Function() onConfirm;
  final Color? actionColor;

  @override
  Widget build(BuildContext context) {
    final checks = controller.selectedBulkChecks;
    final total = checks.fold<double>(
      0,
      (sum, check) => sum + (double.tryParse(check.total) ?? 0),
    );

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'confirmBulkAction'.tr,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 12.h),
            _summaryLine(context, 'bulkAction'.tr, actionTitle.tr),
            _summaryLine(
                context, 'selectedChecks'.tr, checks.length.toString()),
            _summaryLine(context, 'total'.tr, total.toStringAsFixed(2)),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    color: actionColor ?? AppColors.primaryColor,
                    isLoading: controller.isLoading,
                    text: 'yes',
                    onPressed: onConfirm,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    isSafeArea: false,
                    color: Colors.grey,
                    text: 'cancel',
                    onPressed: Get.back,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class BulkCashToPersonDialog extends GetView<ChecksController> {
  const BulkCashToPersonDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedValue = RxnString();
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: CustomCheckBox(
                      title: 'seller'.tr,
                      value: RxBool(!controller.selectedCustomersSellers.value),
                      onChanged: (_) {
                        selectedValue.value = null;
                        controller.selectedCustomersSellers.value = false;
                      },
                    ),
                  ),
                  Expanded(
                    child: CustomCheckBox(
                      title: 'customer'.tr,
                      value: controller.selectedCustomersSellers,
                      onChanged: (_) {
                        selectedValue.value = null;
                        controller.selectedCustomersSellers.value = true;
                      },
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => CustomDropdownFieldWithSearch(
                tital: 'beneficiary',
                hint: 'customerNameExample',
                items: controller.selectedCustomersSellers.value
                    ? controller.allCustomersList
                    : controller.allSellersList,
                onChanged: (value) {
                  if (value != null) selectedValue.value = value.id.toString();
                },
                itemAsString: (item) => item.name,
                compareFn: (a, b) => a.id == b.id,
                validator: (_) => null,
              ),
            ),
            SizedBox(height: 12.h),
            AppButton(
              isSafeArea: false,
              isLoading: controller.isLoading,
              text: 'continue',
              onPressed: () {
                if (selectedValue.value == null) return;
                Get.dialog(
                  BulkCheckConfirmDialog(
                    actionTitle: 'endorseTheCheck',
                    onConfirm: () => controller.bulkCashedToPersonOrCashed(
                      customerId: !controller.selectedCustomersSellers.value
                          ? selectedValue.value
                          : null,
                      sellerId: controller.selectedCustomersSellers.value
                          ? selectedValue.value
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BulkCashToBoxDialog extends GetView<ChecksController> {
  const BulkCashToBoxDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedValue = RxnString();
    final selectedChecks = controller.selectedBulkChecks;
    final currency =
        selectedChecks.isEmpty ? null : selectedChecks.first.currency;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomDropdownFieldWithSearch(
              tital: 'boxName',
              hint: 'boxNameExample',
              items: controller.shownBoxesList
                  .where((box) => currency == null || box.currency == currency)
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedValue.value = value.boxId.toString();
              },
              itemAsString: (item) =>
                  '${item.boxName} - (${item.totalBalance} ${item.currency})',
              compareFn: (a, b) => a.boxId == b.boxId,
              validator: (_) => null,
            ),
            SizedBox(height: 12.h),
            AppButton(
              isSafeArea: false,
              isLoading: controller.isLoading,
              text: 'continue',
              onPressed: () {
                if (selectedValue.value == null) return;
                Get.dialog(
                  BulkCheckConfirmDialog(
                    actionTitle: 'cashTheCheck',
                    onConfirm: () =>
                        controller.bulkChashToBox(boxId: selectedValue.value!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
