import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/app_failure_notice.dart';
import '../../../../../core/services/initial_bindings.dart';
import '../../../../../routes/app_routes.dart';
import '../../../buying/presentation/binding/buying_binding.dart';
import '../../../buying/presentation/controllers/bills_controller.dart';

bool get canPurchaseProductFromStock =>
    userType == 'admin' ||
    employeePermissionNames.contains('Purchasing Section');

Future<void> openProductPurchase({
  required BuildContext context,
  required String productId,
  String? sizeColorId,
}) async {
  if (!canPurchaseProductFromStock) {
    AppFailureNotice.show(
      context: context,
      title: 'error'.tr,
      message: 'permissionDenied'.tr,
    );
    return;
  }
  if (!Get.isRegistered<BillsController>()) {
    BuyingBinding().dependencies();
  }
  final controller = Get.find<BillsController>();
  final prepared = await controller.prepareNewPurchaseForProduct(
    productId,
    sizeColorId: sizeColorId,
  );
  if (!prepared) {
    if (!context.mounted) return;
    AppFailureNotice.show(
      context: context,
      title: 'error'.tr,
      message: 'productDetailsLoadFailed'.tr,
    );
    return;
  }
  await Get.toNamed(AppRoutes.ADDNEWBILLSCREEN);
}
