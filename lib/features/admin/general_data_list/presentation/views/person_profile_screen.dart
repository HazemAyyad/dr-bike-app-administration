import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/services/app_dependency_registry.dart';
import 'package:doctorbike/core/services/theme_service.dart';
import 'package:doctorbike/core/utils/app_colors.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/employee_data_model.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/person_profile_model.dart';
import 'package:doctorbike/features/admin/general_data_list/presentation/controllers/general_data_list_controller.dart';
import 'package:doctorbike/features/admin/stock/presentation/utils/open_instant_sale_invoice.dart';
import 'package:doctorbike/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'person_product_settings_screen.dart';

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

  void _openInvoice(
    BuildContext context, {
    required String type,
    required int id,
  }) {
    if (type == 'sales_order') {
      AppDependencyRegistry.ensureSalesOrders();
      Get.toNamed(AppRoutes.SALESORDERDETAILSCREEN, arguments: id);
      return;
    }
    openInstantSaleInvoiceFromStock(context: context, saleId: id.toString());
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
                Tab(text: 'المنتجات والأسعار'),
              ],
            ),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : profile == null
                  ? const Center(child: Text('تعذر تحميل البروفايل'))
                  : TabBarView(
                      children: [
                        _OverviewTab(
                          profile: profile,
                          onEditData: _openEditData,
                          onEditProducts: _openProductSettings,
                          onOpenInvoice: (invoice) => _openInvoice(
                            context,
                            type: invoice.invoiceType,
                            id: invoice.invoiceId,
                          ),
                        ),
                        _InvoicesTab(
                          invoices: profile.recentInvoices,
                          onOpenInvoice: (invoice) => _openInvoice(
                            context,
                            type: invoice.invoiceType,
                            id: invoice.invoiceId,
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
    required this.onOpenInvoice,
  });

  final PersonProfileModel profile;
  final VoidCallback onEditData;
  final VoidCallback onEditProducts;
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
                title: 'الدين علينا', value: '${_fmt(summary.debtWeOwe)} ₪'),
            _StatCard(
                title: 'الدين لنا', value: '${_fmt(summary.debtOwedToUs)} ₪'),
          ],
        ),
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

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({
    required this.products,
    required this.onEditProducts,
    required this.onHistory,
  });

  final List<PersonProfileProduct> products;
  final VoidCallback onEditProducts;
  final ValueChanged<PersonProfileProduct> onHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: onEditProducts,
              icon: const Icon(Icons.price_change_outlined),
              label: const Text('تعديل إظهار المنتجات والأسعار'),
            ),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('لم يتم شراء منتجات بعد'))
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) => _ProductTile(
                    product: products[index],
                    onHistory: () => onHistory(products[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.person,
    required this.onEditData,
    required this.onEditProducts,
  });

  final PersonProfilePerson person;
  final VoidCallback onEditData;
  final VoidCallback onEditProducts;

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
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150.w,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
            SizedBox(height: 6.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
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
    return _Panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(product.productName.isEmpty
            ? '#${product.productId}'
            : product.productName),
        subtitle: Text(
          'اشتراه ${product.purchaseCount} مرات • الكمية ${_fmt(product.quantity)}'
          '\nآخر سعر ${_fmt(product.lastPrice)} ₪ • من ${_fmt(product.minPrice)} إلى ${_fmt(product.maxPrice)} ₪',
        ),
        trailing: IconButton(
          tooltip: 'سجل الأسعار',
          icon: const Icon(Icons.history),
          onPressed: onHistory,
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
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(product.productName.isEmpty
          ? '#${product.productId}'
          : product.productName),
      subtitle: Text(
          'الكمية ${_fmt(product.quantity)} • ${product.purchaseCount} مرات'),
      trailing: Text('${_fmt(product.totalPaid)} ₪'),
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
                        '\n${entry.soldAt} • الكمية ${_fmt(entry.quantity)}',
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

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _invoiceType(String type) {
  return type == 'sales_order' ? 'طلبية' : 'بيع فوري';
}
