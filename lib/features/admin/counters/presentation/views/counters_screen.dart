import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/helpers/custom_app_bar.dart';
import '../../../../../core/services/theme_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../routes/app_routes.dart';
import '../controllers/counters_controller.dart';

class CountersScreen extends GetView<CountersController> {
  const CountersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        dsibalBack: true,
        title: 'ملخص الأعمال',
        action: false,
        actions: [
          IconButton(
            tooltip: 'التقارير التفصيلية',
            onPressed: () => Get.toNamed(AppRoutes.REPORTSSCREEN),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.analyticsLoading.value && controller.analytics.isEmpty) {
          return const _DashboardSkeleton();
        }
        if (controller.analyticsError.value != null &&
            controller.analytics.isEmpty) {
          return _ErrorState(onRetry: controller.loadAnalytics);
        }
        return RefreshIndicator(
          onRefresh: controller.loadAnalytics,
          child: _DashboardBody(controller: controller),
        );
      }),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller});
  final CountersController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.analytics;
    final summary = _maps(data['summary']);
    final sales = _maps(data['sales_profit_series']);
    final operations = _maps(data['operations_series']);
    final payment = _maps(data['payment_mix']);
    final debts = _maps(data['debts']);
    final checks = _maps(data['checks']);
    final tasks = _maps(data['tasks']);
    final inventory = _map(data['inventory']);
    final period = _map(data['period']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 20.h),
      children: [
        _Header(
          controller: controller,
          period: period,
          generatedAt: data['generated_at']?.toString(),
        ),
        SizedBox(height: 8.h),
        LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxWidth - 8.w) / 2;
          return Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: summary
                .map((item) => SizedBox(
                      width: width,
                      child: _SummaryCard(item: item),
                    ))
                .toList(),
          );
        }),
        SizedBox(height: 8.h),
        _ChartCard(
          title: 'المبيعات والأرباح',
          subtitle: 'الحركة خلال الفترة المحددة',
          chartHeight: 165,
          child: _LineChart(
            data: sales,
            series: const [
              _Series('sales', 'المبيعات', AppColors.primaryColor),
              _Series('profit', 'صافي الربح', Color(0xff16A085)),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        _ChartCard(
          title: 'حركة الأعمال',
          subtitle: 'المبيعات مقابل المصاريف والمشتريات',
          chartHeight: 150,
          child: _BarChart(
            data: operations,
            series: const [
              _Series('sales', 'المبيعات', AppColors.primaryColor),
              _Series('expenses', 'المصاريف', Color(0xffE05A47)),
              _Series('purchases', 'المشتريات', Color(0xffF2A93B)),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 215.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ChartCard(
                title: 'طرق الدفع',
                subtitle: 'توزيع قيمة المبيعات',
                chartHeight: 135,
                child: _DonutChart(data: payment),
              ),
              SizedBox(width: 8.w),
              _ChartCard(
                title: 'الديون الحالية',
                subtitle: 'لنا وعلينا حتى هذه اللحظة',
                chartHeight: 135,
                child: _HorizontalBars(data: debts),
              ),
              SizedBox(width: 8.w),
              _ChartCard(
                title: 'الشيكات',
                subtitle: 'الشيكات الواردة والصادرة غير المصروفة',
                chartHeight: 135,
                child: _HorizontalBars(data: checks),
              ),
              SizedBox(width: 8.w),
              _ChartCard(
                title: 'إنجاز المهام',
                subtitle: 'المهام المنشأة ضمن الفترة',
                chartHeight: 135,
                child: _DonutChart(data: tasks),
              ),
            ]
                .map((widget) => widget is _ChartCard
                    ? SizedBox(width: 280.w, child: widget)
                    : widget)
                .toList(),
          ),
        ),
        SizedBox(height: 8.h),
        _InventoryCard(data: inventory),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.controller, required this.period, this.generatedAt});
  final CountersController controller;
  final Map<String, dynamic> period;
  final String? generatedAt;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('نظرة شاملة على أداء المحل',
                  style:
                      TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 4.h),
              Text('${period['from_date'] ?? ''} — ${period['to_date'] ?? ''}',
                  style:
                      TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
            ]),
          ),
          if (controller.analyticsLoading.value)
            SizedBox(
                width: 18.r,
                height: 18.r,
                child: const CircularProgressIndicator(strokeWidth: 2)),
        ]),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: CountersController.analyticsPeriods.map((item) {
            final selected = controller.selectedPeriod.value == item['key'];
            return Padding(
              padding: EdgeInsetsDirectional.only(end: 7.w),
              child: ChoiceChip(
                selected: selected,
                label: Text(item['label']!),
                onSelected: (_) => item['key'] == 'custom'
                    ? _pickRange(context)
                    : controller.selectAnalyticsPeriod(item['key']!),
                selectedColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp,
                ),
                side: BorderSide.none,
                showCheckmark: false,
              ),
            );
          }).toList()),
        ),
        if (generatedAt != null) ...[
          SizedBox(height: 6.h),
          Text('آخر تحديث: ${_dateTime(generatedAt!)}',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600)),
        ],
      ]),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: controller.customFrom ?? DateTime(now.year, now.month, 1),
        end: controller.customTo ?? now,
      ),
      helpText: 'اختر الفترة',
      saveText: 'تطبيق',
    );
    if (range != null) await controller.setCustomPeriod(range.start, range.end);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final key = item['key']?.toString() ?? '';
    final change = _number(item['change_percent']);
    final increased = change >= 0;
    final favorable = key == 'expenses' ? change <= 0 : change >= 0;
    final meta = _summaryMeta(key);
    return _Surface(
      padding: EdgeInsets.all(12.r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
                color: meta.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9.r)),
            child: Icon(meta.icon, color: meta.color, size: 18.sp),
          ),
          SizedBox(width: 7.w),
          Expanded(
              child: Text(meta.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700))),
        ]),
        SizedBox(height: 10.h),
        Text(_money(item['value']),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w900,
                color: meta.color)),
        SizedBox(height: 5.h),
        Row(children: [
          Icon(increased ? Icons.trending_up : Icons.trending_down,
              size: 14.sp,
              color: favorable
                  ? const Color(0xff15966A)
                  : const Color(0xffD65345)),
          SizedBox(width: 3.w),
          Text('${change.abs().toStringAsFixed(1)}% عن الفترة السابقة',
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600)),
        ]),
      ]),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title,
      required this.subtitle,
      required this.child,
      this.chartHeight = 170});
  final String title;
  final String subtitle;
  final Widget child;
  final double chartHeight;
  @override
  Widget build(BuildContext context) => _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
          SizedBox(height: 3.h),
          Text(subtitle,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600)),
          SizedBox(height: 8.h),
          SizedBox(height: chartHeight.h, child: child),
        ]),
      );
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.data, required this.series});
  final List<Map<String, dynamic>> data;
  final List<_Series> series;
  @override
  Widget build(BuildContext context) => _ChartFrame(
        data: data,
        series: series,
        painter: (data, series, selected) =>
            _LinePainter(data, series, selected),
      );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, required this.series});
  final List<Map<String, dynamic>> data;
  final List<_Series> series;
  @override
  Widget build(BuildContext context) => _ChartFrame(
        data: data,
        series: series,
        painter: (data, series, selected) =>
            _BarPainter(data, series, selected),
      );
}

typedef _PainterFactory = CustomPainter Function(
    List<Map<String, dynamic>>, List<_Series>, int?);

class _ChartFrame extends StatefulWidget {
  const _ChartFrame(
      {required this.data, required this.series, required this.painter});
  final List<Map<String, dynamic>> data;
  final List<_Series> series;
  final _PainterFactory painter;
  @override
  State<_ChartFrame> createState() => _ChartFrameState();
}

class _ChartFrameState extends State<_ChartFrame> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('لا توجد بيانات لهذه الفترة'));
    }
    return Column(children: [
      Wrap(
          spacing: 12.w,
          children: widget.series.map((s) => _Legend(s)).toList()),
      SizedBox(height: 8.h),
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              final usable = math.max(constraints.maxWidth - 32, 1);
              final index = ((details.localPosition.dx - 24) /
                      usable *
                      widget.data.length)
                  .floor();
              setState(() => selected = index.clamp(0, widget.data.length - 1));
            },
            child: Stack(children: [
              CustomPaint(
                  size: Size.infinite,
                  painter:
                      widget.painter(widget.data, widget.series, selected)),
              if (selected != null)
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: _Tooltip(
                      data: widget.data[selected!], series: widget.series),
                ),
            ]),
          );
        }),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.series);
  final _Series series;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8.r,
            height: 8.r,
            decoration:
                BoxDecoration(color: series.color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        Text(series.label,
            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700)),
      ]);
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.data, required this.series});
  final Map<String, dynamic> data;
  final List<_Series> series;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(7.r),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['label']?.toString() ?? '',
              style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w900)),
          ...series.map((s) => Text('${s.label}: ${_money(data[s.key])}',
              style: TextStyle(fontSize: 8.sp, color: s.color))),
        ]),
      );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.data, this.series, this.selected);
  final List<Map<String, dynamic>> data;
  final List<_Series> series;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(25, 4, size.width - 31, size.height - 25);
    final maxValue = math.max(
        1.0,
        data
            .expand((row) => series.map((s) => _number(row[s.key])))
            .fold<double>(0, math.max));
    _grid(canvas, area);
    for (final s in series) {
      final path = Path();
      for (var i = 0; i < data.length; i++) {
        final x = area.left +
            (data.length == 1
                ? area.width / 2
                : area.width * i / (data.length - 1));
        final y =
            area.bottom - (_number(data[i][s.key]) / maxValue * area.height);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = s.color
            ..strokeWidth = 2.3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }
    _labels(canvas, area, data);
    if (selected != null) {
      final x = area.left +
          (data.length == 1
              ? area.width / 2
              : area.width * selected! / (data.length - 1));
      canvas.drawLine(
          Offset(x, area.top),
          Offset(x, area.bottom),
          Paint()
            ..color = Colors.grey.withValues(alpha: .45)
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.selected != selected || old.data != data;
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.data, this.series, this.selected);
  final List<Map<String, dynamic>> data;
  final List<_Series> series;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(25, 4, size.width - 31, size.height - 25);
    final maxValue = math.max(
        1.0,
        data
            .expand((row) => series.map((s) => _number(row[s.key])))
            .fold<double>(0, math.max));
    _grid(canvas, area);
    final group = area.width / math.max(data.length, 1);
    final bar = math.min(10.0, group * .68 / series.length);
    for (var i = 0; i < data.length; i++) {
      for (var j = 0; j < series.length; j++) {
        final value = _number(data[i][series[j].key]);
        final h = value / maxValue * area.height;
        final x = area.left +
            group * i +
            group / 2 +
            (j - (series.length - 1) / 2) * bar;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x - bar * .42, area.bottom - h, bar * .84, h),
                const Radius.circular(2)),
            Paint()
              ..color = series[j].color.withValues(
                  alpha: selected == null || selected == i ? .9 : .35));
      }
    }
    _labels(canvas, area, data);
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.selected != selected || old.data != data;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.data});
  final List<Map<String, dynamic>> data;
  static const colors = [
    AppColors.primaryColor,
    Color(0xffF2A93B),
    Color(0xff16A085),
    Color(0xffE05A47)
  ];
  @override
  Widget build(BuildContext context) {
    final total =
        data.fold<double>(0, (sum, row) => sum + _number(row['value']));
    return Row(children: [
      Expanded(
          child: CustomPaint(
              painter: _DonutPainter(data),
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('الإجمالي',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey)),
                Text(_compact(total),
                    style:
                        TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900))
              ])))),
      SizedBox(width: 8.w),
      Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(data.length, (i) {
                final percent =
                    total == 0 ? 0 : _number(data[i]['value']) / total * 100;
                return Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Row(children: [
                      Container(
                          width: 9.r,
                          height: 9.r,
                          decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: BorderRadius.circular(3))),
                      SizedBox(width: 5.w),
                      Expanded(
                          child: Text(data[i]['label']?.toString() ?? '',
                              style: TextStyle(fontSize: 9.sp))),
                      Text('${percent.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 9.sp, fontWeight: FontWeight.w900))
                    ]));
              }))),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.data);
  final List<Map<String, dynamic>> data;
  @override
  void paint(Canvas canvas, Size size) {
    final total =
        data.fold<double>(0, (sum, row) => sum + _number(row['value']));
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .34;
    var start = -math.pi / 2;
    if (total == 0) {
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.grey.withValues(alpha: .15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 18);
      return;
    }
    for (var i = 0; i < data.length; i++) {
      final sweep = _number(data[i]['value']) / total * math.pi * 2;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          Paint()
            ..color = _DonutChart.colors[i % _DonutChart.colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 18
            ..strokeCap = StrokeCap.butt);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.data != data;
}

class _HorizontalBars extends StatelessWidget {
  const _HorizontalBars({required this.data});
  final List<Map<String, dynamic>> data;
  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(
        1.0,
        data.fold<double>(
            0, (max, row) => math.max(max, _number(row['value']))));
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(data.length, (i) {
          final value = _number(data[i]['value']);
          return Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: Text(data[i]['label']?.toString() ?? '',
                          style: TextStyle(
                              fontSize: 11.sp, fontWeight: FontWeight.w700))),
                  Text(_money(value),
                      style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: i == 0
                              ? AppColors.primaryColor
                              : const Color(0xffE05A47)))
                ]),
                SizedBox(height: 7.h),
                ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: LinearProgressIndicator(
                        value: value / maxValue,
                        minHeight: 9.h,
                        backgroundColor: Colors.grey.withValues(alpha: .12),
                        valueColor: AlwaysStoppedAnimation(i == 0
                            ? AppColors.primaryColor
                            : const Color(0xffE05A47))))
              ]));
        }));
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final top = _maps(data['top_value']);
    return _Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المخزون',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 12.h),
        Row(children: [
          _InventoryMetric('قيمة المخزون', _money(data['value']),
              Icons.inventory_2_outlined),
          _InventoryMetric('إجمالي الكمية', _compact(_number(data['quantity'])),
              Icons.layers_outlined),
          _InventoryMetric('مخزون منخفض', '${data['low_stock_count'] ?? 0}',
              Icons.warning_amber_rounded),
        ]),
        if (top.isNotEmpty) ...[
          SizedBox(height: 18.h),
          Text('الأعلى قيمة في المخزون',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 8.h),
          ...top.take(3).map((row) => Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h),
                child: Row(children: [
                  Expanded(
                      child: Text(row['label']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.sp))),
                  Text(_money(row['value']),
                      style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryColor)),
                ]),
              )),
        ],
      ]),
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Icon(icon, color: AppColors.primaryColor, size: 21.sp),
        SizedBox(height: 6.h),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900)),
        SizedBox(height: 2.h),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.sp, color: Colors.grey.shade600))
      ]));
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: ThemeService.isDark.value
              ? AppColors.customGreyColor4
              : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.withValues(alpha: .10)),
          boxShadow: ThemeService.isDark.value
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .035),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: child,
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: EdgeInsets.all(30.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.query_stats_rounded,
                size: 58.sp, color: AppColors.primaryColor),
            SizedBox(height: 14.h),
            Text('تعذر تحميل الإحصائيات',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 7.h),
            const Text('تحقق من الاتصال ثم حاول مرة أخرى',
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'))
          ])));
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
      padding: EdgeInsets.all(12.r),
      children: List.generate(
          6,
          (i) => Container(
              height: i < 2 ? 105.h : 230.h,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14.r)))));
}

class _Series {
  const _Series(this.key, this.label, this.color);
  final String key;
  final String label;
  final Color color;
}

void _grid(Canvas canvas, Rect area) {
  final paint = Paint()
    ..color = Colors.grey.withValues(alpha: .14)
    ..strokeWidth = 1;
  for (var i = 0; i <= 4; i++) {
    final y = area.top + area.height * i / 4;
    canvas.drawLine(Offset(area.left, y), Offset(area.right, y), paint);
  }
}

void _labels(Canvas canvas, Rect area, List<Map<String, dynamic>> data) {
  if (data.isEmpty) return;
  final step = math.max(1, (data.length / 5).ceil());
  for (var i = 0; i < data.length; i += step) {
    final x = area.left +
        (data.length == 1
            ? area.width / 2
            : area.width * i / (data.length - 1));
    final painter = TextPainter(
        text: TextSpan(
            text: data[i]['label']?.toString() ?? '',
            style: const TextStyle(fontSize: 8, color: Colors.grey)),
        textDirection: Directionality.of(Get.context!))
      ..layout(maxWidth: 45);
    painter.paint(canvas, Offset(x - painter.width / 2, area.bottom + 5));
  }
}

List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
    .toList(growable: false);
Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
String _money(dynamic value) =>
    '${NumberFormat('#,##0.##').format(_number(value))} ₪';
String _compact(double value) =>
    NumberFormat.compact(locale: 'en').format(value);
String _dateTime(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  return parsed == null ? value : DateFormat('dd/MM/yyyy HH:mm').format(parsed);
}

class _SummaryMeta {
  const _SummaryMeta(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

_SummaryMeta _summaryMeta(String key) {
  if (key == 'sales') {
    return const _SummaryMeta(
        'صافي المبيعات', Icons.point_of_sale_rounded, AppColors.primaryColor);
  }
  if (key == 'net_profit') {
    return const _SummaryMeta(
        'صافي الربح', Icons.trending_up_rounded, Color(0xff15966A));
  }
  if (key == 'expenses') {
    return const _SummaryMeta(
        'المصاريف', Icons.payments_outlined, Color(0xffD65345));
  }
  return const _SummaryMeta('المبلغ المحصل',
      Icons.account_balance_wallet_outlined, Color(0xff4B72C2));
}
