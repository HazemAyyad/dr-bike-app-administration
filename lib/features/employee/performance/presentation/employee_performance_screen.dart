import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/databases/api/dio_consumer.dart';
import '../data/employee_performance_model.dart';
import 'employee_performance_controller.dart';

class EmployeePerformanceScreen extends StatefulWidget {
  const EmployeePerformanceScreen({Key? key}) : super(key: key);

  @override
  State<EmployeePerformanceScreen> createState() =>
      _EmployeePerformanceScreenState();
}

class _EmployeePerformanceScreenState extends State<EmployeePerformanceScreen> {
  late final EmployeePerformanceController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<EmployeePerformanceController>()
        ? Get.find<EmployeePerformanceController>()
        : Get.put(EmployeePerformanceController(Get.find<DioConsumer>()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F3FF),
        body: Obx(() {
          final data = controller.performance.value;
          if (data == null && controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _header(data),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  child: Column(
                    children: [
                      _periodSelector(),
                      SizedBox(height: 14.h),
                      if (controller.error.value.isNotEmpty)
                        _notice(
                          Icons.cloud_off_rounded,
                          controller.error.value,
                          const Color(0xFFC2413B),
                        ),
                      if (data != null) ...[
                        _sections(data.sections),
                        if (data.section('social') != null) ...[
                          SizedBox(height: 14.h),
                          _social(data.section('social')!),
                        ],
                        SizedBox(height: 14.h),
                        _notice(
                          Icons.lightbulb_outline_rounded,
                          data.improvementTip,
                          const Color(0xFFD18400),
                          title: 'نقطة للتحسين',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _header(EmployeePerformanceModel? data) {
    final score = data?.score;
    final change = data?.change;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 24.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C35D9), Color(0xFF321472)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Text(
            'أدائي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: 142.w,
            height: 142.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: ((score ?? 0) / 100).clamp(0.0, 1.0),
                    strokeWidth: 11.w,
              backgroundColor: Colors.white.withValues(alpha: .18),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF35E0A1)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score == null ? '—' : score.round().toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'من 100',
                      style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            data?.rating ?? 'جاري حساب الأداء',
            style: TextStyle(
              color: const Color(0xFF35E0A1),
              fontSize: 19.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (change != null) ...[
            SizedBox(height: 8.h),
            Text(
              '${change >= 0 ? '↑' : '↓'} ${change.abs().toStringAsFixed(1)} نقطة عن الفترة الماضية',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _periodSelector() => Obx(
    () => Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [_period('شهري', 'monthly'), _period('أسبوعي', 'weekly')],
      ),
    ),
  );

  Widget _period(String label, String value) {
    final selected = controller.period.value == value;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectPeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6730D7) : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5B5870),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sections(List<EmployeePerformanceSection> all) {
    final items = all.where((item) => item.key != 'social').toList();
    return LayoutBuilder(
      builder: (_, limits) => Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children: items
            .map(
              (item) => SizedBox(
                width: (limits.maxWidth - 12.w) / 2,
                child: _section(item),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _section(EmployeePerformanceSection item) {
    const icons = {
      'tasks': Icons.task_alt_rounded,
      'goals': Icons.track_changes_rounded,
      'attendance': Icons.verified_user_outlined,
    };
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icons[item.key] ?? Icons.insights_rounded,
                color: const Color(0xFF6730D7),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            item.score == null ? 'لا بيانات' : '${item.score!.round()}%',
            style: TextStyle(
              fontSize: 23.sp,
              color: const Color(0xFF6730D7),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 9.h),
          LinearProgressIndicator(
            value: ((item.score ?? 0) / 100).clamp(0.0, 1.0),
            minHeight: 6.h,
            borderRadius: BorderRadius.circular(10.r),
            color: const Color(0xFF6730D7),
            backgroundColor: const Color(0xFFE9E3F8),
          ),
        ],
      ),
    );
  }

  Widget _social(EmployeePerformanceSection section) {
    final m = section.metrics;
    final channels = m['channels'] is List ? m['channels'] as List : const [];
    const names = {
      'whatsapp': 'واتساب',
      'facebook': 'فيسبوك',
      'instagram': 'إنستغرام',
    };
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, color: Color(0xFF6730D7)),
              SizedBox(width: 8.w),
              const Expanded(
                child: Text(
                  'أداء الرسائل',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
              Text(
                section.score == null ? '—' : '${section.score!.round()}%',
                style: const TextStyle(
                  color: Color(0xFF6730D7),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 7.w,
            children: channels.map((raw) {
              final row = raw is Map
                  ? Map<String, dynamic>.from(raw)
                  : <String, dynamic>{};
              return Chip(
                label: Text(names['${row['channel']}'] ?? ''),
                backgroundColor: const Color(0xFFF0EBFF),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _metric('${m['handled_conversations'] ?? 0}', 'محادثة'),
              _metric(
                '${m['average_first_response_minutes'] ?? '—'}',
                'دقيقة لأول رد',
              ),
              _metric('${m['resolution_rate'] ?? '—'}%', 'تم حلها'),
              _metric('${m['needs_reply'] ?? 0}', 'تحتاج رد'),
            ],
          ),
          if (m['sample_sufficient'] != true) ...[
            SizedBox(height: 10.h),
            const Text(
              'ستصبح النتيجة أدق بعد التعامل مع 3 محادثات.',
              style: TextStyle(color: Color(0xFF8A6416), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF777287)),
        ),
      ],
    ),
  );

  Widget _notice(IconData icon, String message, Color color, {String? title}) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                if (title != null) SizedBox(height: 3.h),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
