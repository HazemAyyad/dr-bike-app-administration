import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_coupons_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_discount_editor.dart';
import '../utils/online_store_admin_ui.dart';
import '../../data/online_store_models.dart';

class OnlineStoreCouponsScreen extends GetView<OnlineStoreCouponsController> {
  const OnlineStoreCouponsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreCouponsController>(
        title: 'كوبونات المتجر',
        icon: Icons.confirmation_number_outlined,
        canManage: OnlineStorePermissions.canManagePromotions,
        subtitle: 'الأهلية والأهداف والحدود وسجل الاستخدام',
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
    final totalDiscount = item.values['discount_total'] ?? 0;
    return Card(
      color: OnlineStoreAdminUi.surface,
      child: ListTile(
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
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: OnlineStoreAdminUi.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.confirmation_number_outlined,
              color: OnlineStoreAdminUi.accent),
        ),
        title: Text(item.label,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '${type == 'percentage' ? '$value%' : '$value ₪'} • '
          '${active ? 'نشط' : 'متوقف'} • $activeUses استخدام • خصم $totalDiscount ₪',
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'سجل الاستخدام والإحصاءات',
            onPressed: () => _showRedemptions(item),
            icon: const Icon(Icons.history_rounded,
                color: OnlineStoreAdminUi.accent),
          ),
          trailing,
        ]),
      ),
    );
  }

  Future<void> _showRedemptions(OnlineStoreEntity coupon) async {
    final history = await controller.redemptions(coupon.id);
    final rows = history.rows;
    final summary = history.summary;
    await Get.dialog(AlertDialog(
      title: Text('سجل استخدام ${coupon.label}'),
      content: SizedBox(
        width: OnlineStoreAdminUi.dialogWidth(Get.context!),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(Get.context!).height * .72),
          child: ListView(children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _stat('تم تطبيقه', summary['applied_uses'] ?? 0),
              _stat('محجوز للطلبات', summary['reserved_uses'] ?? 0),
              _stat('المستخدمون', summary['unique_users'] ?? 0),
              _stat('إجمالي الخصم', '${summary['discount_total'] ?? 0} ₪'),
              _stat(
                'المتبقي',
                summary['remaining_uses'] ?? 'غير محدود',
              ),
            ]),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('لم يُستخدم هذا الكوبون بعد.')),
              )
            else
              ...rows.map((row) {
                final user = onlineStoreMap(row['user']);
                final customer = onlineStoreMap(row['customer']);
                final seller = onlineStoreMap(row['seller']);
                final order = onlineStoreMap(row['sales_order']);
                final party = customer.isNotEmpty ? customer : seller;
                final partyName =
                    '${party['name'] ?? party['nameAr'] ?? party['name_ar'] ?? user['name'] ?? 'مستخدم #${row['user_id'] ?? '—'}'}';
                final orderNumber =
                    order['serial_number'] ?? row['sales_order_id'] ?? '—';
                return Card(
                  color: OnlineStoreAdminUi.surfaceMuted,
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(partyName),
                    subtitle: Text(
                      'الطلب: $orderNumber • ${_redemptionStatus('${row['status'] ?? ''}')}\n'
                      '${row['applied_at'] ?? row['created_at'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: Text('${row['discount_amount'] ?? 0} ₪',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                );
              }),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: Get.back, child: const Text('إغلاق'))],
    ));
  }

  Widget _stat(String label, dynamic value) => Container(
        width: 145,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: OnlineStoreAdminUi.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: OnlineStoreAdminUi.textSecondary)),
          Text('$value',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      );

  String _redemptionStatus(String value) =>
      const {
        'reserved': 'محجوز للطلب',
        'applied': 'تم تطبيقه',
        'released': 'أُلغي الحجز',
      }[value] ??
      'غير معروف';
}
