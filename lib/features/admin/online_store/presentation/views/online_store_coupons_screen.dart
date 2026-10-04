import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_coupons_controller.dart';
import '../utils/online_store_permissions.dart';
import '../widgets/online_store_resource_screen.dart';
import '../widgets/online_store_discount_editor.dart';

class OnlineStoreCouponsScreen extends GetView<OnlineStoreCouponsController> {
  const OnlineStoreCouponsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      OnlineStoreResourceScreen<OnlineStoreCouponsController>(
        title: 'كوبونات المتجر',
        icon: Icons.confirmation_number_outlined,
        canManage: OnlineStorePermissions.canManagePromotions,
        subtitle: 'الأهلية والأهداف والحدود وسجل الاستخدام',
        inspectLabel: 'سجل الاستخدام',
        onInspect: (item) => _showRedemptions(item.id),
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
      );

  Future<void> _showRedemptions(int couponId) async {
    final rows = await controller.redemptions(couponId);
    await Get.dialog(AlertDialog(
      title: const Text('سجل استخدام الكوبون'),
      content: SizedBox(
        width: 430,
        child: rows.isEmpty
            ? const Text('لا توجد استخدامات')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: rows.length,
                itemBuilder: (_, index) {
                  final row = rows[index];
                  return ListTile(
                    title: Text('${row['status'] ?? '—'}'),
                    subtitle: Text(
                        'طلب ${row['sales_order_id'] ?? '—'} • مستخدم ${row['user_id'] ?? '—'}'),
                    trailing: Text('${row['discount_amount'] ?? ''}'),
                  );
                },
              ),
      ),
      actions: [TextButton(onPressed: Get.back, child: const Text('إغلاق'))],
    ));
  }
}
