import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../widgets/unified_partner_selector.dart';
import '../../../checks/data/models/check_model.dart';
import '../../../general_data_list/presentation/views/partner_addresses_sheet.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../controllers/sales_orders_controller.dart';
import '../../data/models/sales_order_model.dart';

class SalesOrderPartnerSelectorIcon extends StatelessWidget {
  const SalesOrderPartnerSelectorIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sales = Get.find<SalesController>();
    return Obx(() {
      final selected = sales.pickerSelectedPartner.value != null;
      return IconButton(
        tooltip:
            selected ? 'تغيير الزبون أو المورد' : 'اختيار الزبون أو المورد',
        onPressed: () async {
          await sales.ensurePickerPartnersLoaded();
          if (!context.mounted) return;
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Container(
                  margin: EdgeInsets.all(12.r),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: SalesOrdersController.surfaceGray,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: const SingleChildScrollView(
                    child: SalesOrderPartnerSelector(compact: true),
                  ),
                ),
              ),
            ),
          );
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              selected ? Icons.person_pin_circle : Icons.person_add_alt_1,
              color: AppColors.primaryColor,
              size: 26.sp,
            ),
            if (selected)
              Positioned(
                left: -2,
                top: -2,
                child: Container(
                  width: 9.w,
                  height: 9.w,
                  decoration: BoxDecoration(
                    color: Colors.green,
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

class SalesOrderPartnerSelector extends StatefulWidget {
  const SalesOrderPartnerSelector({this.compact = false, Key? key})
      : super(key: key);

  final bool compact;

  @override
  State<SalesOrderPartnerSelector> createState() =>
      _SalesOrderPartnerSelectorState();
}

class _SalesOrderPartnerSelectorState extends State<SalesOrderPartnerSelector> {
  SalesController get sales => Get.find<SalesController>();
  SalesOrdersController get orders => Get.find<SalesOrdersController>();

  Future<void> _select(_PartnerEntry entry) async {
    sales.pickerPartnerIsCustomer.value = entry.isCustomer;
    // Refresh product prices in the background so address selection opens
    // immediately instead of waiting for the products request.
    sales.onPickerPartnerSelected(entry.partner).catchError((_) {});
    orders.clearPartnerAddress();
    orders.partnerAddresses.clear();
    orders.customerNameController.text = entry.partner.name;
    orders.customerPhoneController.text = entry.partner.phone;
    if (!mounted) return;
    await _chooseAddress(entry);
  }

  Future<void> _chooseAddress(_PartnerEntry entry) async {
    final raw = await showPartnerAddressesSheet(
      context: context,
      partnerType: entry.isCustomer ? 'customer' : 'seller',
      partnerId: entry.partner.id,
      selectionMode: true,
    );
    if (raw == null) return;
    final address = PartnerAddressModel.fromJson(raw);
    if (address.id > 0) {
      final index = orders.partnerAddresses
          .indexWhere((existing) => existing.id == address.id);
      if (index >= 0) {
        orders.partnerAddresses[index] = address;
      } else {
        orders.partnerAddresses.add(address);
      }
      orders.selectPartnerAddress(
        address,
        parcelPrice: sales.totalCost.value,
      );
    }
  }

  Future<void> _openAddresses() async {
    final partner = sales.pickerSelectedPartner.value;
    if (partner == null || partner.id <= 0) return;
    await _chooseAddress(
      _PartnerEntry(partner, sales.pickerPartnerIsCustomer.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final partner = sales.pickerSelectedPartner.value;
      final addressId = orders.selectedPartnerAddressId.value;
      final selectedAddress = orders.partnerAddresses
          .firstWhereOrNull((address) => address.id == addressId);
      return Container(
        padding: EdgeInsets.all(widget.compact ? 10.r : 12.r),
        decoration: BoxDecoration(
          color: SalesOrdersController.cardGray,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: SalesOrdersController.borderGray),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UnifiedPartnerSelector<SellerModel>(
            customers: sales.pickerCustomersList,
            sellers: sales.pickerSellersList,
            selected: partner,
            selectedIsSeller: !sales.pickerPartnerIsCustomer.value,
            idOf: (item) => item.id,
            nameOf: (item) => item.name,
            phoneOf: (item) => item.phone,
            onSelected: (item, isSeller) =>
                _select(_PartnerEntry(item, !isSeller)),
            onCleared: () async {
              orders.clearPartnerAddress();
              orders.partnerAddresses.clear();
              orders.customerNameController.clear();
              orders.customerPhoneController.clear();
              await sales.clearPickerPartner();
            },
            onAddRequested: sales.openAddPickerPartner,
          ),
          if (partner != null) ...[
            SizedBox(height: 6.h),
            InkWell(
              onTap: _openAddresses,
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 5.h),
                child: Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 19.sp, color: AppColors.primaryColor),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      selectedAddress == null
                          ? 'العنوان اختياري — اضغط للاختيار'
                          : _addressText(selectedAddress),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: selectedAddress == null
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: selectedAddress == null
                            ? Colors.grey.shade600
                            : SalesOrdersController.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedAddress != null)
                    InkWell(
                      onTap: orders.clearPartnerAddress,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(Icons.close_rounded,
                            size: 17.sp, color: Colors.grey.shade600),
                      ),
                    )
                  else
                    Icon(Icons.chevron_left_rounded,
                        size: 20.sp, color: Colors.grey.shade600),
                ]),
              ),
            ),
          ],
        ]),
      );
    });
  }

  String _addressText(PartnerAddressModel address) {
    final parts = <String>[
      if ((address.shiplyVillageName ?? '').trim().isNotEmpty)
        address.shiplyVillageName!.trim(),
      if ((address.shiplyCityName ?? '').trim().isNotEmpty)
        address.shiplyCityName!.trim(),
      if (address.streetAddress.trim().isNotEmpty &&
          address.streetAddress.trim() != '----')
        address.streetAddress.trim(),
    ];
    return parts.isEmpty ? address.label : parts.join('، ');
  }
}

class _PartnerEntry {
  const _PartnerEntry(this.partner, this.isCustomer);
  final dynamic partner;
  final bool isCustomer;
}
