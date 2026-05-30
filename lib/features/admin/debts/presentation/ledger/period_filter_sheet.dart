import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../../core/utils/app_colors.dart';
import '../../data/models/debt_ledger_models.dart';
import '../controllers/debt_ledger_controller.dart';
import 'ledger_colors.dart';

class PeriodFilterSheet extends StatelessWidget {
  const PeriodFilterSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();
    final periods = <Map<String, String>>[
      {'key': 'all', 'label': 'ledgerPeriodAll'.tr},
      {'key': 'today', 'label': 'ledgerPeriodToday'.tr},
      {'key': 'yesterday', 'label': 'ledgerPeriodYesterday'.tr},
      {'key': 'current_week', 'label': 'ledgerPeriodCurrentWeek'.tr},
      {'key': 'last_week', 'label': 'ledgerPeriodLastWeek'.tr},
      {'key': 'current_month', 'label': 'ledgerPeriodCurrentMonth'.tr},
      {'key': 'last_month', 'label': 'ledgerPeriodLastMonth'.tr},
      {'key': 'custom', 'label': 'ledgerPeriodCustom'.tr},
    ];
    final sortOptions = <Map<String, String>>[
      {'key': 'newest', 'label': 'ledgerSortNewest'.tr},
      {'key': 'oldest', 'label': 'ledgerSortOldest'.tr},
      {'key': 'largest_amount', 'label': 'ledgerSortLargestAmount'.tr},
      {'key': 'smallest_amount', 'label': 'ledgerSortSmallestAmount'.tr},
      {'key': 'alphabetical', 'label': 'ledgerSortAlphabetical'.tr},
    ];
    final debtTypeOptions = <Map<String, String>>[
      {'key': 'all', 'label': 'all'.tr},
      {'key': 'taken', 'label': 'took'.tr},
      {'key': 'given', 'label': 'gave'.tr},
      {'key': 'settled', 'label': 'ledgerDebtTypeSettled'.tr},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ledgerFilters'.tr,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: LedgerColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => _FilterCardSection(
                        title: 'ledgerFilterBy'.tr,
                        children: periods
                            .map(
                              (p) => _FilterOptionTile(
                                label: p['label']!,
                                selected:
                                    controller.selectedPeriod.value == p['key'],
                                onTap: () {
                                  final key = p['key']!;
                                  controller.selectedPeriod.value = key;
                                  if (key != 'custom') {
                                    controller.customStartDate.value = null;
                                    controller.customEndDate.value = null;
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Obx(() {
                      if (controller.selectedPeriod.value != 'custom') {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          ListTile(
                            title: Text('ledgerStartDate'.tr),
                            subtitle: Text(
                              controller.customStartDate.value != null
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(controller.customStartDate.value!)
                                  : '—',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                locale: const Locale('ar'),
                              );
                              if (date != null) {
                                controller.customStartDate.value = date;
                              }
                            },
                          ),
                          ListTile(
                            title: Text('ledgerEndDate'.tr),
                            subtitle: Text(
                              controller.customEndDate.value != null
                                  ? DateFormat('yyyy-MM-dd')
                                      .format(controller.customEndDate.value!)
                                  : '—',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                locale: const Locale('ar'),
                              );
                              if (date != null) {
                                controller.customEndDate.value = date;
                              }
                            },
                          ),
                        ],
                      );
                    }),
                    SizedBox(height: 10.h),
                    Obx(
                      () => _FilterCardSection(
                        title: 'ledgerDebtTypeFilter'.tr,
                        children: debtTypeOptions
                            .map(
                              (option) => _FilterOptionTile(
                                label: option['label']!,
                                selected: controller.selectedDebtType.value ==
                                    option['key'],
                                onTap: () =>
                                    controller.changeDebtType(option['key']!),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Obx(
                      () => _FilterCardSection(
                        title: 'ledgerSortBy'.tr,
                        children: sortOptions
                            .map(
                              (option) => _FilterOptionTile(
                                label: option['label']!,
                                selected: controller.selectedSort.value ==
                                    option['key'],
                                onTap: () =>
                                    controller.changeSort(option['key']!),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _CategoryFilterSection(controller: controller),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LedgerColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                if (controller.selectedPeriod.value == 'custom') {
                  controller.setCustomPeriod(
                    controller.customStartDate.value,
                    controller.customEndDate.value,
                  );
                } else {
                  controller.applyPeriod(controller.selectedPeriod.value);
                }
                Get.back();
              },
              child: Text('ledgerApply'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCardSection extends StatelessWidget {
  const _FilterCardSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: LedgerColors.primaryBlue,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8.w) / 2;
              return Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: children
                    .map((child) => SizedBox(width: itemWidth, child: child))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 50.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected ? LedgerColors.primaryBlue : Colors.blue.shade50,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? LedgerColors.primaryBlue : Colors.blue.shade50,
              size: 22.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF374151),
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterSection extends StatelessWidget {
  const _CategoryFilterSection({required this.controller});

  final DebtLedgerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = controller.selectedCategoryId.value;
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade100),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ledgerCategories'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: LedgerColors.primaryBlue,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => Get.bottomSheet(
                    const LedgerCategoryManagerSheet(),
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size(0, 40.h),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    'ledgerManageCategories'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'ledgerCategoryScopeHint'.tr,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                ChoiceChip(
                  label: Text('ledgerAllCategories'.tr),
                  selected: selectedId == null,
                  onSelected: (_) => controller.applyCategory(null),
                ),
                ...controller.categories.map((category) {
                  final color = _hexColor(category.color);
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: selectedId == category.id,
                    selectedColor: color.withValues(alpha: 0.14),
                    avatar: CircleAvatar(backgroundColor: color, radius: 5.r),
                    onSelected: (_) => controller.applyCategory(category.id),
                  );
                }),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class LedgerCategoryManagerSheet extends StatelessWidget {
  const LedgerCategoryManagerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DebtLedgerController>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .82,
          ),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ledgerManageCategories'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () => Get.bottomSheet(
                  const LedgerCategoryFormSheet(),
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                ),
                child: Text('ledgerAddCategory'.tr),
              ),
              SizedBox(height: 10.h),
              Flexible(
                child: Obx(() {
                  if (controller.categories.isEmpty) {
                    return Center(child: Text('noData'.tr));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.categories.length,
                    separatorBuilder: (_, __) => Divider(height: 14.h),
                    itemBuilder: (_, index) {
                      final category = controller.categories[index];
                      return ListTile(
                        onTap: () => Get.bottomSheet(
                          LedgerCategoryFormSheet(category: category),
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _hexColor(category.color),
                        ),
                        title: Text(category.name),
                        subtitle: Text(
                          '${category.customersCount} ${'ledgerCustomerCount'.tr} • ${category.sellersCount} ${'ledgerSupplierCount'.tr}',
                        ),
                        trailing: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryColor,
                        ),
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: 10.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Get.back(),
                child: Text('confirm'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LedgerCategoryFormSheet extends StatefulWidget {
  const LedgerCategoryFormSheet({Key? key, this.category}) : super(key: key);

  final ContactCategory? category;

  @override
  State<LedgerCategoryFormSheet> createState() =>
      _LedgerCategoryFormSheetState();
}

class _LedgerCategoryFormSheetState extends State<LedgerCategoryFormSheet> {
  final nameController = TextEditingController();
  final selectedCustomers = <int>{};
  final selectedSellers = <int>{};
  String color = '#2196F3';
  bool saving = false;

  bool get isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      nameController.text = category.name;
      color = category.color;
      selectedCustomers.addAll(category.customerIds);
      selectedSellers.addAll(category.sellerIds);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _editContacts() async {
    final ledger = Get.find<DebtLedgerController>();
    final selection = await Get.bottomSheet<_CategoryContactSelection>(
      _CategoryContactsSheet(
        repository: ledger.repository,
        initialCustomerIds: selectedCustomers,
        initialSellerIds: selectedSellers,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
    if (selection == null) return;
    setState(() {
      selectedCustomers
        ..clear()
        ..addAll(selection.customerIds);
      selectedSellers
        ..clear()
        ..addAll(selection.sellerIds);
    });
  }

  Future<void> _pickColor() async {
    final picked = await Get.bottomSheet<String>(
      _CategoryColorSheet(selected: color),
      backgroundColor: Colors.white,
    );
    if (picked != null) setState(() => color = picked);
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => saving = true);
    final ok = await Get.find<DebtLedgerController>().saveCategory(
      id: widget.category?.id,
      name: name,
      color: color,
      customerIds: selectedCustomers.toList(),
      sellerIds: selectedSellers.toList(),
    );
    setState(() => saving = false);
    if (ok) {
      Get.back();
    }
  }

  Future<void> _delete() async {
    final id = widget.category?.id;
    if (id == null) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFFF3F4F6),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'delete'.tr,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل تريد حذف هذا التصنيف؟',
          style: TextStyle(color: Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
            ),
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await Get.find<DebtLedgerController>().deleteCategory(id);
    if (ok) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            12.h,
            16.w,
            MediaQuery.of(context).viewInsets.bottom + 16.h,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .9 -
                MediaQuery.of(context).viewInsets.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        isEdit ? 'تعديل التصنيف' : 'ledgerAddCategory'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'name'.tr,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickColor,
                              child: Container(
                                width: 54.w,
                                height: 54.w,
                                decoration: BoxDecoration(
                                  color: _hexColor(color),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                controller: nameController,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  hintText: 'name'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: .28),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: .25),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color:
                                  AppColors.primaryColor.withValues(alpha: .22),
                            ),
                          ),
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: _editContacts,
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor
                                      .withValues(alpha: .1),
                                  foregroundColor: AppColors.primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('تعديل'),
                              ),
                              const Spacer(),
                              Text(
                                'جهات الاتصال (${selectedCustomers.length + selectedSellers.length})',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: saving ? null : _save,
                        child: saving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text('confirm'.tr),
                      ),
                    ),
                    if (isEdit) ...[
                      SizedBox(width: 14.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8E0E3),
                            foregroundColor: Colors.red.shade500,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onPressed: saving ? null : _delete,
                          child: Text('delete'.tr),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
    required this.repository,
    required this.initialCustomerIds,
    required this.initialSellerIds,
  });

  final dynamic repository;
  final Set<int> initialCustomerIds;
  final Set<int> initialSellerIds;

  @override
  State<_CategoryContactsSheet> createState() => _CategoryContactsSheetState();
}

class _CategoryContactsSheetState extends State<_CategoryContactsSheet> {
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
    final type = isCustomerTab ? 'customers' : 'sellers';
    final result = await widget.repository.getPeoplePicker(
      type: type,
      search: searchController.text.trim(),
    );
    if (!mounted) return;
    result.fold(
      (_) => null,
      (people) {
        setState(() {
          if (isCustomerTab) {
            customers
              ..clear()
              ..addAll(people);
          } else {
            sellers
              ..clear()
              ..addAll(people);
          }
        });
      },
    );
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
                      onPressed: () => Get.back(),
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
                              'العملاء', Icons.person_outline, true)),
                      Expanded(
                          child: _contactTab('الموردين',
                              Icons.local_shipping_outlined, false)),
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
                                child: Text(person.name.isEmpty
                                    ? ''
                                    : person.name.characters.first),
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
                  onPressed: () => Get.back(
                    result: _CategoryContactSelection(
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
            Icon(icon,
                color: selected ? AppColors.primaryColor : Colors.grey,
                size: 22.sp),
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

class _CategoryColorSheet extends StatelessWidget {
  const _CategoryColorSheet({required this.selected});

  final String selected;

  static const colors = [
    '#AB67C5',
    '#D8628B',
    '#CF6256',
    '#F18A67',
    '#F5C744',
    '#7FAAD0',
    '#69BDE3',
    '#6592E8',
    '#7A85C1',
    '#A793CC',
    '#9AA4D0',
    '#8E70C8',
    '#A89184',
    '#9E9E9E',
    '#A7CA72',
    '#6EB98B',
    '#63AFA8',
    '#67C4D5',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختر اللون',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 18.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: colors.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemBuilder: (_, index) {
                  final value = colors[index];
                  final isSelected =
                      selected.toLowerCase() == value.toLowerCase();
                  return InkWell(
                    onTap: () => Get.back(result: value),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _hexColor(value),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 30)
                          : null,
                    ),
                  );
                },
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
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _hexColor(String value) {
  final hex = value.replaceAll('#', '').trim();
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return LedgerColors.primaryBlue;
  }
  return Color(int.parse('ff$hex', radix: 16));
}
