import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/maintenance_controller.dart';

class MaintenanceDailyAdminScreen extends StatefulWidget {
  const MaintenanceDailyAdminScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceDailyAdminScreen> createState() =>
      _MaintenanceDailyAdminScreenState();
}

class _MaintenanceDailyAdminScreenState
    extends State<MaintenanceDailyAdminScreen> {
  final MaintenanceController controller = Get.find<MaintenanceController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMaintenanceDailyAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'صناديق الصيانة اليومية',
          action: false,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الصناديق المفتوحة'),
              Tab(text: 'طلبات الإغلاق'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isDailyClosingReviewLoading.value &&
              controller.dailyOpenSessions.isEmpty &&
              controller.dailyClosingRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _OpenMaintenanceSessions(controller: controller),
              _MaintenanceClosingRequests(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _OpenMaintenanceSessions extends StatelessWidget {
  const _OpenMaintenanceSessions({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.dailyOpenSessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadMaintenanceDailyAdminData,
        child: ListView(
          children: [
            SizedBox(height: 0.35.sh),
            const Center(child: Text('لا يوجد صناديق صيانة مفتوحة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadMaintenanceDailyAdminData,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.dailyOpenSessions.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = controller.dailyOpenSessions[index];
          final isPending = item['status']?.toString() == 'closing_requested';
          final canClose = item['can_close'] == true || item['can_close'] == 1;
          final pendingId = _intFrom(item['pending_closing_request_id']);

          return Card(
            child: ListTile(
              title: Text(item['employee_name']?.toString() ?? '-'),
              subtitle: Text(
                [
                  'التاريخ: ${item['business_date'] ?? '-'}',
                  'كاش: ${_money(item['cash_total'])}',
                  'المطلوب ترحيله: ${_money(item['expected_closing_balance'])} ${item['currency'] ?? ''}',
                  if (isPending) 'طلب الإغلاق معلق',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: canClose
                  ? TextButton(
                      onPressed: () => _openCloseScreen(item),
                      child: const Text('إغلاق اليوم'),
                    )
                  : const Icon(Icons.chevron_left),
              onTap: () {
                if (isPending && pendingId != null) {
                  final request = controller.dailyClosingRequests
                      .firstWhereOrNull(
                          (row) => _intFrom(row['id']) == pendingId);
                  if (request != null) {
                    _openRequestScreen(request);
                    return;
                  }
                }
                if (canClose) {
                  _openCloseScreen(item);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCloseScreen(Map<String, dynamic> item) async {
    await Get.toNamed(
      AppRoutes.MAINTENANCEDAILYCLOSESCREEN,
      arguments: {'mode': 'direct', 'session': item},
    );
    await controller.loadMaintenanceDailyAdminData();
  }

  Future<void> _openRequestScreen(Map<String, dynamic> item) async {
    await Get.toNamed(
      AppRoutes.MAINTENANCEDAILYCLOSESCREEN,
      arguments: {'mode': 'review', 'request': item},
    );
    await controller.loadMaintenanceDailyAdminData();
  }
}

class _MaintenanceClosingRequests extends StatelessWidget {
  const _MaintenanceClosingRequests({required this.controller});

  final MaintenanceController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.dailyClosingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadMaintenanceDailyAdminData,
        child: ListView(
          children: [
            SizedBox(height: 0.35.sh),
            const Center(child: Text('لا يوجد طلبات إغلاق معلقة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadMaintenanceDailyAdminData,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.dailyClosingRequests.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = controller.dailyClosingRequests[index];
          return Card(
            child: ListTile(
              title: Text(item['employee_name']?.toString() ?? '-'),
              subtitle: Text(
                [
                  'التاريخ: ${item['business_date'] ?? '-'}',
                  'كاش: ${_money(item['cash_total'])}',
                  'المطلوب ترحيله: ${_money(item['amount_to_transfer'] ?? item['expected_closing_balance'])} ${item['currency'] ?? ''}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_left),
              onTap: () async {
                await Get.toNamed(
                  AppRoutes.MAINTENANCEDAILYCLOSESCREEN,
                  arguments: {'mode': 'review', 'request': item},
                );
                await controller.loadMaintenanceDailyAdminData();
              },
            ),
          );
        },
      ),
    );
  }
}

int? _intFrom(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double _doubleFrom(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(dynamic value) => _doubleFrom(value).toStringAsFixed(2);
