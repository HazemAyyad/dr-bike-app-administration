import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../controllers/online_store_dashboard_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_state_view.dart';

class OnlineStoreStatisticsScreen
    extends GetView<OnlineStoreDashboardController> {
  const OnlineStoreStatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: const Text('إحصائيات المتجر'),
          actions: [
            Obx(() => PopupMenuButton<int>(
                  tooltip: 'الفترة الزمنية',
                  initialValue: controller.periodDays.value,
                  onSelected: controller.setPeriod,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 7, child: Text('آخر 7 أيام')),
                    PopupMenuItem(value: 30, child: Text('آخر 30 يومًا')),
                    PopupMenuItem(value: 90, child: Text('آخر 90 يومًا')),
                    PopupMenuItem(value: 365, child: Text('آخر سنة')),
                  ],
                  icon: const Icon(Icons.calendar_month_outlined),
                )),
          ],
        ),
        body: Obx(() {
          final summary = controller.summary.value;
          return OnlineStoreStateView(
            loading: controller.loading.value,
            error: controller.error.value,
            isEmpty: summary == null,
            onRetry: controller.load,
            child: RefreshIndicator(
              onRefresh: controller.load,
              child: _StatisticsBody(summary: summary),
            ),
          );
        }),
      );
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.summary});
  final OnlineStoreDashboardSummary? summary;

  @override
  Widget build(BuildContext context) {
    final values = summary?.values ?? const <String, dynamic>{};
    final analytics = onlineStoreMap(values['analytics']);
    final audience = onlineStoreMap(analytics['audience']);
    final engagement = onlineStoreMap(analytics['engagement']);
    final commerce = onlineStoreMap(analytics['commerce']);
    final discounts = onlineStoreMap(analytics['discounts']);
    final coupons = onlineStoreMap(discounts['coupons']);
    final promotions = onlineStoreMap(discounts['promotions']);
    final catalog = onlineStoreMap(analytics['catalog']);
    final reviews = onlineStoreMap(analytics['reviews']);
    final daily = onlineStoreRows(analytics['daily']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          const Expanded(
            child: Text('نظرة عامة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          Text(
            '${analytics['period_from'] ?? ''} — ${analytics['period_to'] ?? ''}',
            style: const TextStyle(
                fontSize: 10, color: OnlineStoreAdminUi.textSecondary),
          ),
        ]),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: .78,
          children: [
            _MetricCard('الزيارات', audience['visits'],
                Icons.visibility_outlined, const Color(0xFF1D5D9B)),
            _MetricCard('الزوار', audience['unique_visitors'],
                Icons.groups_outlined, const Color(0xFF7A4D00)),
            _MetricCard('المستخدمون', audience['registered_users'],
                Icons.person_outline, OnlineStoreAdminUi.accent),
            _MetricCard('الطلبات', commerce['orders'],
                Icons.receipt_long_outlined, OnlineStoreAdminUi.success),
            _MetricCard('مشاهدات المنتجات', engagement['product_views'],
                Icons.inventory_2_outlined, const Color(0xFF005A6F)),
            _MetricCard('الإيراد', '${commerce['revenue'] ?? 0} ₪',
                Icons.payments_outlined, const Color(0xFF137333)),
            _MetricCard('استخدام الكوبونات', coupons['uses'],
                Icons.confirmation_number_outlined, const Color(0xFF9A6700)),
            _MetricCard('الاستفادة من العروض', promotions['uses'],
                Icons.local_offer_outlined, const Color(0xFF9B2C68)),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'الأداء خلال الفترة',
          subtitle: 'الزيارات والطلبات يومًا بيوم',
          child: _TrendChart(daily),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'التفاعل مع الواجهة',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ValueChip('مشاهدات الأقسام', engagement['section_views']),
              _ValueChip('ضغطات البانرات', engagement['banner_clicks']),
              _ValueChip('الحسابات المرتبطة', audience['linked_users']),
              _ValueChip('روابط العملاء', audience['active_customer_links']),
              _ValueChip('روابط الموردين', audience['active_seller_links']),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'فعالية المبيعات والخصومات',
          child: Column(children: [
            _DataRow('متوسط قيمة الطلب',
                '${commerce['average_order_value'] ?? 0} ₪'),
            _DataRow('توفير الكوبونات', '${coupons['discount_total'] ?? 0} ₪'),
            _DataRow('توفير العروض', '${promotions['discount_total'] ?? 0} ₪'),
            _DataRow('المراجعات المنشورة', reviews['published']),
            _DataRow('متوسط التقييم', reviews['average_rating']),
            _DataRow('مراجعات بانتظار الإشراف', reviews['pending']),
          ]),
        ),
        const SizedBox(height: 10),
        _TopList(
          title: 'أكثر المنتجات مشاهدة',
          rows: onlineStoreRows(analytics['top_products']),
          nameKey: 'name',
        ),
        const SizedBox(height: 10),
        _TopList(
          title: 'أكثر الأقسام مشاهدة',
          rows: onlineStoreRows(analytics['top_sections']),
          nameKey: 'name',
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'تغطية محتوى المتجر',
          child: Column(children: [
            _DataRow('المنتجات المنشورة',
                summary?.countPath('listings', 'published') ?? 0),
            _DataRow('منتجات نفدت',
                summary?.countPath('listings', 'out_of_stock') ?? 0),
            _DataRow('التصنيفات النشطة',
                '${catalog['active_categories'] ?? 0} / ${catalog['categories'] ?? 0}'),
            _DataRow('الأقسام الظاهرة',
                '${catalog['visible_sections'] ?? 0} / ${catalog['sections'] ?? 0}'),
            _DataRow('البانرات النشطة',
                '${catalog['active_banners'] ?? 0} / ${catalog['banners'] ?? 0}'),
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, this.color);
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$value',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9, color: OnlineStoreAdminUi.textSecondary)),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 10, color: OnlineStoreAdminUi.textSecondary)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _TrendChart extends StatelessWidget {
  const _TrendChart(this.rows);
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox(
          height: 180, child: Center(child: Text('لا توجد بيانات بعد.')));
    }
    return Column(children: [
      SizedBox(
        height: 185,
        width: double.infinity,
        child: CustomPaint(painter: _TrendPainter(rows)),
      ),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _LegendDot(OnlineStoreAdminUi.accent, 'الزيارات'),
        SizedBox(width: 16),
        _LegendDot(OnlineStoreAdminUi.success, 'الطلبات'),
      ]),
    ]);
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.rows);
  final List<Map<String, dynamic>> rows;

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 10.0;
    final rect = Rect.fromLTWH(
        inset, inset, size.width - inset * 2, size.height - inset * 2);
    final grid = Paint()..color = OnlineStoreAdminUi.border;
    for (var i = 0; i <= 4; i++) {
      final y = rect.top + rect.height * i / 4;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }

    final maxValue = rows.fold<double>(
        1,
        (current, row) => math.max(
            current, math.max(_number(row['visits']), _number(row['orders']))));
    void drawSeries(String key, Color color) {
      final path = Path();
      for (var i = 0; i < rows.length; i++) {
        final x = rows.length == 1
            ? rect.center.dx
            : rect.left + rect.width * i / (rows.length - 1);
        final y = rect.bottom - rect.height * _number(rows[i][key]) / maxValue;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawSeries('visits', OnlineStoreAdminUi.accent);
    drawSeries('orders', OnlineStoreAdminUi.success);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.rows != rows;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ]);
}

class _ValueChip extends StatelessWidget {
  const _ValueChip(this.label, this.value);
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$label: ${value ?? 0}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value);
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text('${value ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}

class _TopList extends StatelessWidget {
  const _TopList(
      {required this.title, required this.rows, required this.nameKey});
  final String title;
  final List<Map<String, dynamic>> rows;
  final String nameKey;
  @override
  Widget build(BuildContext context) => _SectionCard(
        title: title,
        child: rows.isEmpty
            ? const Text('لا توجد بيانات بعد.')
            : Column(
                children: rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: OnlineStoreAdminUi.surfaceMuted,
                      child: Text('${entry.key + 1}',
                          style: const TextStyle(fontSize: 11)),
                    ),
                    title: Text('${row[nameKey] ?? '#${row['id'] ?? ''}'}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text('${row['view_count'] ?? 0} مشاهدة',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  );
                }).toList(growable: false),
              ),
      );
}
