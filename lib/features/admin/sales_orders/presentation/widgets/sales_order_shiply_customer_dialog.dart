import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../checks/data/models/check_model.dart';
import '../../../../../core/helpers/phone_format_helper.dart';
import '../controllers/sales_orders_controller.dart';

/// Select customer / seller (or add new) before Shiply handover.
class SalesOrderShiplyCustomerDialog extends StatefulWidget {
  const SalesOrderShiplyCustomerDialog({
    Key? key,
    required this.orderId,
    required this.controller,
    this.initialName,
  }) : super(key: key);

  final int orderId;
  final SalesOrdersController controller;
  final String? initialName;

  @override
  State<SalesOrderShiplyCustomerDialog> createState() =>
      _SalesOrderShiplyCustomerDialogState();
}

class _SalesOrderShiplyCustomerDialogState
    extends State<SalesOrderShiplyCustomerDialog> {
  SellerModel? _selected;

  List<SellerModel> _items(bool isCustomer) {
    return isCustomer
        ? widget.controller.shiplyCustomers
        : widget.controller.shiplySellers;
  }

  List<SellerModel> _filter(String filter, bool isCustomer) {
    final items = _items(isCustomer);
    if (filter.trim().isEmpty) return items;
    final q = filter.trim().toLowerCase();
    return items
        .where((p) => p.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: SalesOrdersController.textSecondary),
      filled: true,
      fillColor: SalesOrdersController.cardGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: SalesOrdersController.borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: SalesOrdersController.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: SalesOrdersController.textPrimary),
      ),
    );
  }

  Future<void> _openAddPersonDialog() async {
    final isCustomer = widget.controller.shiplyPartnerIsCustomer.value;
    final nameController = TextEditingController(
      text: widget.initialName?.trim() ?? '',
    );
    final phoneController = TextEditingController();

    final created = await Get.dialog<SellerModel>(
      Dialog(
        backgroundColor: SalesOrdersController.surfaceGray,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isCustomer
                      ? 'salesOrderShiplyAddCustomer'.tr
                      : 'salesOrderShiplyAddSeller'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  decoration: _fieldDecoration('name'.tr),
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: _fieldDecoration('phoneNumber'.tr),
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SalesOrdersController.textPrimary,
                          side: const BorderSide(
                            color: SalesOrdersController.borderGray,
                          ),
                          backgroundColor: SalesOrdersController.cardGray,
                        ),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            Get.snackbar('error'.tr, 'salesOrderShiplyNameRequired'.tr);
                            return;
                          }
                          final phone =
                              PhoneFormatHelper.forApi(phoneController.text);
                          if (phone.isNotEmpty &&
                              !PhoneFormatHelper.isValidApiPhone(phone)) {
                            Get.snackbar(
                              'error'.tr,
                              'salesOrderShiplyPhoneInvalid'.tr,
                            );
                            return;
                          }
                          final partner =
                              await widget.controller.createShiplyPartner(
                            isCustomer: isCustomer,
                            name: name,
                            phone: phone,
                          );
                          if (partner != null) Get.back(result: partner);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SalesOrdersController.textPrimary,
                          foregroundColor: SalesOrdersController.cardGray,
                        ),
                        child: Text('add'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    nameController.dispose();
    phoneController.dispose();

    if (created != null) {
      setState(() => _selected = created);
    }
  }

  Future<void> _onSave() async {
    final partner = _selected;
    if (partner == null) {
      Get.snackbar('error'.tr, 'salesOrderShiplyPartnerRequired'.tr);
      return;
    }

    final isCustomer = widget.controller.shiplyPartnerIsCustomer.value;
    final selection = ShiplyPartnerSelection(
      partner: partner,
      isCustomer: isCustomer,
    );
    widget.controller.pendingShiplyPartner = selection;

    if (partner.phone.trim().isEmpty) {
      Get.back(result: 'needs_phone');
      return;
    }

    final ok = await widget.controller.applyShiplyPartnerToOrder(
      orderId: widget.orderId,
      selection: selection,
    );
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SalesOrdersController.surfaceGray,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: SingleChildScrollView(
          child: Obx(() {
            final isCustomer = widget.controller.shiplyPartnerIsCustomer.value;
            final items = _items(isCustomer);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'salesOrderShiplyCustomerTitle'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'salesOrderShiplyCustomerSubtitle'.tr,
                  style: TextStyle(
                    color: SalesOrdersController.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _PartnerChip(
                        label: 'customer'.tr,
                        selected: isCustomer,
                        onTap: () {
                          widget.controller.shiplyPartnerIsCustomer.value =
                              true;
                          setState(() => _selected = null);
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _PartnerChip(
                        label: 'seller'.tr,
                        selected: !isCustomer,
                        onTap: () {
                          widget.controller.shiplyPartnerIsCustomer.value =
                              false;
                          setState(() => _selected = null);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                DropdownSearch<SellerModel>(
                  selectedItem: _selected,
                  items: (filter, _) async => _filter(filter, isCustomer),
                  itemAsString: (p) {
                    final phone = p.phone.trim();
                    return phone.isEmpty ? p.name : '${p.name} — $phone';
                  },
                  compareFn: (a, b) => a.id == b.id,
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    constraints: const BoxConstraints(maxHeight: 320),
                    searchDelay: Duration.zero,
                    menuProps: MenuProps(
                      backgroundColor: SalesOrdersController.cardGray,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'search'.tr,
                        filled: true,
                        fillColor: SalesOrdersController.surfaceGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: SalesOrdersController.borderGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                  decoratorProps: DropDownDecoratorProps(
                    decoration: _fieldDecoration(
                      isCustomer ? 'customer'.tr : 'seller'.tr,
                    ),
                  ),
                  onChanged: (value) => setState(() => _selected = value),
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openAddPersonDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      isCustomer
                          ? 'salesOrderShiplyAddCustomer'.tr
                          : 'salesOrderShiplyAddSeller'.tr,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: SalesOrdersController.textPrimary,
                    ),
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      'salesOrderShiplyPartnersEmpty'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: SalesOrdersController.textSecondary,
                      ),
                    ),
                  ),
                SizedBox(height: 12.h),
                Obx(() {
                  final busy = widget.controller.isSubmitting.value;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : () => Get.back(result: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SalesOrdersController.textPrimary,
                            side: const BorderSide(
                              color: SalesOrdersController.borderGray,
                            ),
                            backgroundColor: SalesOrdersController.cardGray,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: Text('cancel'.tr),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: busy ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SalesOrdersController.textPrimary,
                            foregroundColor: SalesOrdersController.cardGray,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: busy
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: SalesOrdersController.cardGray,
                                  ),
                                )
                              : Text('saveAndContinue'.tr),
                        ),
                      ),
                    ],
                  );
                }),
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
          ? SalesOrdersController.borderGray
          : SalesOrdersController.cardGray,
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
              color: selected
                  ? SalesOrdersController.textPrimary
                  : SalesOrdersController.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
