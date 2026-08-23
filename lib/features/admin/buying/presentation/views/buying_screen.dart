import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/json_safe_parser.dart';
import '../../../../../core/helpers/show_no_data.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../binding/buying_binding.dart';
import '../controllers/bills_controller.dart';
import '../widgets/bills_widgets/bills_list.dart';

class BuyingScreen extends GetView<BillsController> {
  const BuyingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BillsController>()) {
      BuyingBinding().dependencies();
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'purchasesandReturns',
          action: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: const TabBar(
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: AppColors.primaryColor,
                  tabs: [
                    Tab(text: 'فواتير الشراء'),
                    Tab(text: 'المرتجعات'),
                    Tab(text: 'الأمانات'),
                    Tab(text: 'الفروقات'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PurchaseInvoicesTab(),
                  const _ReturnPurchasesEntryTab(),
                  const _AmanatDashboardTab(),
                  const _DiscrepanciesDashboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseInvoicesTab extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.allBillsSearch.isEmpty) {
          return const Center(child: ShowNoData());
        }
        final months =
            controller.allBillsSearch.keys.toList().reversed.toList();
        return RefreshIndicator(
          onRefresh: () async => controller.getBills(),
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 90.h),
            itemCount: months.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: _ActionTile(
                    icon: Icons.add_shopping_cart_outlined,
                    title: 'فاتورة شراء جديدة',
                    subtitle: 'اختيار مصدر، منتجات، كميات وأسعار قبل الاستلام',
                    onTap: () {
                      controller.isaddNewBill = '1';
                      Get.toNamed(AppRoutes.ADDNEWBILLSCREEN);
                    },
                  ),
                );
              }
              if (index == 1) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => Get.toNamed(AppRoutes.BILLSSCREEN),
                      icon: Icon(Icons.open_in_new, size: 16.sp),
                      label: const Text('فتح شاشة الفواتير الكاملة'),
                    ),
                  ),
                );
              }
              final month = months[index - 2];
              final bills = controller.allBillsSearch[month] ?? [];
              return BillsList(month: month, bills: bills, page: '1');
            },
          ),
        );
      },
    );
  }
}

class _ReturnPurchasesEntryTab extends StatelessWidget {
  const _ReturnPurchasesEntryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        _ActionTile(
          icon: Icons.assignment_return_outlined,
          title: 'مرتجعات الشراء',
          subtitle: 'متابعة المرتجعات وتسويات الموردين',
          onTap: () => Get.toNamed(AppRoutes.RETURNPURCHASESSCREEN),
        ),
        _ActionTile(
          icon: Icons.add_circle_outline,
          title: 'إنشاء مرتجع شراء',
          subtitle: 'اختيار فاتورة وأصناف وتسوية المرتجع',
          onTap: () => Get.toNamed(AppRoutes.CREATEPURCHASERETURNSCREEN),
        ),
        _ActionTile(
          icon: Icons.inventory_outlined,
          title: 'طلبات الشراء القديمة',
          subtitle: 'مراجعة الحالات القديمة لحين إكمال نقلها',
          onTap: () => Get.toNamed(AppRoutes.PURCHASEORDERSSCREEN),
        ),
      ],
    );
  }
}

class _AmanatDashboardTab extends GetView<BillsController> {
  const _AmanatDashboardTab();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        if (controller.isAmanatDashboardLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.amanatDashboard.isEmpty) {
          return const _EmptyState(text: 'لا توجد أمانات حالياً');
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadAmanatDashboard(),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
            itemCount: controller.amanatDashboard.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (_, index) {
              final row = controller.amanatDashboard[index];
              return _InfoCard(
                icon: Icons.inventory_2_outlined,
                title: asString(row['product_name'], 'منتج'),
                subtitle:
                    '${asString(row['source_name'], 'مصدر غير معروف')} • فاتورة #${asString(row['bill_id'])}',
                chips: [
                  'الكمية ${asString(row['remaining_quantity'])}',
                  asString(row['status']),
                  '${asString(row['age_days'], '0')} يوم',
                ],
                onTap: () => _openBill(row['bill_id']),
              );
            },
          ),
        );
      },
    );
  }
}

class _DiscrepanciesDashboardTab extends GetView<BillsController> {
  const _DiscrepanciesDashboardTab();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BillsController>(
      builder: (controller) {
        if (controller.isDiscrepanciesDashboardLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.discrepanciesDashboard.isEmpty) {
          return const _EmptyState(text: 'لا توجد مشاكل استلام حالياً');
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadDiscrepanciesDashboard(),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
            itemCount: controller.discrepanciesDashboard.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (_, index) {
              final row = controller.discrepanciesDashboard[index];
              return _InfoCard(
                icon: Icons.report_problem_outlined,
                title: asString(row['product_name'], 'منتج'),
                subtitle:
                    '${asString(row['source_name'], 'مصدر غير معروف')} • فاتورة #${asString(row['bill_id'])}',
                chips: [
                  if (asDouble(row['missing_quantity']) > 0)
                    'ناقص ${asString(row['missing_quantity'])}',
                  if (asDouble(row['extra_quantity']) > 0)
                    'أمانة ${asString(row['extra_quantity'])}',
                  if (asDouble(row['damaged_quantity']) > 0)
                    'تالف ${asString(row['damaged_quantity'])}',
                  if (asDouble(row['mismatched_quantity']) > 0)
                    'غير مطابق ${asString(row['mismatched_quantity'])}',
                ],
                onTap: () => _openBill(row['bill_id']),
              );
            },
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_left),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.open_in_new),
      footer: Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        children: chips
            .where((chip) => chip.trim().isNotEmpty)
            .map((chip) => _MiniChip(text: chip))
            .toList(),
      ),
    );
  }
}

class _BaseTile extends StatelessWidget {
  const _BaseTile({
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.footer,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: 21.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
            if (footer != null) ...[
              SizedBox(height: 10.h),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13.sp),
      ),
    );
  }
}

void _openBill(dynamic billId) {
  final id = asString(billId);
  if (id.isEmpty) return;
  Get.find<BillsController>().getBillDetails(
    context: Get.context!,
    billId: id,
  );
  Get.toNamed(AppRoutes.BILLDETAILSSCREEN, arguments: '2');
}
