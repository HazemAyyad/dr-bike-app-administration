import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../data/models/sales_order_model.dart';
import '../controllers/sales_orders_controller.dart';

import 'sales_order_shiply_sandbox_badge.dart';

/// عنصر بحث موحّد يجمع المدن والقرى في قائمة واحدة.
class _ShiplyAddressSearchEntry {
  const _ShiplyAddressSearchEntry({
    required this.cityId,
    required this.cityName,
    this.villageId,
    this.villageName = '',
    this.isClosed = false,
  });

  final int cityId;
  final String cityName;
  final int? villageId;
  final String villageName;
  final bool isClosed;

  bool get isVillage => villageId != null;

  String get key => isVillage ? 'v_$villageId' : 'c_$cityId';

  String label(String closedSuffix) {
    if (!isVillage) return cityName;
    final base = '$cityName ‹ $villageName';
    return isClosed ? '$base ($closedSuffix)' : base;
  }
}

/// Searchable city / village / street fields for delivery handover.
class SalesOrderShiplyAddressFields extends StatelessWidget {
  const SalesOrderShiplyAddressFields({
    Key? key,
    required this.controller,
    this.showDeliveryFee = true,
    this.parcelPriceForFee = 0,
    this.showShiplyBranding = true,
  }) : super(key: key);

  final SalesOrdersController controller;
  final bool showDeliveryFee;
  final double parcelPriceForFee;
  final bool showShiplyBranding;

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

  /// قائمة موحّدة بكل المدن والقرى للبحث السريع.
  List<_ShiplyAddressSearchEntry> _allAddressEntries() {
    final entries = <_ShiplyAddressSearchEntry>[];
    for (final city in controller.shiplyCities) {
      entries.add(
        _ShiplyAddressSearchEntry(cityId: city.id, cityName: city.name),
      );
      for (final village in city.villages) {
        entries.add(
          _ShiplyAddressSearchEntry(
            cityId: city.id,
            cityName: city.name,
            villageId: village.id,
            villageName: village.name,
            isClosed: village.isClosed,
          ),
        );
      }
    }
    return entries;
  }

  List<_ShiplyAddressSearchEntry> _filterAddressEntries(String filter) {
    final all = _allAddressEntries();
    final q = filter.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((e) =>
            e.cityName.toLowerCase().contains(q) ||
            e.villageName.toLowerCase().contains(q))
        .toList(growable: false);
  }

  _ShiplyAddressSearchEntry? _selectedAddressEntry() {
    final villageId = controller.selectedShiplyVillageId.value;
    final cityId = controller.selectedShiplyCityId.value;
    if (villageId == null && cityId == null) return null;
    for (final entry in _allAddressEntries()) {
      if (villageId != null) {
        if (entry.villageId == villageId) return entry;
      } else if (!entry.isVillage && entry.cityId == cityId) {
        return entry;
      }
    }
    return null;
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
            showShiplyBranding
                ? 'shiplyAddressesEmpty'.tr
                : 'salesOrderDeliveryAddressesEmpty'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: SalesOrdersController.textSecondary,
            ),
          ),
        );
      }

      final closedLabel = showShiplyBranding
          ? 'shiplyVillageClosed'.tr
          : 'salesOrderDeliveryVillageClosed'.tr;
      final villages = controller.selectedShiplyVillages;
      final cityLabel = showShiplyBranding
          ? 'salesOrderShiplyCity'.tr
          : 'salesOrderDeliveryCity'.tr;
      final villageLabel = showShiplyBranding
          ? 'salesOrderShiplyVillage'.tr
          : 'salesOrderDeliveryVillage'.tr;
      final feeHint = showShiplyBranding
          ? 'shiplyDeliveryFeeHint'.tr
          : 'salesOrderDeliveryFeeHint'.tr;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showShiplyBranding)
            SalesOrderShiplySandboxBadge(controller: controller),
          DropdownSearch<_ShiplyAddressSearchEntry>(
            selectedItem: _selectedAddressEntry(),
            items: (filter, _) async => _filterAddressEntries(filter),
            itemAsString: (e) => e.label(closedLabel),
            compareFn: (a, b) => a.key == b.key,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              constraints: const BoxConstraints(maxHeight: 360),
              searchDelay: Duration.zero,
              menuProps: MenuProps(
                backgroundColor: SalesOrdersController.cardGray,
                elevation: 2,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              searchFieldProps: TextFieldProps(
                style: const TextStyle(color: SalesOrdersController.textPrimary),
                decoration: InputDecoration(
                  hintText: 'salesOrderShiplyAddressSearchHint'.tr,
                  hintStyle: const TextStyle(
                      color: SalesOrdersController.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: SalesOrdersController.textSecondary,
                  ),
                  filled: true,
                  fillColor: SalesOrdersController.surfaceGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: SalesOrdersController.borderGray),
                  ),
                ),
              ),
              itemBuilder: (context, entry, _, __) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    entry.isVillage ? Icons.home_work_outlined : Icons.location_city,
                    size: 18,
                    color: SalesOrdersController.textSecondary,
                  ),
                  title: Text(
                    entry.label(closedLabel),
                    style: const TextStyle(
                        color: SalesOrdersController.textPrimary),
                  ),
                );
              },
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: _fieldDecoration('salesOrderShiplyAddressSearch'.tr)
                  .copyWith(
                prefixIcon: const Icon(
                  Icons.search,
                  color: SalesOrdersController.textSecondary,
                ),
              ),
            ),
            onChanged: (entry) {
              if (entry == null) return;
              if (entry.isVillage) {
                if (entry.isClosed) return;
                controller.selectShiplyCityAndVillage(
                  cityId: entry.cityId,
                  villageId: entry.villageId,
                  parcelPrice: parcelPriceForFee,
                );
              } else {
                controller.onShiplyCityChanged(entry.cityId);
              }
            },
          ),
          SizedBox(height: 12.h),
          DropdownSearch<ShiplyCityModel>(
            selectedItem: _selectedCity(),
            items: (filter, _) async => _filterCities(filter),
            itemAsString: (c) => c.name,
            compareFn: (a, b) => a.id == b.id,
            popupProps: _cityPopupProps(),
            decoratorProps: DropDownDecoratorProps(
              decoration: _fieldDecoration(cityLabel),
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
              decoration: _fieldDecoration(villageLabel),
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
              feeHint,
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
