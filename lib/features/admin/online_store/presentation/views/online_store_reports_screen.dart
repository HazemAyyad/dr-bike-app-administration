import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/online_store_models.dart';
import '../controllers/online_store_reports_controller.dart';
import '../utils/online_store_admin_ui.dart';
import '../widgets/online_store_form_widgets.dart';

class OnlineStoreReportsScreen extends GetView<OnlineStoreReportsController> {
  const OnlineStoreReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(
          title: const Text('تقارير المتجر'),
          actions: [
            IconButton(
              tooltip: 'تصفية التقرير',
              onPressed: () => _showFilters(context),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.loading.value) return const _ReportSkeleton();
          if (controller.error.value != null) {
            return Center(child: Text(controller.error.value!));
          }
          if (controller.data.isEmpty) {
            return const Center(child: Text('التقرير غير متاح لهذه المرشحات'));
          }

          final orders = onlineStoreMap(controller.data['orders']);
          final listings = onlineStoreMap(controller.data['listings']);
          final coupons = onlineStoreMap(controller.data['coupons']);
          final promotions = onlineStoreMap(controller.data['promotions']);
          final reviews = onlineStoreMap(controller.data['reviews']);
          final debt = onlineStoreMap(controller.data['debt_activity']);
          final bestSelling = onlineStoreRows(controller.data['best_selling']);

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'آخر تحديث: ${onlineStoreFriendlyDate(controller.data['generated_at'])}',
                  style: const TextStyle(
                      fontSize: 11, color: OnlineStoreAdminUi.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _MetricCard(
                    label: 'عدد الطلبات',
                    value: '${orders['count'] ?? 0}',
                    icon: Icons.receipt_long_outlined,
                  ),
                  _MetricCard(
                    label: 'إجمالي المبيعات',
                    value: '${orders['total'] ?? 0} ₪',
                    icon: Icons.payments_outlined,
                  ),
                  _MetricCard(
                    label: 'متوسط الطلب',
                    value: '${orders['average_order_value'] ?? 0} ₪',
                    icon: Icons.analytics_outlined,
                  ),
                  _MetricCard(
                    label: 'منتجات المتجر',
                    value: '${listings['count'] ?? 0}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ]),
                const SizedBox(height: 12),
                _section(
                  'تفصيل الطلبات',
                  Icons.donut_small_outlined,
                  [
                    _row('طلبات أُنشئت من الإدارة',
                        onlineStoreMap(orders['origins'])['admin']),
                    _row('طلبات أُنشئت من المتجر',
                        onlineStoreMap(orders['origins'])['store']),
                    _row('طلبات التجزئة',
                        onlineStoreMap(orders['price_contexts'])['retail']),
                    _row('طلبات الجملة',
                        onlineStoreMap(orders['price_contexts'])['wholesale']),
                  ],
                ),
                _section(
                  'المخزون والخصومات',
                  Icons.local_offer_outlined,
                  [
                    _row('منتجات منشورة نفدت كميتها', listings['out_of_stock']),
                    _row('مرات استخدام الكوبونات', coupons['uses']),
                    _row('إجمالي خصم الكوبونات',
                        '${coupons['discount_total'] ?? 0} ₪'),
                    _row('العروض الترويجية النشطة', promotions['active']),
                  ],
                ),
                if (reviews['available'] == true)
                  _section(
                    'مراجعات العملاء',
                    Icons.star_outline_rounded,
                    [
                      _row('بانتظار المراجعة', reviews['pending']),
                      _row('منشورة', reviews['published']),
                    ],
                  ),
                if (debt['available'] == true)
                  _section(
                    'نشاط الذمم المرتبط بالطلبات',
                    Icons.account_balance_wallet_outlined,
                    [
                      _row('ذمم مستحقة', '${debt['given'] ?? 0} ₪'),
                      _row('تسديدات', '${debt['taken'] ?? 0} ₪'),
                      _row('صافي التعرض', '${debt['net_exposure'] ?? 0} ₪'),
                    ],
                  ),
                _bestSelling(bestSelling),
              ],
            ),
          );
        }),
      );

  Future<void> _showFilters(BuildContext context) => showOnlineStoreBottomSheet(
        context,
        child: Obx(() => _filters(onApplied: () {
              Navigator.pop(context);
              controller.load();
            })),
      );

  Widget _filters({required VoidCallback onApplied}) => OnlineStoreFormSection(
        title: 'تصفية التقرير',
        description: 'تؤثر المرشحات التالية في أرقام الطلبات والخصومات.',
        icon: Icons.filter_alt_outlined,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          SizedBox(
            width: 180,
            child: OnlineStoreDateTimeField(
              controller: controller.fromController,
              label: 'من تاريخ',
              includeTime: false,
            ),
          ),
          SizedBox(
            width: 180,
            child: OnlineStoreDateTimeField(
              controller: controller.toController,
              label: 'إلى تاريخ',
              includeTime: false,
            ),
          ),
          _dropdown(
            controller.origin.value,
            const {'all': 'كل المصادر', 'admin': 'الإدارة', 'store': 'المتجر'},
            (value) => controller.origin.value = value,
          ),
          _dropdown(
            controller.accountType.value,
            const {
              'all': 'كل أنواع البيع',
              'customer': 'تجزئة',
              'seller': 'جملة'
            },
            (value) => controller.accountType.value = value,
          ),
          _dropdown(
            controller.status.value,
            const {
              'all': 'كل الحالات',
              'unconfirmed': 'غير مؤكد',
              'confirmed': 'مؤكد',
              'ready': 'جاهز',
              'with_delivery': 'مع شركة التوصيل',
              'delivered': 'تم التسليم',
              'archived': 'مؤرشف',
              'returned': 'مرتجع',
              'canceled': 'ملغي',
            },
            (value) => controller.status.value = value,
          ),
          OutlinedButton.icon(
            style: OnlineStoreAdminUi.actionButtonStyle,
            onPressed: onApplied,
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('تطبيق المرشحات'),
          ),
        ]),
      );

  Widget _dropdown(
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) =>
      DropdownButton<String>(
        value: value,
        items: options.entries
            .map((entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)))
            .toList(),
        onChanged: (next) => onChanged(next ?? options.keys.first),
      );

  Widget _section(String title, IconData icon, List<Widget> rows) => Card(
        color: OnlineStoreAdminUi.surface,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: OnlineStoreAdminUi.accent),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
            const Divider(),
            ...rows,
          ]),
        ),
      );

  Widget _row(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text('${value ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _bestSelling(List<Map<String, dynamic>> rows) => Card(
        color: OnlineStoreAdminUi.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.workspace_premium_outlined,
                  color: OnlineStoreAdminUi.accent),
              SizedBox(width: 8),
              Text('المنتجات الأكثر مبيعًا',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
            const Divider(),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child:
                    Center(child: Text('لا توجد مبيعات ضمن الفترة المحددة.')),
              )
            else
              ...rows.asMap().entries.map((entry) {
                final row = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: OnlineStoreAdminUi.surfaceMuted,
                    child: Text('${entry.key + 1}'),
                  ),
                  title: Text(
                      '${row['product_name'] ?? 'منتج #${row['product_id']}'}'),
                  subtitle: Text(
                    '${row['product_code']?.toString().isNotEmpty == true ? 'الكود: ${row['product_code']} • ' : ''}'
                    'الكمية: ${row['quantity'] ?? 0}',
                  ),
                  trailing: Text('${row['revenue'] ?? 0} ₪',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                );
              }),
          ]),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 165,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: OnlineStoreAdminUi.accent),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: OnlineStoreAdminUi.textSecondary)),
        ]),
      );
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(12),
        children: List.generate(
          6,
          (index) => Container(
            height: index == 0 ? 150 : 92,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: OnlineStoreAdminUi.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}
