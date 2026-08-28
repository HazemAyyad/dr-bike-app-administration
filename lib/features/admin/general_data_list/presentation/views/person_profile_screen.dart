import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/debts/presentation/binding/debts_binding.dart';
import 'package:doctorbike/features/admin/debts/presentation/controllers/debt_ledger_controller.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/person_profile_model.dart';
import 'package:doctorbike/features/admin/general_data_list/presentation/controllers/general_data_list_controller.dart';
import 'package:doctorbike/features/admin/sales/presentation/utils/product_image_viewer.dart';
import 'package:doctorbike/features/admin/stock/presentation/utils/open_instant_sale_invoice.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'person_product_settings_screen.dart';
import 'partner_addresses_sheet.dart';

class PersonProfileScreen extends StatefulWidget {
  const PersonProfileScreen({
    Key? key,
    required this.person,
    required this.isCustomer,
  }) : super(key: key);

  final GeneralDataModel person;
  final bool isCustomer;

  @override
  State<PersonProfileScreen> createState() => _PersonProfileScreenState();
}

class _PersonProfileScreenState extends State<PersonProfileScreen> {
  final _api = Get.find<DioConsumer>();
  PersonProfileModel? _profile;
  bool _loading = true;

  String get _personType => widget.isCustomer ? 'customer' : 'seller';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get(
        EndPoints.personProfile,
        queryParameters: {
          'person_type': _personType,
          'person_id': widget.person.id,
        },
      );
      final body = asMap(response.data);
      _profile = PersonProfileModel.fromJson(asMap(body['profile']));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<PersonProductHistoryEntry>> _loadProductHistory(
      int productId) async {
    final response = await _api.get(
      EndPoints.personProfileProductHistory,
      queryParameters: {
        'person_type': _personType,
        'person_id': widget.person.id,
        'product_id': productId,
      },
    );
    return mapList(
      asMap(response.data)['entries'],
      (m) => PersonProductHistoryEntry.fromJson(m),
    );
  }

  void _openEditData() {
    final controller = Get.find<GeneralDataListController>();
    controller.clearForm();
    controller.isEdit.value = true;
    controller.getPersonData(
      customerId: widget.isCustomer ? widget.person.id.toString() : '',
      sellerId: widget.isCustomer ? '' : widget.person.id.toString(),
    );
    Get.toNamed(
      AppRoutes.ADDNEWCUSTOMERSCREEN,
      arguments: {
        'employeeType': _personType,
        'employeeId': widget.person.id.toString(),
        'sellerId': widget.person.id.toString(),
      },
    )?.then((_) => _load());
  }

  void _openProductSettings() {
    Get.to(
      () => PersonProductSettingsScreen(
        personName: widget.person.name,
        customerId: widget.isCustomer ? widget.person.id.toString() : null,
        sellerId: widget.isCustomer ? null : widget.person.id.toString(),
      ),
    )?.then((_) => _load());
  }

  Future<void> _openDebtLedger() async {
    DebtsBinding().dependencies();
    await Get.find<DebtLedgerController>().openPersonAccount(
      id: widget.person.id,
      name: widget.person.name,
      phone: widget.person.phone,
      personType: _personType,
    );
    _load();
  }

  void _openInvoice(
    BuildContext context, {
    required String type,
    required int id,
    String? invoiceNumber,
  }) {
    if (type == 'sales_order') {
      AppDependencyRegistry.ensureSalesOrders();
      Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: id);
      return;
    }
    openInstantSaleInvoiceFromStock(
      context: context,
      saleId: id.toString(),
      invoiceNumber: invoiceNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.person.name),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'نظرة عامة'),
                Tab(text: 'الفواتير'),
                Tab(text: 'المشتريات'),
              ],
            ),
          ),
          body: _loading
              ? const _PersonProfileSkeleton()
              : profile == null
                  ? const Center(child: Text('تعذر تحميل البروفايل'))
                  : TabBarView(
                      children: [
                        _OverviewTab(
                          profile: profile,
                          onEditData: _openEditData,
                          onEditProducts: _openProductSettings,
                          onOpenDebtLedger: _openDebtLedger,
                          onManageAddresses: () => showPartnerAddressesSheet(
                            context: context,
                            partnerType: _personType,
                            partnerId: widget.person.id,
                          ),
                          onOpenInvoice: (invoice) => _openInvoice(
                            context,
                            type: invoice.invoiceType,
                            id: invoice.invoiceId,
                            invoiceNumber: invoice.invoiceNumber,
                          ),
                        ),
                        _InvoicesTab(
                          invoices: profile.recentInvoices,
                          onOpenInvoice: (invoice) => _openInvoice(
                            context,
                            type: invoice.invoiceType,
                            id: invoice.invoiceId,
                            invoiceNumber: invoice.invoiceNumber,
                          ),
                        ),
                        _ProductsTab(
                          products: profile.purchasedProducts,
                          onEditProducts: _openProductSettings,
                          onHistory: (product) =>
                              _showProductHistory(context, product),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Future<void> _showProductHistory(
    BuildContext context,
    PersonProfileProduct product,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    List<PersonProductHistoryEntry> entries = const [];
    Object? error;
    try {
      entries = await _loadProductHistory(product.productId);
    } catch (e) {
      error = e;
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!context.mounted) return;
    if (error != null) {
      Get.snackbar(
        'error'.tr,
        'تعذر تحميل سجل الأسعار',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductHistorySheet(
        product: product,
        entries: entries,
        onOpenInvoice: (entry) => _openInvoice(
          context,
          type: entry.invoiceType,
          id: entry.invoiceId,
          invoiceNumber: entry.invoiceNumber,
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.profile,
    required this.onEditData,
    required this.onEditProducts,
    required this.onOpenDebtLedger,
    required this.onManageAddresses,
    required this.onOpenInvoice,
  });

  final PersonProfileModel profile;
  final VoidCallback onEditData;
  final VoidCallback onEditProducts;
  final VoidCallback onOpenDebtLedger;
  final VoidCallback onManageAddresses;
  final ValueChanged<PersonProfileInvoice> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final summary = profile.summary;
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _HeaderCard(
          person: profile.person,
          onEditData: onEditData,
          onEditProducts: onEditProducts,
          onManageAddresses: onManageAddresses,
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _StatCard(
                title: 'الفواتير', value: summary.invoiceCount.toString()),
            _StatCard(
                title: 'منتجات مختلفة',
                value: summary.distinctProductsCount.toString()),
            _StatCard(title: 'الكمية', value: _fmt(summary.totalQuantity)),
            _StatCard(
                title: 'إجمالي الدفع', value: '${_fmt(summary.totalPaid)} ₪'),
            _StatCard(
              title: 'الدين علينا',
              value: '${_fmt(summary.debtWeOwe)} ₪',
              onTap: onOpenDebtLedger,
            ),
            _StatCard(
              title: 'الدين لنا',
              value: '${_fmt(summary.debtOwedToUs)} ₪',
              onTap: onOpenDebtLedger,
            ),
            _StatCard(
              title: 'شيكات منه',
              value: '${summary.checksFromPersonCount}',
              subtitle: 'غير مصروفة ${summary.checksFromPersonOpenCount}',
            ),
            _StatCard(
              title: 'شيكات له',
              value: '${summary.checksToPersonCount}',
              subtitle: 'غير مصروفة ${summary.checksToPersonOpenCount}',
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _ChecksSummaryPanel(checks: profile.checks),
        SizedBox(height: 12.h),
        const _SectionTitle(title: 'آخر 5 فواتير'),
        ...profile.recentInvoices.map(
          (invoice) => _InvoiceTile(
            invoice: invoice,
            onTap: () => onOpenInvoice(invoice),
          ),
        ),
        SizedBox(height: 12.h),
        const _SectionTitle(title: 'أكثر المنتجات طلباً'),
        ...profile.topProducts.map(
          (product) => _ProductCompactTile(product: product),
        ),
      ],
    );
  }
}

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({
    required this.invoices,
    required this.onOpenInvoice,
  });

  final List<PersonProfileInvoice> invoices;
  final ValueChanged<PersonProfileInvoice> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(child: Text('لا توجد فواتير لهذا الحساب'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, index) => _InvoiceTile(
        invoice: invoices[index],
        onTap: () => onOpenInvoice(invoices[index]),
      ),
    );
  }
}

enum _ProductFilter { all, belowWholesale, belowCustom }

class _ProductsTab extends StatefulWidget {
  const _ProductsTab({
    required this.products,
    required this.onEditProducts,
    required this.onHistory,
  });

  final List<PersonProfileProduct> products;
  final VoidCallback onEditProducts;
  final ValueChanged<PersonProfileProduct> onHistory;

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final _searchController = TextEditingController();
  _ProductFilter _filter = _ProductFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PersonProfileProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return widget.products.where((product) {
      var matchesFilter = true;
      switch (_filter) {
        case _ProductFilter.all:
          matchesFilter = true;
          break;
        case _ProductFilter.belowWholesale:
          matchesFilter = product.soldBelowWholesale;
          break;
        case _ProductFilter.belowCustom:
          matchesFilter = product.soldBelowCustomPrice;
          break;
      }
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return product.productName.toLowerCase().contains(query) ||
          product.productCode.toLowerCase().contains(query) ||
          product.productId.toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن منتج',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton.filledTonal(
                    tooltip: 'تعديل إظهار المنتجات والأسعار',
                    onPressed: widget.onEditProducts,
                    icon: const Icon(Icons.price_change_outlined),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: _filter == _ProductFilter.all,
                      onSelected: () =>
                          setState(() => _filter = _ProductFilter.all),
                    ),
                    SizedBox(width: 6.w),
                    _FilterChip(
                      label: 'أقل من الجملة',
                      selected: _filter == _ProductFilter.belowWholesale,
                      onSelected: () => setState(
                        () => _filter = _ProductFilter.belowWholesale,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    _FilterChip(
                      label: 'أقل من السعر الخاص',
                      selected: _filter == _ProductFilter.belowCustom,
                      onSelected: () => setState(
                        () => _filter = _ProductFilter.belowCustom,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.products.isEmpty
              ? const Center(child: Text('لم يتم شراء منتجات بعد'))
              : products.isEmpty
                  ? const Center(child: Text('لا توجد منتجات مطابقة'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width >= 1100
                            ? 4
                            : width >= 820
                                ? 3
                                : width >= 520
                                    ? 2
                                    : 1;
                        return GridView.builder(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 8.h,
                            crossAxisSpacing: 8.w,
                            mainAxisExtent: 126.h,
                          ),
                          itemCount: products.length,
                          itemBuilder: (_, index) => _ProductTile(
                            product: products[index],
                            onHistory: () => widget.onHistory(products[index]),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final PersonProfileProduct product;

  @override
  Widget build(BuildContext context) {
    final raw = product.imageUrl;
    final hasImage = raw.trim().isNotEmpty && raw != 'no image';
    final url = ShowNetImage.getThumbnailPhoto(raw);
    return InkWell(
      onTap: hasImage ? () => openProductImageViewer(context, raw) : null,
      borderRadius: BorderRadius.circular(8.r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: 58.w,
          height: 58.w,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 20.sp,
                  ),
                )
              : Icon(Icons.inventory_2_outlined, size: 22.sp),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.person,
    required this.onEditData,
    required this.onEditProducts,
    required this.onManageAddresses,
  });

  final PersonProfilePerson person;
  final VoidCallback onEditData;
  final VoidCallback onEditProducts;
  final VoidCallback onManageAddresses;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person.name,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5.h),
          Text(
            [
              if (person.phone.isNotEmpty) person.phone,
              if (person.jobTitle.isNotEmpty) person.jobTitle,
              person.type == 'seller' ? 'تاجر' : 'زبون',
            ].join(' • '),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
          ),
          if (person.address.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(person.address, style: TextStyle(fontSize: 12.sp)),
          ],
          if (person.createdAt.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              [
                'أضيف على النظام ${formatApiDateTime12(person.createdAt)}',
                if ((person.createdByName ?? '').isNotEmpty)
                  'بواسطة ${person.createdByName}',
              ].join(' • '),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            ),
          ],
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              OutlinedButton.icon(
                onPressed: onEditData,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل البيانات'),
              ),
              FilledButton.icon(
                onPressed: onEditProducts,
                icon: const Icon(Icons.price_change_outlined),
                label: const Text('تعديل المنتجات والأسعار'),
              ),
              OutlinedButton.icon(
                onPressed: onManageAddresses,
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('إدارة العناوين'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
                ),
              ),
              if (onTap != null)
                Icon(Icons.open_in_new_outlined,
                    size: 15.sp, color: Colors.grey.shade600),
            ],
          ),
          if ((subtitle ?? '').isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );

    return SizedBox(
      width: 150.w,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8.r),
              child: content,
            ),
    );
  }
}

class _ChecksSummaryPanel extends StatelessWidget {
  const _ChecksSummaryPanel({required this.checks});

  final PersonProfileChecks checks;

  @override
  Widget build(BuildContext context) {
    final hasChecks = checks.fromPerson.count > 0 || checks.toPerson.count > 0;
    if (!hasChecks) return const SizedBox.shrink();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'الشيكات'),
          _CheckSideRow(
            icon: Icons.call_received_outlined,
            title: 'شيكات منه',
            side: checks.fromPerson,
          ),
          SizedBox(height: 8.h),
          _CheckSideRow(
            icon: Icons.call_made_outlined,
            title: 'شيكات له',
            side: checks.toPerson,
          ),
        ],
      ),
    );
  }
}

class _CheckSideRow extends StatelessWidget {
  const _CheckSideRow({
    required this.icon,
    required this.title,
    required this.side,
  });

  final IconData icon;
  final String title;
  final PersonProfileCheckSide side;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primaryColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            '$title: ${side.count} • غير مصروفة ${side.openCount}',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          _moneyTotals(side.openTotalsByCurrency),
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.onTap});

  final PersonProfileInvoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text('فاتورة ${invoice.invoiceNumber}'),
        subtitle:
            Text('${_invoiceType(invoice.invoiceType)} • ${invoice.soldAt}'),
        trailing: Text('${_fmt(invoice.total)} ₪'),
        onTap: onTap,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onHistory});

  final PersonProfileProduct product;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final hasAlert = product.soldBelowWholesale || product.soldBelowCustomPrice;
    return _Panel(
      child: Row(
        children: [
          _ProductThumb(product: product),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.productName.isEmpty
                            ? '#${product.productId}'
                            : product.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (hasAlert)
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 17.sp,
                        color: Colors.orange.shade700,
                      ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  [
                    if (product.productCode.isNotEmpty) product.productCode,
                    '${product.purchaseCount} مرات',
                    'كمية ${_fmt(product.quantity)}',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Wrap(
                  spacing: 5.w,
                  runSpacing: 4.h,
                  children: [
                    _MiniPrice(label: 'آخر بيع', value: product.lastPrice),
                    _MiniPrice(label: 'أقل بيع', value: product.minPrice),
                    _MiniPrice(
                        label: 'سعر الجملة', value: product.wholesalePrice),
                    if (product.customPrice != null)
                      _MiniPrice(
                          label: 'السعر الخاص', value: product.customPrice!),
                    if (product.priceRuleLabel != null)
                      _RuleChip(label: product.priceRuleLabel!),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          IconButton(
            tooltip: 'سجل الأسعار',
            icon: const Icon(Icons.history),
            onPressed: onHistory,
          ),
        ],
      ),
    );
  }
}

class _MiniPrice extends StatelessWidget {
  const _MiniPrice({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$label ${_fmt(value)}',
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }
}

class _ProductCompactTile extends StatelessWidget {
  const _ProductCompactTile({required this.product});

  final PersonProfileProduct product;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          _ProductThumb(product: product),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName.isEmpty
                      ? '#${product.productId}'
                      : product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3.h),
                Text(
                  'الكمية ${_fmt(product.quantity)} • ${product.purchaseCount} مرات',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${_fmt(product.totalPaid)} ₪',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProductHistorySheet extends StatelessWidget {
  const _ProductHistorySheet({
    required this.product,
    required this.entries,
    required this.onOpenInvoice,
  });

  final PersonProfileProduct product;
  final List<PersonProductHistoryEntry> entries;
  final ValueChanged<PersonProductHistoryEntry> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        constraints: BoxConstraints(maxHeight: 0.62.sh),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سجل أسعار ${product.productName}',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 10.h),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا يوجد سجل أسعار لهذا المنتج',
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${_fmt(entry.cost)} ₪'),
                      subtitle: Text(
                        '${_invoiceType(entry.invoiceType)} #${entry.invoiceNumber}'
                        '\n${entry.soldAt} • الكمية ${_fmt(entry.quantity)}'
                        '${entry.priceRuleLabel == null ? '' : ' • ${entry.priceRuleLabel}'}',
                      ),
                      trailing: const Icon(Icons.open_in_new_outlined),
                      onTap: () {
                        Navigator.pop(context);
                        onOpenInvoice(entry);
                      },
                    );
                  },
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark.value;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkColor : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _PersonProfileSkeleton extends StatelessWidget {
  const _PersonProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _SkeletonBox(height: 118.h, color: base),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: List.generate(
            6,
            (_) => _SkeletonBox(width: 150.w, height: 68.h, color: base),
          ),
        ),
        SizedBox(height: 16.h),
        _SkeletonBox(height: 44.h, color: base),
        SizedBox(height: 10.h),
        ...List.generate(
          5,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _SkeletonBox(height: 72.h, color: base),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    required this.color,
    this.width,
  });

  final double height;
  final double? width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _moneyTotals(Map<String, double> totals) {
  final visible = totals.entries.where((entry) => entry.value.abs() > 0.001);
  if (visible.isEmpty) return '0';
  return visible
      .map((entry) => '${_fmt(entry.value)} ${entry.key}')
      .join(' • ');
}

String _invoiceType(String type) {
  return type == 'sales_order' ? 'طلبية' : 'بيع فوري';
}
