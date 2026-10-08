import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_coupons_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_discount_editor.dart';
import '../utils/online_store_admin_ui.dart';
import '../../data/online_store_models.dart';
import '../widgets/online_store_form_widgets.dart';

class OnlineStoreCouponsScreen extends GetView<OnlineStoreCouponsController> {
  const OnlineStoreCouponsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreCouponsController>(
        title: 'كوبونات المتجر',
        icon: Icons.confirmation_number_outlined,
        canManage: OnlineStorePermissions.canManagePromotions,
        actions: const {
          OnlineStoreResourceAction.activate,
          OnlineStoreResourceAction.deactivate,
          OnlineStoreResourceAction.delete,
        },
        editor: (context, item) => showOnlineStoreDiscountEditor(
          context,
          controller: controller,
          kind: OnlineStoreDiscountKind.coupon,
          item: item,
        ),
        cardBuilder: _couponCard,
      );

  Widget _couponCard(
    BuildContext context,
    OnlineStoreEntity item,
    Widget trailing,
  ) {
    final active =
        item.values['is_active'] == true || item.values['is_active'] == 1;
    final type = '${item.values['discount_type'] ?? ''}';
    final value = item.values['discount_value'] ?? 0;
    final activeUses = item.values['active_redemptions_count'] ?? 0;
    final limit = int.tryParse('${item.values['total_usage_limit'] ?? ''}');
    final used = int.tryParse('$activeUses') ?? 0;
    final remaining = limit == null ? null : (limit - used).clamp(0, limit);
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -3),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(10, 2, 4, 2),
        onTap: OnlineStorePermissions.canManagePromotions
            ? () async {
                final payload = await showOnlineStoreDiscountEditor(
                  context,
                  controller: controller,
                  kind: OnlineStoreDiscountKind.coupon,
                  item: item,
                );
                if (payload != null) {
                  await controller.updateItem(item.id, payload);
                }
              }
            : null,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: OnlineStoreAdminUi.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.confirmation_number_outlined,
              color: OnlineStoreAdminUi.accent),
        ),
        title: Row(children: [
          Expanded(
              child: Text(item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          _badge(
              active ? 'نشط' : 'متوقف',
              active
                  ? OnlineStoreAdminUi.success
                  : OnlineStoreAdminUi.textSecondary),
        ]),
        subtitle: Text(
          '${type == 'percentage' ? '$value%' : '$value ₪'}  •  استُخدم $used  •  متبقي ${remaining ?? '∞'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'سجل الاستخدام والإحصاءات',
            onPressed: () => Get.to(() => OnlineStoreCouponHistoryScreen(
                  coupon: item,
                  controller: controller,
                )),
            icon: const Icon(Icons.history_rounded,
                color: OnlineStoreAdminUi.accent),
          ),
          trailing,
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}

class OnlineStoreCouponHistoryScreen extends StatelessWidget {
  const OnlineStoreCouponHistoryScreen({
    Key? key,
    required this.coupon,
    required this.controller,
  }) : super(key: key);

  final OnlineStoreEntity coupon;
  final OnlineStoreCouponsController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: OnlineStoreAdminUi.pageBackground,
        appBar: AppBar(title: Text('سجل ${coupon.label}')),
        body: FutureBuilder<OnlineStoreCouponHistory>(
          future: controller.redemptions(coupon.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('تعذر تحميل السجل: ${snapshot.error}'));
            }
            final history = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _HistoryStat(
                        'تم تطبيقه', history.summary['applied_uses'] ?? 0),
                    _HistoryStat(
                        'محجوز', history.summary['reserved_uses'] ?? 0),
                    _HistoryStat(
                        'المستخدمون', history.summary['unique_users'] ?? 0),
                    _HistoryStat('المتبقي',
                        history.summary['remaining_uses'] ?? 'غير محدود'),
                  ],
                ),
                const SizedBox(height: 12),
                if (history.rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('لم يُستخدم هذا الكوبون بعد.')),
                  )
                else
                  ...history.rows.map((row) => _HistoryRow(row)),
              ],
            );
          },
        ),
      );
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat(this.label, this.value);
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OnlineStoreAdminUi.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: OnlineStoreAdminUi.textSecondary)),
          Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow(this.row);
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final user = onlineStoreMap(row['user']);
    final customer = onlineStoreMap(row['customer']);
    final seller = onlineStoreMap(row['seller']);
    final order = onlineStoreMap(row['sales_order']);
    final party = customer.isNotEmpty ? customer : seller;
    final name =
        '${party['name'] ?? party['nameAr'] ?? party['name_ar'] ?? user['name'] ?? 'مستخدم #${row['user_id'] ?? '—'}'}';
    final status = const {
          'reserved': 'محجوز للطلب',
          'applied': 'تم تطبيقه',
          'released': 'أُلغي الحجز'
        }['${row['status'] ?? ''}'] ??
        'غير معروف';
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            'الطلب: ${order['serial_number'] ?? row['sales_order_id'] ?? '—'} • $status\n${onlineStoreFriendlyDate(row['applied_at'] ?? row['created_at'])}'),
        isThreeLine: true,
        trailing: Text('${row['discount_amount'] ?? 0} ₪',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
