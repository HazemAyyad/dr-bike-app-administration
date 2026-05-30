import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../debts/data/models/debt_ledger_models.dart';

class ContactCategoriesSettingsScreen extends StatefulWidget {
  const ContactCategoriesSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ContactCategoriesSettingsScreen> createState() =>
      _ContactCategoriesSettingsScreenState();
}

class _ContactCategoriesSettingsScreenState
    extends State<ContactCategoriesSettingsScreen> {
  final api = Get.find<DioConsumer>();
  final categories = <ContactCategory>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final response = await api.get(EndPoints.contactCategories);
      final data = response.data as Map<String, dynamic>;
      categories
        ..clear()
        ..addAll(
          (data['categories'] as List<dynamic>? ?? [])
              .map((e) => ContactCategory.fromJson(e as Map<String, dynamic>)),
        );
    } catch (_) {
      Get.snackbar('error'.tr, 'حدث خطأ أثناء تحميل التصنيفات');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save({ContactCategory? category}) async {
    final result = await showModalBottomSheet<_CategoryFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _CategoryFormSheet(category: category),
    );
    if (result == null) return;
    try {
      await api.post(
        category == null
            ? EndPoints.contactCategories
            : EndPoints.contactCategoryUpdate(category.id),
        data: {
          'name': result.name,
          'color': result.color,
          'customer_ids': result.customerIds,
          'seller_ids': result.sellerIds,
        },
      );
      await _load();
    } catch (_) {
      Get.snackbar('error'.tr, 'تعذر حفظ التصنيف');
    }
  }

  Future<void> _delete(ContactCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFFF3F4F6),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'حذف التصنيف',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'هل تريد حذف "${category.name}"؟',
            style: const TextStyle(color: Color(0xFF374151)),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('delete'.tr),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await api.post(EndPoints.contactCategoryDelete(category.id));
      await _load();
    } catch (_) {
      Get.snackbar('error'.tr, 'تعذر حذف التصنيف');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'تصنيفات العملاء والموردين',
          action: false,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          onPressed: () => _save(),
          icon: const Icon(Icons.add),
          label: const Text('إضافة تصنيف'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    final category = categories[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _categoryColor(category.color),
                        ),
                        title: Text(
                          category.name,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${category.customersCount} عميل • ${category.sellersCount} مورد',
                          textAlign: TextAlign.right,
                        ),
                        trailing: Wrap(
                          spacing: 4.w,
                          children: [
                            IconButton(
                              onPressed: () => _save(category: category),
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.primaryColor,
                            ),
                            IconButton(
                              onPressed: () => _delete(category),
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _CategoryFormResult {
  const _CategoryFormResult({
    required this.name,
    required this.color,
    required this.customerIds,
    required this.sellerIds,
  });

  final String name;
  final String color;
  final List<int> customerIds;
  final List<int> sellerIds;
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({this.category});

  final ContactCategory? category;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController nameController;
  late String color;
  final customerIds = <int>{};
  final sellerIds = <int>{};

  static const colors = [
    '#6B65BD',
    '#AB67C5',
    '#D8628B',
    '#CF6256',
    '#F18A67',
    '#F5C744',
    '#7FAAD0',
    '#69BDE3',
    '#6592E8',
    '#A7CA72',
    '#6EB98B',
    '#63AFA8',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category?.name ?? '');
    color = widget.category?.color ?? '#6B65BD';
    customerIds.addAll(widget.category?.customerIds ?? const []);
    sellerIds.addAll(widget.category?.sellerIds ?? const []);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _editContacts() async {
    final result = await showModalBottomSheet<_CategoryContactSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _CategoryContactsSheet(
        initialCustomerIds: customerIds,
        initialSellerIds: sellerIds,
      ),
    );
    if (result == null) return;
    setState(() {
      customerIds
        ..clear()
        ..addAll(result.customerIds);
      sellerIds
        ..clear()
        ..addAll(result.sellerIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18.w,
            18.h,
            18.w,
            MediaQuery.of(context).viewInsets.bottom + 18.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.category == null ? 'إضافة تصنيف' : 'تعديل التصنيف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'name'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: colors.map((value) {
                  final selected = value.toLowerCase() == color.toLowerCase();
                  return InkWell(
                    onTap: () => setState(() => color = value),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: _categoryColor(value),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: .2),
                  ),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _editContacts,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryColor.withValues(
                          alpha: .1,
                        ),
                        foregroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('تعديل'),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        'جهات الاتصال (${customerIds.length + sellerIds.length})',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    context,
                    _CategoryFormResult(
                      name: name,
                      color: color,
                      customerIds: customerIds.toList(),
                      sellerIds: sellerIds.toList(),
                    ),
                  );
                },
                child: Text('confirm'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryContactSelection {
  const _CategoryContactSelection({
    required this.customerIds,
    required this.sellerIds,
  });

  final Set<int> customerIds;
  final Set<int> sellerIds;
}

class _CategoryContactsSheet extends StatefulWidget {
  const _CategoryContactsSheet({
    required this.initialCustomerIds,
    required this.initialSellerIds,
  });

  final Set<int> initialCustomerIds;
  final Set<int> initialSellerIds;

  @override
  State<_CategoryContactsSheet> createState() => _CategoryContactsSheetState();
}

class _CategoryContactsSheetState extends State<_CategoryContactsSheet> {
  final api = Get.find<DioConsumer>();
  final searchController = TextEditingController();
  final customers = <LedgerPerson>[];
  final sellers = <LedgerPerson>[];
  late final Set<int> selectedCustomers;
  late final Set<int> selectedSellers;
  bool isCustomerTab = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    selectedCustomers = {...widget.initialCustomerIds};
    selectedSellers = {...widget.initialSellerIds};
    searchController.addListener(_loadPeople);
    _loadPeople();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    setState(() => loading = true);
    try {
      final response = await api.get(
        EndPoints.debtLedgerPeoplePicker,
        queryParameters: {
          'type': isCustomerTab ? 'customers' : 'sellers',
          if (searchController.text.trim().isNotEmpty)
            'search': searchController.text.trim(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final people = (data['people'] as List<dynamic>? ?? [])
          .map((e) => LedgerPerson.fromJson(e as Map<String, dynamic>))
          .toList();
      if (isCustomerTab) {
        customers
          ..clear()
          ..addAll(people);
      } else {
        sellers
          ..clear()
          ..addAll(people);
      }
    } catch (_) {
      Get.snackbar('error'.tr, 'تعذر تحميل جهات الاتصال');
    }
    if (mounted) setState(() => loading = false);
  }

  void _switchTab(bool customersTab) {
    if (isCustomerTab == customersTab) return;
    setState(() => isCustomerTab = customersTab);
    _loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    final people = isCustomerTab ? customers : sellers;
    final selectedSet = isCustomerTab ? selectedCustomers : selectedSellers;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .94,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'ربط جهات الاتصال',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _contactTab(
                          'العملاء',
                          Icons.person_outline,
                          true,
                        ),
                      ),
                      Expanded(
                        child: _contactTab(
                          'الموردين',
                          Icons.local_shipping_outlined,
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: searchController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'search'.tr,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF3F8FE),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          itemCount: people.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.blue.shade50),
                          itemBuilder: (_, index) {
                            final person = people[index];
                            final selected = selectedSet.contains(person.id);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Checkbox(
                                value: selected,
                                activeColor: AppColors.primaryColor,
                                onChanged: (_) => setState(() {
                                  selected
                                      ? selectedSet.remove(person.id)
                                      : selectedSet.add(person.id);
                                }),
                              ),
                              title: Text(
                                person.name,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                person.balance.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                              ),
                              trailing: CircleAvatar(
                                backgroundColor: AppColors.primaryColor
                                    .withValues(alpha: .12),
                                foregroundColor: Colors.black87,
                                child: Text(
                                  person.name.isEmpty
                                      ? ''
                                      : person.name.characters.first,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    _CategoryContactSelection(
                      customerIds: selectedCustomers,
                      sellerIds: selectedSellers,
                    ),
                  ),
                  child: Text('confirm'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactTab(String label, IconData icon, bool customerTab) {
    final selected = isCustomerTab == customerTab;
    return InkWell(
      onTap: () => _switchTab(customerTab),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor.withValues(alpha: .1) : null,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primaryColor : Colors.grey,
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black87 : Colors.grey,
                fontSize: 14.sp,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(String value) {
  final hex = value.replaceAll('#', '').trim();
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return AppColors.primaryColor;
  }
  return Color(int.parse('ff$hex', radix: 16));
}
