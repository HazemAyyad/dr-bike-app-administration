import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/dio_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/app_dependency_registry.dart';
import '../../../../../core/utils/app_colors.dart';

class EmployeeTaskPerformanceScreen extends StatefulWidget {
  const EmployeeTaskPerformanceScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeTaskPerformanceScreen> createState() =>
      _EmployeeTaskPerformanceScreenState();
}

class _EmployeeTaskPerformanceScreenState
    extends State<EmployeeTaskPerformanceScreen> {
  late final ApiConsumer _api;
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppDependencyRegistry.ensureEmployeeTasks();
    _api = Get.find<DioConsumer>();
    _load();
  }

  Future<void> _load() async {
    final employeeId = Get.arguments?['employee_id'];
    if (employeeId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await _api.get(
        EndPoints.employeeTaskPerformance,
        queryParameters: {'employee_id': employeeId.toString()},
      );
      if (res['status'] == 'success') {
        setState(() {
          _data = Map<String, dynamic>.from(res['performance'] as Map);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(title: 'employeePerformance'.tr),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.operationalPurple))
          : _data == null
              ? Center(child: Text('noData'.tr))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.operationalPurple,
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _KpiRow(
                        items: [
                          _KpiCard(
                            title: 'totalPoints'.tr,
                            value: '${_data!['total_points'] ?? 0}',
                            icon: Icons.stars_rounded,
                          ),
                          _KpiCard(
                            title: 'streak'.tr,
                            value: '${_data!['streak_days'] ?? 0}',
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _KpiRow(
                        items: [
                          _KpiCard(
                            title: 'completionRate'.tr,
                            value: '${_data!['completion_rate'] ?? 0}%',
                            icon: Icons.pie_chart_outline_rounded,
                          ),
                          _KpiCard(
                            title: 'overdueCount'.tr,
                            value: '${_data!['overdue_count'] ?? 0}',
                            icon: Icons.warning_amber_rounded,
                            accent: AppColors.redColor,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      _ChartCard(data: _data!['weekly_performance']),
                      SizedBox(height: 20.h),
                      _Leaderboard(
                        items: List<Map<String, dynamic>>.from(
                          _data!['leaderboard'] ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map((w) => Expanded(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: w,
              )))
          .toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.operationalPurple;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.operationalNavy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.operationalNavy,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12.sp, color: AppColors.customGreyColor5),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final completed = List<num>.from(data?['completed'] ?? []);
    final labels = List<String>.from(data?['labels'] ?? []);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'weeklyPerformance'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 160.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(completed.length, (i) {
                final maxVal = completed.isEmpty
                    ? 1.0
                    : completed.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b);
                final h = maxVal > 0 ? (completed[i].toDouble() / maxVal) * 120.h : 0.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h,
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        decoration: BoxDecoration(
                          color: AppColors.operationalPurple,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        labels.length > i ? labels[i] : '',
                        style: TextStyle(fontSize: 9.sp),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'leaderboard'.tr,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.operationalNavy,
            ),
          ),
          SizedBox(height: 12.h),
          ...items.map(
            (e) => ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: AppColors.operationalSurface,
                child: Text('${e['rank']}'),
              ),
              title: Text(e['employee_name']?.toString() ?? ''),
              trailing: Text(
                '${e['points']} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.operationalPurple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
