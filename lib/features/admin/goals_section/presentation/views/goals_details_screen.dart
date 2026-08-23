import 'dart:math' as math;

import 'package:doctorbike/core/helpers/custom_app_bar.dart';
import 'package:doctorbike/core/helpers/showtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../data/models/goals_details_model.dart';
import '../controllers/target_section_controller.dart';

class GoalsDetailsScreen extends GetView<TargetSectionController> {
  const GoalsDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.operationalSurface,
      appBar: CustomAppBar(
        title: 'targetDetails',
        action: false,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: IconButton(
              tooltip: 'shareGoal'.tr,
              onPressed: () => _showShareGoalDialog(context),
              icon: const Icon(Icons.group_add_outlined, size: 30),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: IconButton(
              tooltip: 'edit'.tr,
              onPressed: () => controller.editGoal(),
              icon: const Icon(Icons.edit_calendar_outlined, size: 30),
            ),
          ),
        ],
      ),
      body: GetBuilder<TargetSectionController>(
        builder: (controller) {
          if (controller.isAddLoading.value ||
              controller.goalDetailsList == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final goal = controller.goalDetailsList!.goal;
          final logs = controller.goalDetailsList!.goalLogs;
          final achievement = double.tryParse(goal.achievementPercentage) ?? 0;
          final current = double.tryParse(goal.currentValue) ?? 0;
          final target = double.tryParse(goal.targetedValue) ?? 0;
          final progressColor = _goalProgressColor(achievement);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalHeroCard(
                  goal: goal,
                  achievement: achievement,
                  current: current,
                  target: target,
                  progressColor: progressColor,
                ),
                SizedBox(height: 10.h),
                _GoalProgressChart(
                  history: goal.progressHistory,
                  achievement: achievement,
                  progressColor: progressColor,
                ),
                SizedBox(height: 10.h),
                _GoalInfoGrid(goal: goal),
                if (logs.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  _GoalLogsCard(logs: logs),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showShareGoalDialog(BuildContext context) {
    final goal = controller.goalDetailsList?.goal;
    if (goal == null) return;
    final selected = goal.sharedEmployees.map((e) => e.id).toSet();

    Get.dialog(
      Dialog(
        backgroundColor:
            ThemeService.isDark.value ? AppColors.darkColor : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'shareGoal'.tr,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 330.h,
                    child: ListView.builder(
                      itemCount: controller.employeeList.length,
                      itemBuilder: (context, index) {
                        final employee = controller.employeeList[index];
                        final id = employee.id.toString();
                        return CheckboxListTile(
                          value: selected.contains(id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            });
                          },
                          title: Text(employee.employeeName),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.operationalPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => controller.shareGoalWithEmployees(
                        employeeIds: selected.toList(),
                      ),
                      child: Text(
                        'done'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GoalHeroCard extends StatelessWidget {
  const _GoalHeroCard({
    required this.goal,
    required this.achievement,
    required this.current,
    required this.target,
    required this.progressColor,
  });

  final Goal goal;
  final double achievement;
  final double current;
  final double target;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final progress = (achievement / 100).clamp(0.0, 1.0);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: ThemeService.isDark.value
                                ? Colors.white
                                : AppColors.operationalNavy,
                          ),
                    ),
                    SizedBox(height: 7.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        _StatusChip(
                          label: _goalStatusLabel(achievement),
                          color: progressColor,
                        ),
                        if (goal.scope.isNotEmpty)
                          _SoftChip(label: goal.scope.tr),
                        if (goal.type.isNotEmpty)
                          _SoftChip(label: goal.type.tr),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 68.h,
                    width: 68.h,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Text(
                    '${achievement.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: progressColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  title: 'currentValue',
                  value: _compactNumber(current),
                  color: AppColors.operationalPurple,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MetricTile(
                  title: 'targetValue',
                  value: _compactNumber(target),
                  color: AppColors.operationalNavy,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _MetricTile(
                  title: 'date',
                  value: goal.dueDate.isEmpty ? '-' : showData(goal.dueDate),
                  color: progressColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalProgressChart extends StatelessWidget {
  const _GoalProgressChart({
    required this.history,
    required this.achievement,
    required this.progressColor,
  });

  final List<GoalProgressPoint> history;
  final double achievement;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final points = history
        .map((e) => double.tryParse(e.achievementPercentage) ?? 0)
        .toList();
    final chartPoints = points.length >= 2 ? points : [0.0, achievement];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stacked_line_chart_rounded,
                size: 20.sp,
                color: progressColor,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'progress'.tr,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                history.isEmpty ? 'اليوم'.tr : '${history.length} ${'date'.tr}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.customGreyColor5,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 118.h,
            width: double.infinity,
            child: CustomPaint(
              painter: _ProgressChartPainter(
                values: chartPoints,
                color: progressColor,
                gridColor: ThemeService.isDark.value
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.operationalNavy.withValues(alpha: 0.08),
              ),
            ),
          ),
          if (history.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    showData(history.first.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  showData(history.last.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalInfoGrid extends StatelessWidget {
  const _GoalInfoGrid({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      if (goal.startDate.isNotEmpty)
        _InfoItem('fromDate', showData(goal.startDate), Icons.play_arrow),
      if (goal.calculationMode.isNotEmpty)
        _InfoItem(
          'calculationMode',
          goal.calculationMode.tr,
          Icons.functions_rounded,
        ),
      if (goal.form.isNotEmpty)
        _InfoItem('options', goal.form.tr, Icons.tune_rounded),
      if (goal.employee != null)
        _InfoItem('employeeName', goal.employee!.name, Icons.person_outline),
      if (goal.box != null && goal.box!.name.isNotEmpty)
        _InfoItem('boxName', goal.box!.name, Icons.account_balance_wallet),
      if (goal.people?.isNotEmpty ?? false)
        ...goal.people!.expand(
          (person) => [
            if (person.customerName.isNotEmpty)
              _InfoItem('customerName', person.customerName, Icons.groups),
            if (person.sellerName.isNotEmpty)
              _InfoItem('sellerName', person.sellerName, Icons.badge_outlined),
          ],
        ),
      if (goal.storeSections.isNotEmpty)
        _InfoItem(
          'store_sections',
          goal.storeSections.map((e) => e.name).join('، '),
          Icons.place_outlined,
        ),
      if (goal.products?.isNotEmpty ?? false)
        _InfoItem(
          'productName',
          goal.products!.map((e) => e.name).join('، '),
          Icons.inventory_2_outlined,
        ),
      if (goal.sharedEmployees.isNotEmpty)
        _InfoItem(
          'sharedEmployees',
          goal.sharedEmployees.map((e) => e.name).join('، '),
          Icons.group_outlined,
        ),
      if ((goal.notes ?? '').isNotEmpty)
        _InfoItem('notes', goal.notes!, Icons.notes_rounded),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'targetDetails'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: items
                .map(
                  (item) => _InfoChip(item: item),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GoalLogsCard extends StatelessWidget {
  const _GoalLogsCard({required this.logs});

  final List<GoalLog> logs;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'log'.tr,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
          ),
          SizedBox(height: 8.h),
          ...logs.take(5).map(
                (log) => Padding(
                  padding: EdgeInsets.only(bottom: 7.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        margin: EdgeInsets.only(top: 6.h),
                        decoration: const BoxDecoration(
                          color: AppColors.operationalPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${log.title} - ${log.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ThemeService.isDark.value
            ? AppColors.customGreyColor
            : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: ThemeService.isDark.value
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.operationalNavy.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 60.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10.sp,
                  color: AppColors.customGreyColor5,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 13.sp,
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158.w,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.operationalSurface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 17.sp,
            color: AppColors.operationalPurple,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 10.sp,
                        color: AppColors.customGreyColor5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.operationalPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.operationalPurple,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  _ProgressChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxValue = math.max(100.0, values.reduce(math.max));
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width
          : size.width * i / (values.length - 1);
      final y = size.height -
          ((values[i].clamp(0, maxValue) / maxValue) * size.height);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 3.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor;
  }
}

Color _goalProgressColor(double achievement) {
  if (achievement >= 100) return const Color(0xFFD4AF37);
  if (achievement >= 80) return Colors.green;
  if (achievement >= 50) return AppColors.operationalPurple;
  return Colors.redAccent;
}

String _goalStatusLabel(double achievement) {
  if (achievement >= 100) return 'محقق';
  if (achievement >= 80) return 'ممتاز';
  if (achievement >= 50) return 'قيد التقدم';
  return 'متأخر';
}

String _compactNumber(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
