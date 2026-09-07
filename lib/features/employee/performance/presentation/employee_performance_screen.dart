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
                        _monthlyChart(data.monthlyTrend),
                        SizedBox(height: 14.h),
                        _pointsCard(data.pointsSummary),
                        SizedBox(height: 14.h),
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
    final scoreColor = _performanceColor(score);
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
          _AnimatedPerformanceScore(
            key: ValueKey<String>(
              'performance-${controller.period.value}-$score',
            ),
            score: score,
            color: scoreColor,
          ),
          SizedBox(height: 14.h),
          Text(
            data?.rating ?? 'جاري حساب الأداء',
            style: TextStyle(
              color: scoreColor,
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
            .asMap()
            .entries
            .map(
              (entry) => SizedBox(
                width: items.length.isOdd && entry.key == items.length - 1
                    ? limits.maxWidth
                    : (limits.maxWidth - 12.w) / 2,
                child: _section(entry.value),
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
            item.score == null
                ? _emptySectionLabel(item)
                : '${item.score!.round()}%',
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

  String _emptySectionLabel(EmployeePerformanceSection item) {
    if (item.key == 'tasks') return 'لا توجد مهام ضمن الفترة';
    if (item.key == 'goals') return 'لا توجد أهداف ضمن الفترة';
    if (item.key == 'attendance') return 'لا يوجد سجل دوام';
    return 'لا توجد بيانات';
  }

  Widget _monthlyChart(List<EmployeePerformanceTrendPoint> points) {
    final withData = points.where((point) => point.score != null).length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
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
              const Icon(Icons.show_chart_rounded, color: Color(0xFF6730D7)),
              SizedBox(width: 8.w),
              const Expanded(
                child: Text(
                  'مستوى الأداء خلال الشهر',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            withData == 0
                ? 'سيظهر المنحنى عند توفر مهام أو سجلات دوام.'
                : 'يتحدث يوميًا من إنجاز المهام والالتزام المتوفر.',
            style: const TextStyle(color: Color(0xFF777287), fontSize: 12),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 150.h,
            child: CustomPaint(
              painter: _MonthlyPerformanceChartPainter(points),
              child: const SizedBox.expand(),
            ),
          ),
          if (points.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  points.first.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF777287),
                  ),
                ),
                Text(
                  points[points.length ~/ 2].label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF777287),
                  ),
                ),
                Text(
                  points.last.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF777287),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pointsCard(EmployeePerformancePointsSummary points) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6F1FF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE5DAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF6730D7).withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF6730D7),
                ),
              ),
              SizedBox(width: 10.w),
              const Expanded(
                child: Text(
                  'نقاطي خلال الفترة',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                'الرصيد ${points.lifetimeNet}',
                style: const TextStyle(
                  color: Color(0xFF6730D7),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _pointsMetric(
                'مكتسبة',
                points.earned,
                const Color(0xFF15996E),
                Icons.add_circle_outline,
              ),
              SizedBox(width: 8.w),
              _pointsMetric(
                'مخصومة',
                points.deducted,
                const Color(0xFFD94A4F),
                Icons.remove_circle_outline,
              ),
              SizedBox(width: 8.w),
              _pointsMetric(
                'الصافي',
                points.net,
                points.net < 0
                    ? const Color(0xFFD94A4F)
                    : const Color(0xFF6730D7),
                Icons.balance_rounded,
                signed: true,
              ),
            ],
          ),
          if (!points.available) ...[
            SizedBox(height: 12.h),
            const Text(
              'سجل النقاط غير متوفر حاليًا.',
              style: TextStyle(color: Color(0xFF777287)),
            ),
          ] else if (points.movements.isEmpty) ...[
            SizedBox(height: 12.h),
            const Text(
              'لا توجد حركات نقاط ضمن الفترة المختارة.',
              style: TextStyle(color: Color(0xFF777287)),
            ),
          ] else ...[
            SizedBox(height: 16.h),
            const Text(
              'آخر الحركات',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 7.h),
            ...points.movements.map(_pointMovementRow),
          ],
        ],
      ),
    );
  }

  Widget _pointsMetric(
    String label,
    int value,
    Color color,
    IconData icon, {
    bool signed = false,
  }) {
    final valueText = signed && value > 0 ? '+$value' : '$value';
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 7.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.w),
            SizedBox(height: 5.h),
            Text(
              valueText,
              style: TextStyle(
                color: color,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6F697C)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointMovementRow(EmployeePerformancePointMovement movement) {
    final color = movement.isAdd
        ? const Color(0xFF15996E)
        : const Color(0xFFD94A4F);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            movement.isAdd
                ? Icons.arrow_circle_up_rounded
                : Icons.arrow_circle_down_rounded,
            color: color,
            size: 22.w,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (movement.date.isNotEmpty)
                  Text(
                    movement.date,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8B8495),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${movement.isAdd ? '+' : '-'}${movement.points}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
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

Color _performanceColor(double? score) {
  if (score == null) return const Color(0xFFB8AED2);
  if (score < 50) return const Color(0xFFE5484D);
  if (score < 65) return const Color(0xFFF07A2B);
  if (score < 80) return const Color(0xFFE5B62F);
  if (score < 90) return const Color(0xFF35BFA4);
  return const Color(0xFF24D98B);
}

class _AnimatedPerformanceScore extends StatefulWidget {
  const _AnimatedPerformanceScore({
    Key? key,
    required this.score,
    required this.color,
  }) : super(key: key);

  final double? score;
  final Color color;

  @override
  State<_AnimatedPerformanceScore> createState() =>
      _AnimatedPerformanceScoreState();
}

class _AnimatedPerformanceScoreState extends State<_AnimatedPerformanceScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final target = (widget.score ?? 0).clamp(0.0, 100.0);
    final upper = (target + 9).clamp(0.0, 100.0);
    final lower = (target - 5).clamp(0.0, 100.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: upper,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: upper,
          end: lower,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: lower,
          end: target,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
    ]).animate(_controller);
    if (widget.score != null) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.score == null) {
      return _scoreRing(0, '—');
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => _scoreRing(
        (_animation.value / 100).clamp(0.0, 1.0),
        _animation.value.round().toString(),
      ),
    );
  }

  Widget _scoreRing(double progress, String value) {
    return SizedBox(
      width: 142.w,
      height: 142.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 11.w,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: .18),
              valueColor: AlwaysStoppedAnimation(widget.color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
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
    );
  }
}

class _MonthlyPerformanceChartPainter extends CustomPainter {
  const _MonthlyPerformanceChartPainter(this.points);

  final List<EmployeePerformanceTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE9E3F8)
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.isEmpty) return;

    final line = Paint()
      ..color = const Color(0xFF6730D7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = const Color(0xFF35E0A1)
      ..style = PaintingStyle.fill;
    final path = Path();
    var started = false;
    for (var index = 0; index < points.length; index++) {
      final score = points[index].score;
      if (score == null) {
        started = false;
        continue;
      }
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final y = size.height - (score.clamp(0, 100) / 100 * size.height);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, fill);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MonthlyPerformanceChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
