import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_colors.dart';
import '../../../../widgets/unified_partner_selector.dart';
import '../../../../checks/data/models/check_model.dart';
import '../../controllers/sales_controller.dart';

class InstantSalePickerPartnerIcon extends StatelessWidget {
  const InstantSalePickerPartnerIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    return Obx(() {
      final hasPartner = controller.hasPickerPartner;
      return IconButton(
        tooltip: 'اختيار الزبون أو المورد',
        onPressed: () => showInstantSalePickerPartnerSheet(context),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              hasPartner ? Icons.person_pin_circle : Icons.person_add_alt_1,
              color: AppColors.primaryColor,
              size: 26.sp,
            ),
            if (hasPartner)
              Positioned(
                left: -2,
                top: -2,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: controller.pickerPartnerIsCustomer.value
                        ? Colors.green
                        : const Color(0xFFE65100),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
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
    builder: (_) => const _PickerPartnerSheet(),
  );
}

class _PickerPartnerSheet extends StatelessWidget {
  const _PickerPartnerSheet();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: SingleChildScrollView(
            child: Obx(() => UnifiedPartnerSelector<SellerModel>(
                  customers: controller.pickerCustomersList,
                  sellers: controller.pickerSellersList,
                  selected: controller.pickerSelectedPartner.value,
                  selectedIsSeller: !controller.pickerPartnerIsCustomer.value,
                  idOf: (item) => item.id,
                  nameOf: (item) => item.name,
                  phoneOf: (item) => item.phone,
                  onSelected: (item, isSeller) async {
                    controller.pickerPartnerIsCustomer.value = !isSeller;
                    await controller.onPickerPartnerSelected(item);
                  },
                  onCleared: controller.clearPickerPartner,
                  onAddRequested: controller.openAddPickerPartner,
                )),
          ),
        ),
      ),
    );
  }
}
