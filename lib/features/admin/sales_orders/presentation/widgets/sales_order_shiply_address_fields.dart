import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';

import 'sales_order_shiply_sandbox_badge.dart';

/// Searchable Shiply city / village / street fields (gray UI, no purple).
class SalesOrderShiplyAddressFields extends StatelessWidget {
  const SalesOrderShiplyAddressFields({
    Key? key,
    required this.controller,
    this.showDeliveryFee = true,
    this.parcelPriceForFee = 0,
  }) : super(key: key);

  final SalesOrdersController controller;
  final bool showDeliveryFee;
  final double parcelPriceForFee;

  static PopupProps<ShiplyCityModel> _cityPopupProps() {
    return PopupProps.menu(
      showSearchBox: true,
      constraints: const BoxConstraints(maxHeight: 320),
      searchDelay: Duration.zero,
      menuProps: MenuProps(
        backgroundColor: SalesOrdersController.cardGray,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      searchFieldProps: TextFieldProps(
        style: const TextStyle(color: SalesOrdersController.textPrimary),
        decoration: InputDecoration(
          hintText: 'search'.tr,
          hintStyle: const TextStyle(color: SalesOrdersController.textSecondary),
          filled: true,
          fillColor: SalesOrdersController.surfaceGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: SalesOrdersController.borderGray),
          ),
        ),
      ),
    );
  }

  ShiplyCityModel? _selectedCity() {
    final id = controller.selectedShiplyCityId.value;
    if (id == null) return null;
    for (final city in controller.shiplyCities) {
      if (city.id == id) return city;
    }
    return null;
  }

  ShiplyVillageModel? _selectedVillage() {
    final id = controller.selectedShiplyVillageId.value;
    if (id == null) return null;
    for (final village in controller.selectedShiplyVillages) {
      if (village.id == id) return village;
    }
    return null;
  }

  List<ShiplyCityModel> _filterCities(String filter) {
    if (filter.trim().isEmpty) return controller.shiplyCities;
    final q = filter.trim().toLowerCase();
    return controller.shiplyCities
        .where((c) => c.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<ShiplyVillageModel> _filterVillages(String filter) {
    final villages = controller.selectedShiplyVillages;
    if (filter.trim().isEmpty) return villages;
    final q = filter.trim().toLowerCase();
    final closedLabel = 'shiplyVillageClosed'.tr.toLowerCase();
    return villages
        .where((v) => v.displayLabel(closedLabel).toLowerCase().contains(q))
        .toList(growable: false);
  }

  InputDecoration _fieldDecoration(String hint, {bool floatingLabel = false}) {
    return InputDecoration(
      hintText: floatingLabel ? null : hint,
      labelText: floatingLabel ? hint : null,
      hintStyle: const TextStyle(color: SalesOrdersController.textSecondary),
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cities = controller.shiplyCities;
      if (cities.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            'shiplyAddressesEmpty'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: SalesOrdersController.textSecondary,
            ),
          ),
        );
      }

      final closedLabel = 'shiplyVillageClosed'.tr;
      final villages = controller.selectedShiplyVillages;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SalesOrderShiplySandboxBadge(controller: controller),
          DropdownSearch<ShiplyCityModel>(
            selectedItem: _selectedCity(),
            items: (filter, _) async => _filterCities(filter),
            itemAsString: (c) => c.name,
            compareFn: (a, b) => a.id == b.id,
            popupProps: _cityPopupProps(),
            decoratorProps: DropDownDecoratorProps(
              decoration: _fieldDecoration('salesOrderShiplyCity'.tr),
            ),
            onChanged: (city) => controller.onShiplyCityChanged(city?.id),
          ),
          SizedBox(height: 12.h),
          DropdownSearch<ShiplyVillageModel>(
            selectedItem: _selectedVillage(),
            items: (filter, _) async => _filterVillages(filter),
            itemAsString: (v) => v.displayLabel(closedLabel),
            compareFn: (a, b) => a.id == b.id,
            enabled: villages.isNotEmpty,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              constraints: const BoxConstraints(maxHeight: 320),
              searchDelay: Duration.zero,
              menuProps: MenuProps(
                backgroundColor: SalesOrdersController.cardGray,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              searchFieldProps: TextFieldProps(
                style: const TextStyle(color: SalesOrdersController.textPrimary),
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  hintStyle:
                      const TextStyle(color: SalesOrdersController.textSecondary),
                  filled: true,
                  fillColor: SalesOrdersController.surfaceGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: SalesOrdersController.borderGray),
                  ),
                ),
              ),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: _fieldDecoration('salesOrderShiplyVillage'.tr),
            ),
            onChanged: villages.isEmpty
                ? null
                : (village) {
                    if (village != null && village.isClosed) return;
                    controller.onShiplyVillageChanged(
                      village?.id,
                      parcelPrice: parcelPriceForFee,
                    );
                  },
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: controller.customerAddressController,
            style: TextStyle(
              color: SalesOrdersController.textPrimary,
              fontSize: 14.sp,
            ),
            decoration: _fieldDecoration('salesOrderStreetAddress'.tr, floatingLabel: true),
          ),
          if (showDeliveryFee) ...[
            SizedBox(height: 12.h),
            TextField(
              controller: controller.deliveryFeeController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: SalesOrdersController.textPrimary,
                fontSize: 14.sp,
              ),
              decoration: _fieldDecoration('salesOrderDeliveryFeeInput'.tr, floatingLabel: true),
              onChanged: (_) => controller.onDeliveryFeeChanged(),
            ),
            SizedBox(height: 4.h),
            Text(
              'shiplyDeliveryFeeHint'.tr,
              style: TextStyle(
                fontSize: 11.sp,
                color: SalesOrdersController.textSecondary,
              ),
            ),
          ],
        ],
      );
    });
  }
}
