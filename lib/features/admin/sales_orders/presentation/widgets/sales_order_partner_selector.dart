import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../general_data_list/presentation/views/partner_addresses_sheet.dart';
import '../../../sales/presentation/controllers/sales_controller.dart';
import '../controllers/sales_orders_controller.dart';
import '../../data/models/sales_order_model.dart';

class SalesOrderPartnerSelector extends StatefulWidget {
  const SalesOrderPartnerSelector({this.compact = false, Key? key})
      : super(key: key);

  final bool compact;

  @override
  State<SalesOrderPartnerSelector> createState() =>
      _SalesOrderPartnerSelectorState();
}

class _SalesOrderPartnerSelectorState extends State<SalesOrderPartnerSelector> {
  final search = TextEditingController();
  final focus = FocusNode();
  bool showResults = false;

  SalesController get sales => Get.find<SalesController>();
  SalesOrdersController get orders => Get.find<SalesOrdersController>();

  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (focus.hasFocus && mounted) setState(() => showResults = true);
    });
  }

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    super.dispose();
  }

  List<_PartnerEntry> _results() {
    final all = <_PartnerEntry>[
      ...sales.pickerCustomersList
          .map((partner) => _PartnerEntry(partner, true)),
      ...sales.pickerSellersList
          .map((partner) => _PartnerEntry(partner, false)),
    ];
    final query = search.text.trim().toLowerCase();
    if (query.isEmpty) return all.take(10).toList();
    return all
        .where((entry) => '${entry.partner.name} ${entry.partner.phone}'
            .toLowerCase()
            .contains(query))
        .take(15)
        .toList();
  }

  Future<void> _select(_PartnerEntry entry) async {
    sales.pickerPartnerIsCustomer.value = entry.isCustomer;
    await sales.onPickerPartnerSelected(entry.partner);
    orders.customerNameController.text = entry.partner.name;
    orders.customerPhoneController.text = entry.partner.phone;
    search.text = entry.partner.name;
    focus.unfocus();
    if (mounted) setState(() => showResults = false);
    await orders.loadPartnerAddresses(
      partnerId: entry.partner.id,
      isCustomer: entry.isCustomer,
    );
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
      orders.selectPartnerAddress(address);
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
      final results = _results();
      if (partner != null && !focus.hasFocus && search.text != partner.name) {
        search.text = partner.name;
      }
      return Container(
        padding: EdgeInsets.all(widget.compact ? 10.r : 12.r),
        decoration: BoxDecoration(
          color: SalesOrdersController.cardGray,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: SalesOrdersController.borderGray),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.people_alt_outlined,
                size: 19.sp, color: AppColors.primaryColor),
            SizedBox(width: 6.w),
            Text('الزبون أو المورد',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (partner != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  sales.pickerPartnerIsCustomer.value ? 'زبون' : 'مورد',
                  style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor),
                ),
              ),
          ]),
          SizedBox(height: 8.h),
          TextField(
            controller: search,
            focusNode: focus,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم الهاتف',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: partner == null
                  ? null
                  : IconButton(
                      tooltip: 'إلغاء الاختيار',
                      onPressed: () async {
                        await sales.clearPickerPartner();
                        orders.partnerAddresses.clear();
                        orders.selectedPartnerAddressId.value = null;
                        search.clear();
                        if (mounted) setState(() => showResults = true);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11.r),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() => showResults = true),
          ),
          if (showResults && focus.hasFocus)
            Container(
              constraints: BoxConstraints(maxHeight: 220.h),
              margin: EdgeInsets.only(top: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.operationalCardBorder),
              ),
              child: results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(14), child: Text('لا توجد نتائج'))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final entry = results[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            entry.isCustomer
                                ? Icons.person_outline
                                : Icons.storefront_outlined,
                            color: AppColors.primaryColor,
                          ),
                          title: Text(entry.partner.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text([
                            entry.isCustomer ? 'زبون' : 'مورد',
                            if (entry.partner.phone.trim().isNotEmpty)
                              entry.partner.phone,
                          ].join(' • ')),
                          onTap: () => _select(entry),
                        );
                      },
                    ),
            ),
          if (partner != null) ...[
            SizedBox(height: 8.h),
            InkWell(
              onTap: _openAddresses,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: SalesOrdersController.borderGray),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.primaryColor),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedAddress == null
                              ? 'اختر عنواناً أو أضف عنواناً جديداً'
                              : selectedAddress.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (selectedAddress != null)
                          Text(selectedAddress.streetAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                ]),
              ),
            ),
          ],
        ]),
      );
    });
  }
}

class _PartnerEntry {
  const _PartnerEntry(this.partner, this.isCustomer);
  final dynamic partner;
  final bool isCustomer;
}
